# transactions/models.py
import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class TransactionType(models.TextChoices):
    INCOME = 'income', 'Income'
    EXPENSE = 'expense', 'Expense'
    SAVINGS = 'savings', 'Savings'


class TransactionStatus(models.TextChoices):
    PENDING = 'pending', 'Pending'
    COMPLETED = 'completed', 'Completed'
    FAILED = 'failed', 'Failed'
    CANCELLED = 'cancelled', 'Cancelled'
    REFUNDED = 'refunded', 'Refunded'


class PaymentMethod(models.TextChoices):
    CASH = 'cash', 'Cash'
    CARD = 'card', 'Card'
    BANK = 'bank', 'Bank'
    MOBILE = 'mobile', 'Mobile'
    ONLINE = 'online', 'Online'
    CHEQUE = 'cheque', 'Cheque'


class Transaction(models.Model):
    """
    Main transaction model for all financial transactions.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    category = models.ForeignKey(
        'accounts.Category',
        on_delete=models.SET_NULL,
        related_name='transactions',
        null=True,
        blank=True
    )
    goal = models.ForeignKey(
        'goals.Goal',
        on_delete=models.SET_NULL,
        related_name='transactions',
        null=True,
        blank=True
    )
    
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    type = models.CharField(max_length=20, choices=TransactionType.choices)
    status = models.CharField(
        max_length=20,
        choices=TransactionStatus.choices,
        default=TransactionStatus.COMPLETED
    )
    payment_method = models.CharField(
        max_length=20,
        choices=PaymentMethod.choices,
        null=True,
        blank=True
    )
    
    description = models.TextField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    reference = models.CharField(max_length=100, null=True, blank=True)
    recipient = models.CharField(max_length=255, null=True, blank=True)
    sms_source = models.TextField(null=True, blank=True)
    
    is_expense = models.BooleanField(default=True)
    is_pending = models.BooleanField(default=False)
    is_recurring = models.BooleanField(default=False)
    is_synced = models.BooleanField(default=False)
    
    transaction_date = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'transactions'
        ordering = ['-transaction_date']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['category']),
            models.Index(fields=['goal']),
            models.Index(fields=['transaction_date']),
            models.Index(fields=['type']),
            models.Index(fields=['status']),
            models.Index(fields=['is_synced']),
            models.Index(fields=['profile', '-transaction_date']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(amount__gt=0),
                name='amount_positive'
            )
        ]
    
    def __str__(self):
        return f"{self.type.capitalize()} - {self.amount} - {self.transaction_date.date()}"
    
    def save(self, *args, **kwargs):
        """Override save to set is_expense based on type."""
        if self.type == TransactionType.EXPENSE:
            self.is_expense = True
        else:
            self.is_expense = False
        super().save(*args, **kwargs)
    
    @property
    def currency(self):
        """Get currency from profile."""
        return self.profile.base_currency if self.profile else 'KES'


class PendingTransaction(models.Model):
    """
    Pending transactions detected from SMS that await user review.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='pending_transactions'
    )
    category = models.ForeignKey(
        'accounts.Category',
        on_delete=models.SET_NULL,
        related_name='pending_transactions',
        null=True,
        blank=True
    )
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.SET_NULL,
        related_name='pending_source',
        null=True,
        blank=True
    )
    
    raw_text = models.TextField(null=True, blank=True)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    description = models.TextField(null=True, blank=True)
    
    transaction_date = models.DateTimeField(default=timezone.now)
    type = models.CharField(
        max_length=20,
        choices=TransactionType.choices,
        default=TransactionType.EXPENSE
    )
    status = models.CharField(
        max_length=20,
        choices=TransactionStatus.choices,
        default=TransactionStatus.PENDING
    )
    
    confidence = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=Decimal('0.5')
    )
    metadata = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'pending_transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['status']),
            models.Index(fields=['-created_at']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(confidence__gte=0) & models.Q(confidence__lte=1),
                name='confidence_range'
            )
        ]
    
    def __str__(self):
        return f"Pending - {self.amount} - {self.created_at.date()}"
    
    def approve(self, category=None):
        """
        Approve this pending transaction and create a real transaction.
        Returns the created Transaction instance.
        """
        if self.status != TransactionStatus.PENDING:
            raise ValueError("Only pending transactions can be approved")
        
        # Create the actual transaction
        transaction = Transaction.objects.create(
            profile=self.profile,
            category=category or self.category,
            amount=self.amount,
            type=self.type,
            status=TransactionStatus.COMPLETED,
            description=self.description,
            sms_source=self.raw_text,
            transaction_date=self.transaction_date,
            is_synced=False
        )
        
        # Update this pending transaction
        self.transaction = transaction
        self.status = TransactionStatus.COMPLETED
        self.save()
        
        return transaction
    
    def reject(self):
        """Reject this pending transaction."""
        self.status = TransactionStatus.CANCELLED
        self.save()


class TransactionCategory(models.TextChoices):
    """
    Enum for transaction categories (matches Flutter app).
    """
    FOOD = 'food', 'Food'
    TRANSPORT = 'transport', 'Transport'
    UTILITIES = 'utilities', 'Utilities'
    ENTERTAINMENT = 'entertainment', 'Entertainment'
    HEALTHCARE = 'healthcare', 'Healthcare'
    GROCERIES = 'groceries', 'Groceries'
    DINING_OUT = 'diningOut', 'Dining Out'
    SHOPPING = 'shopping', 'Shopping'
    EDUCATION = 'education', 'Education'
    SALARY = 'salary', 'Salary'
    BUSINESS = 'business', 'Business'
    INVESTMENT = 'investment', 'Investment'
    GIFT = 'gift', 'Gift'
    OTHER_INCOME = 'otherIncome', 'Other Income'
    OTHER_EXPENSE = 'otherExpense', 'Other Expense'
    EMERGENCY_FUND = 'emergencyFund', 'Emergency Fund'
    RENT = 'rent', 'Rent'
    RETIREMENT = 'retirement', 'Retirement'
    OTHER = 'other', 'Other'
    SAVINGS = 'savings', 'Savings'
    OTHER_SAVINGS = 'otherSavings', 'Other Savings'
# transactions/models.py - FIXED VERSION
import uuid
import json
from django.db import models
from django.utils import timezone
from decimal import Decimal
from django.core.validators import MinValueValidator, MaxValueValidator


class TransactionType(models.TextChoices):
    INCOME = 'income', 'Income'
    EXPENSE = 'expense', 'Expense'
    SAVINGS = 'savings', 'Savings'
    TRANSFER = 'transfer', 'Transfer'


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
    MPESA = 'mpesa', 'Mpesa'
    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'
    OTHER = 'other', 'Other'


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
    
    # ✅ Store category as string
    category = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        help_text="Category name as string"
    )
    
    # ✅ Store goal_id as string (REMOVED duplicate 'goal' field)
    goal_id = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        help_text="Goal name or ID as string"
    )
    
    is_synced = models.BooleanField(default=False)
    
    amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    type = models.CharField(max_length=20, choices=TransactionType.choices)
    status = models.CharField(
        max_length=20,
        choices=TransactionStatus.choices,
        default=TransactionStatus.COMPLETED
    )
    currency = models.CharField(max_length=3, default='KES')
    payment_method = models.CharField(
        max_length=50,
        choices=PaymentMethod.choices,
        null=True,
        blank=True
    )
    
    description = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    reference = models.CharField(max_length=255, blank=True, null=True)
    recipient = models.CharField(max_length=255, blank=True, null=True)
    sms_source = models.TextField(blank=True, null=True)
    
    # ✅ CRITICAL: Database column is 'date' not 'transaction_date'
    date = models.DateTimeField(default=timezone.now, db_column='date')
    
    # Database fields that exist
    is_recurring = models.BooleanField(default=False)
    recurring_pattern = models.CharField(max_length=50, blank=True, null=True)
    parent_transaction = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='child_transactions'
    )
    merchant_name = models.CharField(max_length=255, blank=True, null=True)
    merchant_category = models.CharField(max_length=100, blank=True, null=True)
    tags = models.CharField(
        default='', 
        blank=True,
        max_length=500,
        help_text="Comma-separated tags for categorizing transactions"
    )
    location = models.CharField(max_length=255, blank=True, null=True)
    latitude = models.DecimalField(
        max_digits=10, 
        decimal_places=8, 
        null=True, 
        blank=True
    )
    longitude = models.DecimalField(
        max_digits=11, 
        decimal_places=8, 
        null=True, 
        blank=True
    )
    is_flagged = models.BooleanField(default=False)
    anomaly_score = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        null=True, 
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(1)]
    )
    budget_period = models.CharField(max_length=50, blank=True, null=True)
    budget_id = models.UUIDField(null=True, blank=True)
    budget_category = models.CharField(max_length=255, blank=True, null=True)
    remote_id = models.CharField(max_length=255, blank=True, null=True)
    is_pending = models.BooleanField(default=False)
    is_expense = models.BooleanField(null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'transactions'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['category']),
            models.Index(fields=['goal_id']),
            models.Index(fields=['date']),
            models.Index(fields=['type']),
            models.Index(fields=['status']),
            models.Index(fields=['profile', '-date']),
            models.Index(fields=['anomaly_score'], name='idx_transactions_anomaly'),
            models.Index(fields=['budget_id'], name='idx_transactions_budget_id'),
            models.Index(fields=['location'], name='idx_transactions_location'),
            models.Index(fields=['merchant_name'], name='idx_transactions_merchant'),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(amount__gt=0),
                name='amount_positive'
            ),
            models.CheckConstraint(
                condition=(models.Q(anomaly_score__gte=0) & models.Q(anomaly_score__lte=1)) | 
                           models.Q(anomaly_score__isnull=True),
                name='transactions_anomaly_score_check'
            ),
        ]
    
    def __str__(self):
        return f"{self.type.capitalize()} - KES {self.amount} - {self.date.date()}"

    def save(self, *args, **kwargs):
        """Override save to set derived fields."""
        if self.is_expense is None:
            self.is_expense = (self.type == TransactionType.EXPENSE)
        
        self.is_pending = (self.status == TransactionStatus.PENDING)
        
        # If tags is a list, convert to comma-separated string
        if isinstance(self.tags, list):
            self.tags = ','.join(str(tag).strip() for tag in self.tags if tag)
        
        super().save(*args, **kwargs)

    @property
    def transaction_date(self):
        """Property alias for 'date' field for backward compatibility."""
        return self.date
    
    @transaction_date.setter
    def transaction_date(self, value):
        """Setter for transaction_date alias."""
        self.date = value
    
    @property
    def display_amount(self):
        """Get formatted amount with currency."""
        return f"{self.currency} {self.amount:,.2f}"
    
    @property
    def tags_list(self):
        """Get tags as Python list from comma-separated string."""
        if not self.tags:
            return []
        
        # Split by comma and clean up
        return [tag.strip() for tag in str(self.tags).split(',') if tag.strip()]

    @tags_list.setter
    def tags_list(self, value):
        """Set tags from a list."""
        if isinstance(value, list):
            self.tags = ','.join(str(tag).strip() for tag in value if tag)
        else:
            self.tags = value or ''
        
    @property
    def has_location(self):
        """Check if transaction has location data."""
        return self.latitude is not None and self.longitude is not None
    
    @property
    def is_anomalous(self):
        """Check if transaction is flagged as anomalous."""
        return self.anomaly_score is not None and self.anomaly_score > 0.7
        
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
    # ✅ Store category as string (not ForeignKey)
    category = models.CharField(
        max_length=255,
        null=True,
        blank=True  # Changed to allow blank
    )
    transaction = models.ForeignKey(
        Transaction,
        on_delete=models.SET_NULL,
        related_name='pending_source',
        null=True,
        blank=True
    )
    
    raw_text = models.TextField(blank=True, null=True)
    amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    description = models.TextField(blank=True, null=True)
    
    date = models.DateTimeField(default=timezone.now, db_column='date')
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
        default=Decimal('0.5'),
        validators=[MinValueValidator(0), MaxValueValidator(1)]
    )
    metadata = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
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
# budgets/models.py
import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class BudgetPeriod(models.TextChoices):
    DAILY = 'daily', 'Daily'
    WEEKLY = 'weekly', 'Weekly'
    MONTHLY = 'monthly', 'Monthly'
    QUARTERLY = 'quarterly', 'Quarterly'
    YEARLY = 'yearly', 'Yearly'


class Budget(models.Model):
    """Budget plans and tracking."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='budgets'
    )
    category = models.CharField(max_length=255, null=True, blank=True)
    
    name = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    
    budget_amount = models.DecimalField(max_digits=15, decimal_places=2)
    spent_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    
    period = models.CharField(
        max_length=20,
        choices=BudgetPeriod.choices,
        default=BudgetPeriod.MONTHLY
    )
    
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'budgets'
        ordering = ['-start_date']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['category']),
            models.Index(fields=['is_active']),
            models.Index(fields=['start_date', 'end_date']),
            models.Index(fields=['is_synced']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(budget_amount__gt=0),
                name='budget_amount_positive'
            ),
            models.CheckConstraint(
                condition=models.Q(spent_amount__gte=0),
                name='spent_amount_non_negative'
            ),
            models.CheckConstraint(
                condition=models.Q(end_date__gt=models.F('start_date')),
                name='end_after_start'
            ),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.profile}"
    
    @property
    def remaining_amount(self):
        """Calculate remaining budget amount."""
        return self.budget_amount - self.spent_amount
    
    @property
    def spent_percentage(self):
        """Calculate percentage of budget spent."""
        if self.budget_amount <= 0:
            return 0.0
        return min((float(self.spent_amount) / float(self.budget_amount)) * 100, 100.0)
    
    @property
    def is_over_budget(self):
        """Check if budget is exceeded."""
        return self.spent_amount > self.budget_amount
    
    @property
    def days_remaining(self):
        """Calculate days remaining in budget period."""
        now = timezone.now()
        if now > self.end_date:
            return 0
        return (self.end_date - now).days
    
    @property
    def is_current(self):
        """Check if budget is currently active (within date range)."""
        now = timezone.now()
        return self.start_date <= now <= self.end_date
    
    def update_spent_amount(self):
        """Recalculate spent amount from transactions."""
        from transactions.models import Transaction, TransactionStatus, TransactionType
        
        # Get all expense transactions for this budget period
        transactions = Transaction.objects.filter(
            profile=self.profile,
            type=TransactionType.EXPENSE,
            status=TransactionStatus.COMPLETED,
            transaction_date__gte=self.start_date,
            transaction_date__lte=self.end_date
        )
        
        # Filter by category if budget is category-specific
        if self.category:
            transactions = transactions.filter(category=self.category)
        
        # Calculate total
        total = sum(t.amount for t in transactions)
        self.spent_amount = Decimal(str(total))
        self.is_synced = False
        self.save()


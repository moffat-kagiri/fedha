# goals/models.py
# Create your models here.
import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class GoalType(models.TextChoices):
    SAVINGS = 'savings', 'Savings'
    DEBT_REDUCTION = 'debtReduction', 'Debt Reduction'
    INSURANCE = 'insurance', 'Insurance'
    EMERGENCY_FUND = 'emergencyFund', 'Emergency Fund'
    INVESTMENT = 'investment', 'Investment'
    OTHER = 'other', 'Other'


class GoalStatus(models.TextChoices):
    ACTIVE = 'active', 'Active'
    COMPLETED = 'completed', 'Completed'
    PAUSED = 'paused', 'Paused'
    CANCELLED = 'cancelled', 'Cancelled'


class GoalPriority(models.TextChoices):
    LOW = 'low', 'Low'
    MEDIUM = 'medium', 'Medium'
    HIGH = 'high', 'High'
    CRITICAL = 'critical', 'Critical'


class Goal(models.Model):
    """Financial goals and savings targets."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='goals'
    )
    
    name = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    
    target_amount = models.DecimalField(max_digits=15, decimal_places=2)
    current_amount = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    
    target_date = models.DateTimeField()
    completed_date = models.DateTimeField(null=True, blank=True)
    
    goal_type = models.CharField(max_length=20, choices=GoalType.choices)
    status = models.CharField(
        max_length=20,
        choices=GoalStatus.choices,
        default=GoalStatus.ACTIVE
    )
    priority = models.CharField(
        max_length=20,
        choices=GoalPriority.choices,
        default=GoalPriority.MEDIUM
    )
    
    is_synced = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'goals'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['status']),
            models.Index(fields=['goal_type']),
            models.Index(fields=['is_synced']),
            models.Index(fields=['target_date']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(target_amount__gt=0) & models.Q(current_amount__gte=0),
                name='goal_amounts_positive'
            ),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.profile}"
    
    @property
    def progress_percentage(self):
        """Calculate progress percentage."""
        if self.target_amount <= 0:
            return 0.0
        return min((float(self.current_amount) / float(self.target_amount)) * 100, 100.0)
    
    @property
    def remaining_amount(self):
        """Calculate remaining amount to reach target."""
        return max(self.target_amount - self.current_amount, 0)
    
    @property
    def is_completed(self):
        """Check if goal is completed."""
        return self.status == GoalStatus.COMPLETED
    
    @property
    def is_overdue(self):
        """Check if goal is overdue."""
        return not self.is_completed and self.target_date < timezone.now()
    
    @property
    def days_remaining(self):
        """Calculate days remaining until target date."""
        if self.target_date < timezone.now():
            return 0
        return (self.target_date - timezone.now()).days
    
    def add_contribution(self, amount):
        """Add a contribution to the goal."""
        if amount <= 0:
            raise ValueError("Contribution amount must be positive")
        
        self.current_amount += Decimal(str(amount))
        
        # Check if goal is now completed
        if self.current_amount >= self.target_amount:
            self.status = GoalStatus.COMPLETED
            self.completed_date = timezone.now()
        
        self.is_synced = False
        self.save()

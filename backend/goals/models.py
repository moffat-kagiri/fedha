# goals/models.py
import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal
from django.core.validators import MinValueValidator


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


class Goal(models.Model):
    """Financial goals and savings targets."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='goals'
    )
    
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    
    goal_type = models.CharField(
        max_length=50,  # Changed from 20 to match database enum
        choices=GoalType.choices,
        default=GoalType.SAVINGS
    )
    status = models.CharField(
        max_length=50,  # Changed from 20 to match database enum
        choices=GoalStatus.choices,
        default=GoalStatus.ACTIVE,
        db_column='goal_status'  # ✅ CRITICAL: Database column is 'goal_status' not 'status'
    )
    
    target_amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    current_amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2, 
        default=0,
        validators=[MinValueValidator(0)]
    )
    
    # ✅ Database shows target_date is nullable
    target_date = models.DateTimeField(null=True, blank=True)
    completed_date = models.DateTimeField(null=True, blank=True)
    
    # ✅ Database fields (already exist)
    currency = models.CharField(max_length=3, default='KES')
    last_contribution_date = models.DateTimeField(null=True, blank=True)
    contribution_count = models.IntegerField(default=0)
    average_contribution = models.DecimalField(
        max_digits=15, 
        decimal_places=2, 
        null=True, 
        blank=True
    )
    linked_category_id = models.UUIDField(null=True, blank=True)
    projected_completion_date = models.DateTimeField(null=True, blank=True)
    days_ahead_behind = models.IntegerField(null=True, blank=True)
    goal_group = models.CharField(max_length=100, blank=True, null=True)
    
    # ✅ ADDED: This field exists in your database but was missing
    remote_id = models.CharField(max_length=255, blank=True, null=True)
    
    # Note: 'is_synced' field doesn't exist in your database schema
    # If you want it, you'll need to add it to the database first
    # is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'goals'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['status']),
            models.Index(fields=['goal_type']),
            models.Index(fields=['target_date']),
            models.Index(fields=['linked_category_id']),
            # Removed 'is_synced' index since field doesn't exist in DB
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(target_amount__gt=0),
                name='goal_amounts_positive'
            ),
            # Database already has: CHECK (current_amount <= target_amount OR goal_status = 'completed'::goal_status)
            models.CheckConstraint(
                condition=models.Q(current_amount__lte=models.F('target_amount')) | 
                           models.Q(status=GoalStatus.COMPLETED),
                name='goal_current_amount_check'
            ),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.profile}"
    
    def save(self, *args, **kwargs):
        """Override save to handle auto-updates."""
        # Update completed_date if status changes to COMPLETED
        if self.status == GoalStatus.COMPLETED and not self.completed_date:
            self.completed_date = timezone.now()
        
        # Update last_contribution_date if current_amount changes
        if self.pk:
            try:
                old = Goal.objects.get(pk=self.pk)
                if self.current_amount != old.current_amount:
                    self.last_contribution_date = timezone.now()
                    if self.current_amount > old.current_amount:
                        self.contribution_count += 1
                        contribution_amount = self.current_amount - old.current_amount
                        if self.contribution_count > 0:
                            self.average_contribution = self.current_amount / self.contribution_count
            except Goal.DoesNotExist:
                pass  # New goal
        
        # Auto-complete if current_amount reaches or exceeds target
        if self.current_amount >= self.target_amount and self.status != GoalStatus.COMPLETED:
            self.status = GoalStatus.COMPLETED
            if not self.completed_date:
                self.completed_date = timezone.now()
        
        super().save(*args, **kwargs)
    
    @property
    def progress_percentage(self):
        """Calculate progress percentage."""
        if self.target_amount <= 0:
            return 0.0
        try:
            percentage = (float(self.current_amount) / float(self.target_amount)) * 100
            return min(percentage, 100.0)
        except (ValueError, ZeroDivisionError):
            return 0.0
    
    @property
    def remaining_amount(self):
        """Calculate remaining amount to reach target."""
        try:
            remaining = self.target_amount - self.current_amount
            return max(remaining, Decimal('0'))
        except (ValueError, TypeError):
            return Decimal('0')
    
    @property
    def is_completed(self):
        """Check if goal is completed."""
        return self.status == GoalStatus.COMPLETED
    
    @property
    def is_overdue(self):
        """Check if goal is overdue."""
        return not self.is_completed and self.target_date and self.target_date < timezone.now()
    
    @property
    def days_remaining(self):
        """Calculate days remaining until target date."""
        if not self.target_date or self.target_date < timezone.now():
            return 0
        try:
            return (self.target_date - timezone.now()).days
        except (ValueError, TypeError):
            return 0
    
    @property
    def daily_savings_needed(self):
        """Calculate daily savings needed to reach target."""
        days = self.days_remaining
        if days <= 0:
            return self.remaining_amount
        try:
            return self.remaining_amount / Decimal(str(days))
        except (ZeroDivisionError, ValueError):
            return Decimal('0')
    
    @property
    def monthly_savings_needed(self):
        """Calculate monthly savings needed to reach target."""
        months = max(self.days_remaining / 30, 1)  # At least 1 month
        try:
            return self.remaining_amount / Decimal(str(months))
        except (ZeroDivisionError, ValueError):
            return Decimal('0')
    
    def add_contribution(self, amount):
        """Add a contribution to the goal."""
        try:
            amount_decimal = Decimal(str(amount))
            if amount_decimal <= 0:
                raise ValueError("Contribution amount must be positive")
            
            self.current_amount += amount_decimal
            
            # Check if goal is now completed
            if self.current_amount >= self.target_amount:
                self.status = GoalStatus.COMPLETED
                self.completed_date = timezone.now()
            
            # Note: Can't set is_synced since field doesn't exist
            # self.is_synced = False
            self.save()
        except (ValueError, TypeError) as e:
            raise ValueError(f"Invalid contribution amount: {e}")
    
    def mark_completed(self):
        """Mark the goal as completed manually."""
        self.status = GoalStatus.COMPLETED
        self.completed_date = timezone.now()
        if self.current_amount < self.target_amount:
            self.current_amount = self.target_amount  # Set to target if manually completed
        # Note: Can't set is_synced since field doesn't exist
        # self.is_synced = False
        self.save()
    
    def update_progress(self, new_current_amount):
        """Update the current amount manually."""
        try:
            new_amount = Decimal(str(new_current_amount))
            if new_amount < 0:
                raise ValueError("Current amount cannot be negative")
            
            self.current_amount = new_amount
            
            # Check if goal is now completed
            if self.current_amount >= self.target_amount:
                self.status = GoalStatus.COMPLETED
                if not self.completed_date:
                    self.completed_date = timezone.now()
            
            # Note: Can't set is_synced since field doesn't exist
            # self.is_synced = False
            self.save()
        except (ValueError, TypeError) as e:
            raise ValueError(f"Invalid amount: {e}")
            
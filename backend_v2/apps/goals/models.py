# apps/goals/models.py
from django.db import models
from apps.accounts.models import User
import uuid as uuid_lib  # FIXED
from datetime import datetime

class Goal(models.Model):
    """
    Matches Flutter: lib/models/goal.dart
    Financial goals/savings targets
    """
    
    # Matches GoalType enum
    GOAL_TYPE_CHOICES = [
        ('savings', 'Savings'),
        ('debtReduction', 'Debt Reduction'),
        ('insurance', 'Insurance'),
        ('emergencyFund', 'Emergency Fund'),
        ('investment', 'Investment'),
        ('other', 'Other'),
    ]
    
    # Matches GoalStatus enum
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('paused', 'Paused'),
        ('cancelled', 'Cancelled'),
    ]
    
    # Matches GoalPriority enum
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid_lib.uuid4)  # FIXED
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='goals')
    profile_id = models.UUIDField()  # Matches Flutter profileId
    
    # Core fields - exact Flutter mapping
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    target_amount = models.DecimalField(max_digits=12, decimal_places=2)  # Matches targetAmount
    current_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)  # Matches currentAmount
    target_date = models.DateField()  # Matches targetDate
    completed_date = models.DateTimeField(null=True, blank=True)  # Matches completedDate
    
    # Type, status, priority
    goal_type = models.CharField(max_length=20, choices=GOAL_TYPE_CHOICES)  # Matches goalType
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    
    # Sync flag
    is_synced = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'goals'
        ordering = ['-created_at']
    
    @property
    def progress_percentage(self):
        """Matches Flutter: progressPercentage"""
        if self.target_amount == 0:
            return 0.0
        return min((self.current_amount / self.target_amount * 100), 100.0)
    
    @property
    def is_completed(self):
        """Matches Flutter: isCompleted"""
        return self.status == 'completed'
    
    @property
    def is_overdue(self):
        """Matches Flutter: isOverdue"""
        return not self.is_completed and self.target_date < datetime.now().date()
    
    @property
    def days_remaining(self):
        """Matches Flutter: daysRemaining"""
        now = datetime.now().date()
        return (self.target_date - now).days
    
    @property
    def amount_needed(self):
        """Matches Flutter: amountNeeded"""
        return max(self.target_amount - self.current_amount, 0)
    
    @property
    def daily_savings_needed(self):
        """Matches Flutter: dailySavingsNeeded"""
        days = self.days_remaining
        if days <= 0:
            return self.amount_needed
        return self.amount_needed / days
    
    @property
    def monthly_savings_needed(self):
        """Matches Flutter: monthlySavingsNeeded"""
        months = max((self.days_remaining / 30), 1)
        return self.amount_needed / months
    
    def add_contribution(self, amount):
        """Matches Flutter: addContribution()"""
        self.current_amount = min(self.current_amount + amount, self.target_amount)
        
        if self.current_amount >= self.target_amount:
            self.status = 'completed'
            self.completed_date = datetime.now()
        
        self.save()
        return self
    
    def save(self, *args, **kwargs):
        # Auto-set profile_id from user if not set
        if not self.profile_id:
            self.profile_id = self.user.id
        
        # Update completed_date if status changed to completed
        if self.status == 'completed' and not self.completed_date:
            self.completed_date = datetime.now()
        
        # Set updated_at
        self.updated_at = datetime.now()
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.name} - {self.progress_percentage:.1f}% ({self.status})"
# apps/budgets/models.py
from django.db import models
from apps.accounts.models import User
import uuid

class Budget(models.Model):
    """
    Matches Flutter: lib/models/budget.dart
    Budget tracking per category/period
    """
    
    PERIOD_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('yearly', 'Yearly'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budgets')
    
    # Matches Flutter fields exactly
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    budget_amount = models.DecimalField(max_digits=12, decimal_places=2)  # Matches budgetAmount
    spent_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)  # Matches spentAmount
    category_id = models.UUIDField()  # Matches categoryId
    profile_id = models.UUIDField()  # Matches profileId
    period = models.CharField(max_length=20, choices=PERIOD_CHOICES, default='monthly')
    
    # Date range
    start_date = models.DateField()
    end_date = models.DateField()
    
    # Status
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'budgets'
        ordering = ['-start_date']
    
    @property
    def remaining_amount(self):
        """Matches Flutter: remainingAmount"""
        return self.budget_amount - self.spent_amount
    
    @property
    def spent_percentage(self):
        """Matches Flutter: spentPercentage"""
        if self.budget_amount <= 0:
            return 0.0
        return min((self.spent_amount / self.budget_amount * 100), 100.0)
    
    @property
    def is_over_budget(self):
        """Matches Flutter: isOverBudget"""
        return self.spent_amount > self.budget_amount
    
    @property
    def total_budget(self):
        """Matches Flutter: totalBudget"""
        return self.budget_amount
    
    @property
    def total_spent(self):
        """Matches Flutter: totalSpent"""
        return self.spent_amount
    
    @property
    def days_remaining(self):
        """Matches Flutter: daysRemaining"""
        from datetime import datetime
        now = datetime.now().date()
        if now > self.end_date:
            return 0
        return (self.end_date - now).days
    
    def save(self, *args, **kwargs):
        # Auto-set profile_id from user if not set
        if not self.profile_id:
            self.profile_id = self.user.id
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.name} - {self.period} ({self.spent_amount}/{self.budget_amount})"
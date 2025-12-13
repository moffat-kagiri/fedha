# apps/transactions/models.py
from django.db import models
from apps.accounts.models import User
import uuid

class Transaction(models.Model):
    """
    Matches Flutter: lib/models/transaction.dart
    Core transaction model for income/expense tracking
    """
    
    # Transaction types - matches TransactionType enum
    TYPE_CHOICES = [
        ('income', 'Income'),
        ('expense', 'Expense'),
        ('savings', 'Savings'),
    ]
    
    # Payment methods - matches PaymentMethod enum
    PAYMENT_METHOD_CHOICES = [
        ('cash', 'Cash'),
        ('card', 'Card'),
        ('bank', 'Bank'),
        ('mobile', 'Mobile'),
        ('online', 'Online'),
        ('cheque', 'Cheque'),
    ]
    
    # Primary fields - exact Flutter mapping
    uuid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    profile_id = models.UUIDField()  # Matches Flutter profileId
    
    # Core transaction data
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    category_id = models.CharField(max_length=100, db_index=True)  # Matches Flutter categoryId
    category = models.CharField(max_length=50, blank=True, null=True)  # Enum name
    date = models.DateTimeField(db_index=True)
    
    # Description fields
    notes = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    
    # Status flags - matches Flutter fields
    is_synced = models.BooleanField(default=False)
    is_pending = models.BooleanField(default=False)
    is_expense = models.BooleanField(default=True)  # Derived from type
    is_recurring = models.BooleanField(default=False)
    
    # Optional metadata
    goal_id = models.UUIDField(null=True, blank=True)
    sms_source = models.CharField(max_length=200, blank=True, null=True)
    reference = models.CharField(max_length=200, blank=True, null=True)
    recipient = models.CharField(max_length=200, blank=True, null=True)
    payment_method = models.CharField(
        max_length=20, 
        choices=PAYMENT_METHOD_CHOICES,
        blank=True,
        null=True
    )
    
    # Timestamps - matches Flutter
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'transactions'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['user', '-date']),
            models.Index(fields=['user', 'category_id']),
            models.Index(fields=['user', 'type']),
            models.Index(fields=['profile_id', '-date']),
        ]
    
    def save(self, *args, **kwargs):
        # Auto-set is_expense based on type
        self.is_expense = self.type == 'expense'
        # Auto-set profile_id from user if not set
        if not self.profile_id:
            self.profile_id = self.user.id
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.type.title()}: {self.amount} - {self.category_id} ({self.date.date()})"


class TransactionCandidate(models.Model):
    """
    Matches Flutter: lib/models/transaction_candidate.dart
    For SMS-extracted transactions pending approval
    """
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transaction_candidates')
    
    # Raw SMS data
    raw_text = models.TextField(blank=True, null=True)
    
    # Extracted transaction data
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.TextField(blank=True, null=True)
    category_id = models.CharField(max_length=100, blank=True, null=True)
    date = models.DateTimeField()
    type = models.CharField(max_length=10, choices=Transaction.TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Confidence scoring
    confidence = models.DecimalField(max_digits=3, decimal_places=2, default=0.5)  # 0.0 to 1.0
    
    # Link to created transaction if approved
    transaction_id = models.UUIDField(null=True, blank=True)
    
    # Metadata
    metadata = models.JSONField(default=dict, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'transaction_candidates'
        ordering = ['-created_at']
    
    @property
    def is_pending(self):
        return self.status == 'pending'
    
    @property
    def is_approved(self):
        return self.status == 'completed'
    
    @property
    def is_rejected(self):
        return self.status == 'cancelled'
    
    @property
    def is_high_confidence(self):
        return self.confidence >= 0.8
    
    @property
    def is_low_confidence(self):
        return self.confidence < 0.5


class Category(models.Model):
    """
    Matches Flutter: lib/models/category.dart
    Custom categories per user
    """
    
    TYPE_CHOICES = [
        ('income', 'Income'),
        ('expense', 'Expense'),
        ('both', 'Both'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='categories')
    
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    color = models.CharField(max_length=20, default='#2196F3')  # Hex color
    icon = models.CharField(max_length=50, default='category')  # Icon name
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='expense')
    
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categories'
        unique_together = ['user', 'name']
        ordering = ['name']
        verbose_name_plural = 'categories'
    
    def __str__(self):
        return f"{self.name} ({self.type})"
# backend/api/models.py
import uuid
from django.db import models
from django.core.validators import MinLengthValidator, MinValueValidator
from django.utils import timezone
import hashlib
from django.conf import settings

class Profile(models.Model):
    class ProfileType(models.TextChoices):
        BUSINESS = 'BIZ', 'Business'
        PERSONAL = 'PERS', 'Personal'
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        verbose_name="Profile ID"
    )
    name = models.CharField(
        max_length=100,
        blank=True,
        help_text="Optional profile display name"
    )
    profile_type = models.CharField(
        max_length=4,
        choices=ProfileType.choices,
        default=ProfileType.PERSONAL
    )
    pin_hash = models.CharField(
        max_length=128,
        help_text="SHA-256 hash of 4-digit PIN"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile_type']),
            models.Index(fields=['created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_profile_type_display()} Profile ({self.id})"

    @staticmethod
    def hash_pin(raw_pin: str) -> str:
        """Securely hash a 4-digit PIN"""
        if len(raw_pin) != 4 or not raw_pin.isdigit():
            raise ValueError("PIN must be 4 digits")
        salted = f"{raw_pin}{settings.SECRET_KEY}"
        return hashlib.sha256(salted.encode()).hexdigest()

    def verify_pin(self, raw_pin: str) -> bool:
        return self.pin_hash == self.hash_pin(raw_pin)

class Transaction(models.Model):
    class TransactionType(models.TextChoices):
        INCOME = 'IN', 'Income'
        EXPENSE = 'EX', 'Expense'

    class Category(models.TextChoices):
        # Business Categories
        SALES = 'SALE', 'Sales'
        MARKETING = 'MRKT', 'Marketing'
        # Personal Categories
        GROCERIES = 'GROC', 'Groceries'
        RENT = 'RENT', 'Rent'
        # Common
        OTHER = 'OTHR', 'Other'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    type = models.CharField(
        max_length=2,
        choices=TransactionType.choices
    )
    category = models.CharField(
        max_length=4,
        choices=Category.choices,
        default=Category.OTHER
    )
    date = models.DateField(default=timezone.now)
    notes = models.TextField(blank=True, null=True)
    is_synced = models.BooleanField(
        default=True,
        help_text="True if synced with mobile app"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['date'], name='transaction_date_idx'),
            models.Index(fields=['type'], name='transaction_type_idx'),
        ]
        ordering = ['-date']
        verbose_name = "Financial Transaction"
        verbose_name_plural = "Financial Transactions"

    def __str__(self):
        return f"{self.get_type_display()} - {self.amount} ({self.date})"

    def clean(self):
        if self.amount <= 0:
            raise ValidationError("Amount must be greater than zero.")
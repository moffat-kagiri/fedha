# Create your models here.
from django.db import models
from .profile import Profile  # Assuming Profile model exists

class Profile(models.Model):
    id = models.CharField(primary_key=True, max_length=20)  # e.g., "biz_8a7d2f"
    is_business = models.BooleanField()
    pin_hash = models.CharField(max_length=128)  # Hashed PIN (SHA256)
    created_at = models.DateTimeField(auto_now_add=True)
class Transaction(models.Model):
    class TransactionType(models.TextChoices):
        INCOME = "IN", "Income"
        EXPENSE = "EX", "Expense"
    
    class Category(models.TextChoices):
        # Business Categories
        MARKETING = "MARKETING", "Marketing"
        UTILITIES = "UTILITIES", "Utilities"
        SALARIES = "SALARIES", "Salaries"
        # Personal Categories
        GROCERIES = "GROCERIES", "Groceries"
        RENT = "RENT", "Rent"
        OTHER = "OTHER", "Other"

    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(
        max_length=2,
        choices=TransactionType.choices,
        default=TransactionType.EXPENSE
    )
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.OTHER
    )
    date = models.DateField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)
    is_synced = models.BooleanField(default=True)  # Managed by backend

    def __str__(self):
        return f"{self.type} - {self.category}: ${self.amount}"
# Create your models here.
from django.db import models

class Profile(models.Model):
    id = models.CharField(primary_key=True, max_length=20)  # e.g., "biz_8a7d2f"
    is_business = models.BooleanField()
    pin_hash = models.CharField(max_length=128)  # Hashed PIN (SHA256)
    created_at = models.DateTimeField(auto_now_add=True)

class Transaction(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    type = models.CharField(max_length=10)  # "income" or "expense"
    category = models.CharField(max_length=50)
    date = models.DateField()
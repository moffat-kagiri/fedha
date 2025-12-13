# apps/invoicing/models.py
from django.db import models
from apps.accounts.models import User
import uuid as uuid_lib  # FIXED
from datetime import datetime

class Client(models.Model):
    """
    Matches Flutter: lib/models/client.dart
    Client/customer management for invoicing
    """
    
    id = models.UUIDField(primary_key=True, default=uuid_lib.uuid4)  # FIXED
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='clients')
    
    # Core fields - exact Flutter mapping
    name = models.CharField(max_length=200)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=50, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'clients'
        ordering = ['name']
    
    def __str__(self):
        return f"{self.name} ({self.email or 'No email'})"


class Invoice(models.Model):
    """
    Matches Flutter: lib/models/invoice.dart
    Invoice management for freelancers/businesses
    """
    
    # Matches InvoiceStatus enum
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('sent', 'Sent'),
        ('paid', 'Paid'),
        ('overdue', 'Overdue'),
        ('cancelled', 'Cancelled'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid_lib.uuid4)  # FIXED
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='invoices')
    client = models.ForeignKey(Client, on_delete=models.CASCADE, related_name='invoices')
    
    # Core fields - exact Flutter mapping
    invoice_number = models.CharField(max_length=50, unique=True)  # Matches invoiceNumber
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='KES')
    
    # Dates
    issue_date = models.DateField()  # Matches issueDate
    due_date = models.DateField()    # Matches dueDate
    
    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # Optional fields
    description = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    
    # Flags
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'invoices'
        ordering = ['-issue_date']
    
    @property
    def is_overdue(self):
        """Matches Flutter: isOverdue"""
        return (self.status not in ['paid', 'cancelled'] and 
                datetime.now().date() > self.due_date)
    
    def save(self, *args, **kwargs):
        # Auto-update status to overdue if applicable
        if self.is_overdue and self.status not in ['paid', 'cancelled']:
            self.status = 'overdue'
        super().save(*args, **kwargs)
        
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.client.name} ({self.status})"


class Loan(models.Model):
    """
    Matches Flutter: lib/models/loan.dart
    Loan tracking
    """
    
    id = models.AutoField(primary_key=True)  # Matches Flutter int? id
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='loans')
    profile_id = models.UUIDField()  # Matches Flutter profileId
    
    # Core fields - exact Flutter mapping
    name = models.CharField(max_length=200)
    principal_minor = models.DecimalField(max_digits=15, decimal_places=2)  # Matches principalMinor
    currency = models.CharField(max_length=3, default='KES')
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)  # Matches interestRate
    
    # Dates
    start_date = models.DateField()  # Matches startDate
    end_date = models.DateField()    # Matches endDate
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'loans'
        ordering = ['-start_date']
    
    def save(self, *args, **kwargs):
        if not self.profile_id:
            self.profile_id = self.user.id
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.name} - {self.principal_minor} {self.currency}"
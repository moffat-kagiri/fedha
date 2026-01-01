# invoicing/models.py
import uuid
from django.db import models
from django.utils import timezone
from decimal import Decimal


class InvoiceStatus(models.TextChoices):
    DRAFT = 'draft', 'Draft'
    SENT = 'sent', 'Sent'
    PAID = 'paid', 'Paid'
    OVERDUE = 'overdue', 'Overdue'
    CANCELLED = 'cancelled', 'Cancelled'


class InterestModel(models.TextChoices):
    SIMPLE = 'simple', 'Simple'
    COMPOUND = 'compound', 'Compound'
    REDUCING_BALANCE = 'reducingBalance', 'Reducing Balance'


class Client(models.Model):
    """Business clients for invoicing."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='clients'
    )
    
    name = models.CharField(max_length=255)
    email = models.EmailField(null=True, blank=True)
    phone = models.CharField(max_length=20, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'clients'
        ordering = ['name']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return self.name


class Invoice(models.Model):
    """Invoices for business users."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    client = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    
    invoice_number = models.CharField(max_length=50, unique=True)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    currency = models.CharField(max_length=3, default='KES')
    
    issue_date = models.DateTimeField()
    due_date = models.DateTimeField()
    
    status = models.CharField(
        max_length=20,
        choices=InvoiceStatus.choices,
        default=InvoiceStatus.DRAFT
    )
    
    description = models.TextField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'invoices'
        ordering = ['-issue_date']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['client']),
            models.Index(fields=['status']),
            models.Index(fields=['issue_date', 'due_date']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(amount__gt=0),
                name='invoice_amount_positive'
            )
        ]
    
    def __str__(self):
        return f"{self.invoice_number} - {self.client.name}"
    
    @property
    def is_overdue(self):
        """Check if invoice is overdue."""
        return (self.status not in [InvoiceStatus.PAID, InvoiceStatus.CANCELLED] 
                and timezone.now() > self.due_date)
    
    @property
    def days_until_due(self):
        """Calculate days until due date."""
        if timezone.now() > self.due_date:
            return 0
        return (self.due_date - timezone.now()).days


class Loan(models.Model):
    """Loan tracking and management."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        'accounts.Profile',
        on_delete=models.CASCADE,
        related_name='loans'
    )
    
    name = models.CharField(max_length=255)
    principal_amount = models.DecimalField(max_digits=15, decimal_places=2)
    currency = models.CharField(max_length=3, default='KES')
    interest_rate = models.DecimalField(max_digits=5, decimal_places=2)
    interest_model = models.CharField(
        max_length=20,
        choices=InterestModel.choices,
        default=InterestModel.SIMPLE
    )
    
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    is_synced = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'loans'
        ordering = ['-start_date']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['start_date', 'end_date']),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(principal_amount__gt=0),
                name='loan_principal_positive'
            ),
            models.CheckConstraint(
                condition=models.Q(interest_rate__gte=0) & models.Q(interest_rate__lte=100),
                name='loan_interest_rate_valid'
            ),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.principal_amount}"
    
    @property
    def is_active(self):
        """Check if loan is currently active."""
        now = timezone.now()
        return self.start_date <= now <= self.end_date
    
    def calculate_total_interest(self):
        """Calculate total interest based on interest model."""
        principal = float(self.principal_amount)
        rate = float(self.interest_rate) / 100
        days = (self.end_date - self.start_date).days
        years = days / 365
        
        if self.interest_model == InterestModel.SIMPLE:
            return Decimal(str(principal * rate * years))
        elif self.interest_model == InterestModel.COMPOUND:
            # Compound annually
            return Decimal(str(principal * ((1 + rate) ** years - 1)))
        else:
            # Reducing balance - simplified calculation
            return Decimal(str(principal * rate * years * 0.5))
    
    def calculate_total_amount(self):
        """Calculate total amount to be repaid."""
        return self.principal_amount + self.calculate_total_interest()


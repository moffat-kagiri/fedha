# backend/api/models.py
"""
Fedha Budget Tracker - Comprehensive Database Schema

This module defines the complete database schema for the Fedha Budget Tracker,
a privacy-focused financial management system for SMEs and personal finance.

Key Features Covered:
- Profile management with UUID-based privacy
- Transaction tracking with hierarchical categorization
- Invoice generation and management
- Tax preparation and compliance
- Loan tracking with complex interest calculations
- Goal setting and progress monitoring
- Cash flow analysis for SMEs
- Multi-currency support
- Asset management and depreciation

Author: Fedha Development Team
Last Updated: May 26, 2025
"""

import uuid
from decimal import Decimal
from django.db import models
from django.core.validators import (
    MinLengthValidator, 
    MinValueValidator, 
    MaxValueValidator,
    RegexValidator
)
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
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
        ordering = ['-date']        verbose_name = "Financial Transaction"
        verbose_name_plural = "Financial Transactions"

    def __str__(self):
        return f"{self.get_type_display()} - {self.amount} ({self.date})"
    
    def clean(self):
        if self.amount <= 0:
            raise ValidationError("Amount must be greater than zero.")


# =============================================================================
# HIERARCHICAL CATEGORY SYSTEM
# =============================================================================

class Category(models.Model):
    """
    Hierarchical category system for transactions, supporting both business 
    and personal categorization with parent-child relationships.
    
    Features:
    - Self-referential hierarchy (parent categories can have subcategories)
    - Profile-specific custom categories
    - Tax-deductible marking for business expenses
    - Industry-specific default categories
    """
    
    class CategoryType(models.TextChoices):
        INCOME = 'INC', 'Income'
        EXPENSE = 'EXP', 'Expense'
        ASSET = 'AST', 'Asset'
        LIABILITY = 'LIA', 'Liability'
        EQUITY = 'EQT', 'Equity'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile, 
        on_delete=models.CASCADE, 
        related_name='categories',
        null=True, 
        blank=True,
        help_text="Leave blank for system default categories"
    )
    name = models.CharField(max_length=100)
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='subcategories'
    )
    type = models.CharField(max_length=3, choices=CategoryType.choices)
    is_tax_deductible = models.BooleanField(
        default=False,
        help_text="Mark if this category represents tax-deductible expenses"
    )
    is_system_default = models.BooleanField(
        default=False,
        help_text="System-provided categories that apply to all profiles"
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'type']),
            models.Index(fields=['parent']),
        ]
        unique_together = ['profile', 'name', 'parent']
        verbose_name_plural = "Categories"

    def __str__(self):
        path = []
        current = self
        while current:
            path.append(current.name)
            current = current.parent
        return " > ".join(reversed(path))

    @property
    def full_path(self):
        """Return the full hierarchical path of this category"""
        return str(self)


# =============================================================================
# CLIENT MANAGEMENT SYSTEM
# =============================================================================

class Client(models.Model):
    """
    Client management for business profiles to handle invoicing and payments.
    
    Features:
    - Contact information management
    - Credit limit and payment terms
    - Payment history tracking
    - Client-specific pricing and discounts
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile, 
        on_delete=models.CASCADE, 
        related_name='clients'
    )
    name = models.CharField(max_length=200)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    
    # Financial settings    credit_limit = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0'),
        help_text="Maximum credit allowed for this client"
    )
    payment_terms_days = models.PositiveIntegerField(
        default=30,
        help_text="Default payment terms in days"
    )    discount_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    
    # Status tracking
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_transaction_date = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'is_active']),
            models.Index(fields=['name']),
        ]
        unique_together = ['profile', 'email']

    def __str__(self):
        return f"{self.name} ({self.profile.name})"

    @property
    def outstanding_balance(self):
        """Calculate total outstanding invoice balance for this client"""
        from django.db.models import Sum
        outstanding = self.invoices.filter(
            status__in=['SENT', 'OVERDUE']
        ).aggregate(
            total=Sum('total_amount')
        )['total'] or Decimal('0')
        return outstanding

    @property
    def is_over_credit_limit(self):
        """Check if client has exceeded their credit limit"""
        return self.outstanding_balance > self.credit_limit


# =============================================================================
# ENHANCED TRANSACTION SYSTEM
# =============================================================================

class EnhancedTransaction(models.Model):
    """
    Enhanced transaction model with support for:
    - Multiple currencies
    - Attachments (receipts, documents)
    - Split transactions
    - Recurring transaction templates
    """
    
    class TransactionType(models.TextChoices):
        INCOME = 'IN', 'Income'
        EXPENSE = 'EX', 'Expense'
        TRANSFER = 'TR', 'Transfer'
        ADJUSTMENT = 'ADJ', 'Adjustment'
    
    class PaymentMethod(models.TextChoices):
        CASH = 'CASH', 'Cash'
        CARD = 'CARD', 'Credit/Debit Card'
        BANK_TRANSFER = 'BANK', 'Bank Transfer'
        MOBILE_MONEY = 'MOBILE', 'Mobile Money'
        CHEQUE = 'CHEQUE', 'Cheque'
        OTHER = 'OTHER', 'Other'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='enhanced_transactions'
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        related_name='transactions'
    )
    
    # Basic transaction details
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        help_text="ISO 4217 currency code"
    )    exchange_rate = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        default=Decimal('1.0'),
        help_text="Exchange rate to base currency"
    )
    type = models.CharField(max_length=3, choices=TransactionType.choices)
    payment_method = models.CharField(
        max_length=6,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH
    )
    
    # Transaction metadata
    description = models.CharField(max_length=255)
    notes = models.TextField(blank=True)
    reference_number = models.CharField(max_length=100, blank=True)
    date = models.DateField(default=timezone.now)
    
    # Relationships
    client = models.ForeignKey(
        Client,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions'
    )
    invoice = models.ForeignKey(
        'Invoice',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments'
    )
    
    # Split transaction support
    parent_transaction = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='split_transactions'
    )
    
    # Recurring transaction template
    recurring_template = models.ForeignKey(
        'RecurringTransactionTemplate',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='generated_transactions'
    )
    
    # Tracking fields
    is_reconciled = models.BooleanField(default=False)
    is_tax_relevant = models.BooleanField(default=False)
    is_synced = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'date']),
            models.Index(fields=['type', 'date']),
            models.Index(fields=['category', 'date']),
            models.Index(fields=['client', 'date']),
            models.Index(fields=['is_tax_relevant']),
        ]
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.get_type_display()}: {self.currency} {self.amount} - {self.description}"

    @property
    def amount_in_base_currency(self):
        """Convert amount to base currency using exchange rate"""
        return self.amount * self.exchange_rate

    def clean(self):
        if self.amount <= 0:
            raise ValidationError("Transaction amount must be positive")
        if self.parent_transaction and self.parent_transaction.parent_transaction:
            raise ValidationError("Split transactions cannot be nested")


# =============================================================================
# INVOICE MANAGEMENT SYSTEM
# =============================================================================

class Invoice(models.Model):
    """
    Professional invoice management system for business profiles.
    
    Features:
    - Customizable invoice templates
    - Automatic numbering sequences
    - Payment tracking and aging
    - Multi-currency support
    - PDF generation capability
    """
    
    class InvoiceStatus(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        SENT = 'SENT', 'Sent'
        VIEWED = 'VIEWED', 'Viewed by Client'
        PARTIALLY_PAID = 'PARTIAL', 'Partially Paid'
        PAID = 'PAID', 'Paid'
        OVERDUE = 'OVERDUE', 'Overdue'
        CANCELLED = 'CANCELLED', 'Cancelled'
        REFUNDED = 'REFUNDED', 'Refunded'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    client = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        related_name='invoices'
    )
    
    # Invoice identification
    invoice_number = models.CharField(max_length=50, unique=True)
    reference = models.CharField(max_length=100, blank=True)
    
    # Dates
    issue_date = models.DateField(default=timezone.now)
    due_date = models.DateField()
    sent_date = models.DateTimeField(null=True, blank=True)
    payment_date = models.DateTimeField(null=True, blank=True)
      # Financial details
    subtotal = models.DecimalField(max_digits=15, decimal_places=2)
    tax_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    tax_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)]
    )
    discount_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    total_amount = models.DecimalField(max_digits=15, decimal_places=2)
    paid_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    
    # Invoice content
    notes = models.TextField(blank=True)
    terms_and_conditions = models.TextField(blank=True)
    footer_text = models.TextField(blank=True)
    
    # Status and tracking
    status = models.CharField(
        max_length=10,
        choices=InvoiceStatus.choices,
        default=InvoiceStatus.DRAFT
    )
    currency = models.CharField(max_length=3, default='USD')
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['client', 'status']),
            models.Index(fields=['due_date']),
            models.Index(fields=['invoice_number']),
        ]
        ordering = ['-issue_date', '-created_at']

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.client.name}"

    @property
    def outstanding_amount(self):
        """Calculate remaining unpaid amount"""
        return self.total_amount - self.paid_amount

    @property
    def is_overdue(self):
        """Check if invoice is past due date"""
        return (
            self.due_date < timezone.now().date() and 
            self.status not in [Invoice.InvoiceStatus.PAID, Invoice.InvoiceStatus.CANCELLED]
        )

    @property
    def days_overdue(self):
        """Calculate days past due date"""
        if self.is_overdue:
            return (timezone.now().date() - self.due_date).days
        return 0

    def calculate_totals(self):
        """Recalculate invoice totals based on line items"""
        self.subtotal = sum(item.total for item in self.line_items.all())
        self.discount_amount = (self.subtotal * self.discount_percentage) / 100
        discounted_subtotal = self.subtotal - self.discount_amount
        self.tax_amount = (discounted_subtotal * self.tax_rate) / 100
        self.total_amount = discounted_subtotal + self.tax_amount

    def mark_as_sent(self):
        """Mark invoice as sent and record timestamp"""
        self.status = self.InvoiceStatus.SENT
        self.sent_date = timezone.now()
        self.save()


class InvoiceLineItem(models.Model):
    """
    Individual line items for invoices supporting products/services.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    invoice = models.ForeignKey(
        Invoice,
        on_delete=models.CASCADE,
        related_name='line_items'
    )
    
    description = models.CharField(max_length=255)
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(0.001)]
    )
    unit_price = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    total = models.DecimalField(max_digits=15, decimal_places=2)
    
    # Optional product/service categorization
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['id']

    def __str__(self):
        return f"{self.description} (x{self.quantity})"

    def save(self, *args, **kwargs):
        self.total = self.quantity * self.unit_price
        super().save(*args, **kwargs)


# =============================================================================
# LOAN MANAGEMENT SYSTEM
# =============================================================================

class Loan(models.Model):
    """
    Comprehensive loan tracking with support for complex interest calculations.
    
    Features:
    - Multiple interest calculation methods
    - Amortization schedule generation
    - Early payment tracking
    - Interest rate solving algorithms
    """
    
    class LoanType(models.TextChoices):
        PERSONAL = 'PERSONAL', 'Personal Loan'
        BUSINESS = 'BUSINESS', 'Business Loan'
        MORTGAGE = 'MORTGAGE', 'Mortgage'
        AUTO = 'AUTO', 'Auto Loan'
        CREDIT_CARD = 'CREDIT', 'Credit Card'
        LINE_OF_CREDIT = 'LOC', 'Line of Credit'
        OTHER = 'OTHER', 'Other'
    
    class InterestType(models.TextChoices):
        SIMPLE = 'SIMPLE', 'Simple Interest'
        COMPOUND = 'COMPOUND', 'Compound Interest'
        REDUCING_BALANCE = 'REDUCING', 'Reducing Balance'
        FLAT_RATE = 'FLAT', 'Flat Rate'
    
    class PaymentFrequency(models.TextChoices):
        DAILY = 'DAILY', 'Daily'
        WEEKLY = 'WEEKLY', 'Weekly'
        BIWEEKLY = 'BIWEEKLY', 'Bi-weekly'
        MONTHLY = 'MONTHLY', 'Monthly'
        QUARTERLY = 'QUARTERLY', 'Quarterly'
        SEMI_ANNUALLY = 'SEMI_ANUAL', 'Semi-annually'
        ANNUALLY = 'ANNUALLY', 'Annually'
    
    class LoanStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        PAID_OFF = 'PAID_OFF', 'Paid Off'
        DEFAULTED = 'DEFAULTED', 'Defaulted'
        REFINANCED = 'REFINANCED', 'Refinanced'
        SUSPENDED = 'SUSPENDED', 'Suspended'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='loans'
    )
    
    # Basic loan information
    name = models.CharField(max_length=200)
    lender = models.CharField(max_length=200)
    loan_type = models.CharField(max_length=10, choices=LoanType.choices)
    account_number = models.CharField(max_length=50, blank=True)
    
    # Financial terms
    principal_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    annual_interest_rate = models.DecimalField(
        max_digits=8,
        decimal_places=5,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Annual interest rate as percentage (e.g., 15.75000)"
    )
    interest_type = models.CharField(max_length=10, choices=InterestType.choices)
    payment_frequency = models.CharField(max_length=12, choices=PaymentFrequency.choices)
    number_of_payments = models.PositiveIntegerField(
        help_text="Total number of scheduled payments"
    )
    payment_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Scheduled payment amount per period"
    )
    
    # Dates
    origination_date = models.DateField()
    first_payment_date = models.DateField()
    maturity_date = models.DateField()
      # Current status
    current_balance = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    total_paid = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    payments_made = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=12,
        choices=LoanStatus.choices,
        default=LoanStatus.ACTIVE
    )
      # Additional terms
    late_fee_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0')
    )
    grace_period_days = models.PositiveIntegerField(default=0)
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['maturity_date']),
            models.Index(fields=['loan_type']),
        ]
        ordering = ['maturity_date']

    def __str__(self):
        return f"{self.name} - {self.lender}"

    @property
    def remaining_payments(self):
        """Calculate remaining number of payments"""
        return max(0, self.number_of_payments - self.payments_made)

    @property
    def monthly_interest_rate(self):
        """Convert annual rate to monthly rate"""
        frequency_map = {
            'MONTHLY': 12,
            'QUARTERLY': 4,
            'SEMI_ANNUAL': 2,
            'ANNUALLY': 1,
            'WEEKLY': 52,
            'BIWEEKLY': 26,
            'DAILY': 365
        }
        periods_per_year = frequency_map.get(self.payment_frequency, 12)
        return self.annual_interest_rate / 100 / periods_per_year

    @property
    def total_interest_paid(self):
        """Calculate total interest paid to date"""
        return self.total_paid - (self.principal_amount - self.current_balance)

    @property
    def loan_to_value_ratio(self):
        """Calculate current loan-to-value ratio if applicable"""
        if hasattr(self, 'collateral_value') and self.collateral_value > 0:
            return (self.current_balance / self.collateral_value) * 100
        return None

    def calculate_payment_amount(self):
        """Calculate payment amount using loan terms"""
        if self.interest_type == self.InterestType.REDUCING_BALANCE:
            # Standard amortization formula
            monthly_rate = self.monthly_interest_rate
            if monthly_rate == 0:
                return self.principal_amount / self.number_of_payments
            
            numerator = monthly_rate * (1 + monthly_rate) ** self.number_of_payments
            denominator = (1 + monthly_rate) ** self.number_of_payments - 1
            return self.principal_amount * (numerator / denominator)
        
        elif self.interest_type == self.InterestType.SIMPLE:
            total_interest = self.principal_amount * (self.annual_interest_rate / 100)
            total_amount = self.principal_amount + total_interest
            return total_amount / self.number_of_payments
        
        # Add other calculation methods as needed
        return self.payment_amount


class LoanPayment(models.Model):
    """
    Individual loan payments with principal/interest breakdown.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    loan = models.ForeignKey(
        Loan,
        on_delete=models.CASCADE,
        related_name='payments'
    )
    
    payment_number = models.PositiveIntegerField()
    scheduled_date = models.DateField()
    actual_date = models.DateField(null=True, blank=True)
    
    scheduled_amount = models.DecimalField(max_digits=15, decimal_places=2)
    actual_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True
    )
    
    principal_amount = models.DecimalField(max_digits=15, decimal_places=2)
    interest_amount = models.DecimalField(max_digits=15, decimal_places=2)
    late_fee = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0'))
    
    balance_after_payment = models.DecimalField(max_digits=15, decimal_places=2)
    
    is_paid = models.BooleanField(default=False)
    is_late = models.BooleanField(default=False)
    
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['loan', 'payment_number']),
            models.Index(fields=['scheduled_date']),
            models.Index(fields=['is_paid']),
        ]
        unique_together = ['loan', 'payment_number']
        ordering = ['payment_number']

    def __str__(self):
        return f"Payment {self.payment_number} for {self.loan.name}"


# =============================================================================
# GOAL SETTING AND TRACKING SYSTEM
# =============================================================================

class Goal(models.Model):
    """
    Financial goal setting and progress tracking system.
    
    Features:
    - SMART goal framework
    - Progress visualization
    - Multiple goal types
    - Achievement notifications
    """
    
    class GoalType(models.TextChoices):
        SAVINGS = 'SAVINGS', 'Savings Goal'
        DEBT_REDUCTION = 'DEBT', 'Debt Reduction'
        INVESTMENT = 'INVESTMENT', 'Investment Target'
        EXPENSE_REDUCTION = 'EXPENSE', 'Expense Reduction'
        INCOME_INCREASE = 'INCOME', 'Income Increase'
        EMERGENCY_FUND = 'EMERGENCY', 'Emergency Fund'
        RETIREMENT = 'RETIREMENT', 'Retirement Planning'
        OTHER = 'OTHER', 'Other'
    
    class GoalStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        COMPLETED = 'COMPLETED', 'Completed'
        PAUSED = 'PAUSED', 'Paused'
        CANCELLED = 'CANCELLED', 'Cancelled'
        OVERDUE = 'OVERDUE', 'Overdue'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='goals'
    )
    
    # Goal definition
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    goal_type = models.CharField(max_length=12, choices=GoalType.choices)
      # Financial targets
    target_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0.01)]
    )
    current_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    currency = models.CharField(max_length=3, default='USD')
    
    # Timeline
    start_date = models.DateField(default=timezone.now)
    target_date = models.DateField()
    completion_date = models.DateField(null=True, blank=True)
    
    # Progress tracking
    status = models.CharField(
        max_length=10,
        choices=GoalStatus.choices,
        default=GoalStatus.ACTIVE
    )
    is_automated = models.BooleanField(
        default=False,
        help_text="Automatically track progress based on transactions"
    )
    
    # Linked accounts/categories for automatic tracking
    linked_categories = models.ManyToManyField(
        Category,
        blank=True,
        help_text="Categories to track for automatic progress updates"
    )
    
    # Motivation and reminders
    milestone_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Amount for milestone celebrations"
    )
    reminder_frequency_days = models.PositiveIntegerField(
        default=7,
        help_text="Days between progress reminders"
    )
    last_reminder_sent = models.DateTimeField(null=True, blank=True)
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['target_date']),
            models.Index(fields=['goal_type']),
        ]
        ordering = ['target_date', '-created_at']

    def __str__(self):
        return f"{self.name} - {self.get_goal_type_display()}"

    @property
    def progress_percentage(self):
        """Calculate completion percentage"""
        if self.target_amount <= 0:
            return 0
        progress = (self.current_amount / self.target_amount) * 100
        return min(progress, 100)

    @property
    def remaining_amount(self):
        """Calculate remaining amount to reach goal"""
        return max(0, self.target_amount - self.current_amount)

    @property
    def days_remaining(self):
        """Calculate days until target date"""
        return (self.target_date - timezone.now().date()).days

    @property
    def required_daily_amount(self):
        """Calculate daily amount needed to reach goal"""
        if self.days_remaining <= 0:
            return self.remaining_amount
        return self.remaining_amount / self.days_remaining

    @property
    def is_on_track(self):
        """Determine if goal is on track based on timeline"""
        total_days = (self.target_date - self.start_date).days
        elapsed_days = (timezone.now().date() - self.start_date).days
        
        if total_days <= 0:
            return True
        
        expected_progress = (elapsed_days / total_days) * 100
        actual_progress = self.progress_percentage
        
        return actual_progress >= (expected_progress * 0.9)  # 10% tolerance

    def update_progress(self):
        """Update progress based on linked transactions"""
        if not self.is_automated or not self.linked_categories.exists():
            return
        
        # Calculate progress from linked category transactions
        from django.db.models import Sum
        total = EnhancedTransaction.objects.filter(
            profile=self.profile,
            category__in=self.linked_categories.all(),
            date__gte=self.start_date,
            date__lte=timezone.now().date()
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        
        self.current_amount = total
        
        # Check if goal is completed
        if self.current_amount >= self.target_amount:
            self.status = self.GoalStatus.COMPLETED
            self.completion_date = timezone.now().date()
        
        self.save()


# =============================================================================
# TAX PREPARATION AND COMPLIANCE SYSTEM
# =============================================================================

class TaxJurisdiction(models.Model):
    """
    Tax jurisdictions and their specific rules.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    country_code = models.CharField(max_length=2)
    tax_year_start = models.CharField(
        max_length=5,
        help_text="MM-DD format for tax year start (e.g., 01-01)"
    )
      # Standard rates
    standard_tax_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0')
    )
    vat_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0')
    )
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['name', 'country_code']

    def __str__(self):
        return f"{self.name} ({self.country_code})"


class TaxCategory(models.Model):
    """
    Tax-specific categorization for transactions and deductions.
    """
    
    class TaxTreatment(models.TextChoices):
        DEDUCTIBLE = 'DEDUCTIBLE', 'Tax Deductible'
        TAXABLE_INCOME = 'TAXABLE', 'Taxable Income'
        TAX_FREE = 'TAX_FREE', 'Tax Free'
        CAPITAL_GAIN = 'CAPITAL', 'Capital Gain'
        DEPRECIATION = 'DEPRECIATION', 'Depreciation'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    jurisdiction = models.ForeignKey(
        TaxJurisdiction,
        on_delete=models.CASCADE,
        related_name='tax_categories'
    )
    name = models.CharField(max_length=100)
    treatment = models.CharField(max_length=12, choices=TaxTreatment.choices)
    description = models.TextField(blank=True)
    
    # Limitation rules
    deduction_limit_annual = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Annual deduction limit for this category"
    )
    deduction_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Percentage of expense that's deductible"
    )
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['jurisdiction', 'name']
        verbose_name_plural = "Tax Categories"

    def __str__(self):
        return f"{self.name} ({self.get_treatment_display()})"


class TaxRecord(models.Model):
    """
    Tax preparation records linking transactions to tax implications.
    """
    
    class RecordType(models.TextChoices):
        INCOME = 'INCOME', 'Income Record'
        DEDUCTION = 'DEDUCTION', 'Deduction Record'
        CREDIT = 'CREDIT', 'Tax Credit'
        PAYMENT = 'PAYMENT', 'Tax Payment'
        REFUND = 'REFUND', 'Tax Refund'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='tax_records'
    )
    jurisdiction = models.ForeignKey(
        TaxJurisdiction,
        on_delete=models.CASCADE,
        related_name='tax_records'
    )
    tax_category = models.ForeignKey(
        TaxCategory,
        on_delete=models.CASCADE,
        related_name='tax_records'
    )
    
    # Record details
    record_type = models.CharField(max_length=10, choices=RecordType.choices)
    tax_year = models.PositiveIntegerField()
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    deductible_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True
    )
    
    # Source transaction
    transaction = models.ForeignKey(
        EnhancedTransaction,
        on_delete=models.CASCADE,
        related_name='tax_records',
        null=True,
        blank=True
    )
    
    # Documentation
    description = models.CharField(max_length=255)
    notes = models.TextField(blank=True)
    documentation_required = models.BooleanField(default=False)
    documentation_complete = models.BooleanField(default=False)
    
    # Verification
    is_verified = models.BooleanField(default=False)
    verified_by = models.CharField(max_length=100, blank=True)
    verification_date = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'tax_year']),
            models.Index(fields=['jurisdiction', 'tax_year']),
            models.Index(fields=['record_type', 'tax_year']),
        ]
        ordering = ['-tax_year', '-created_at']

    def __str__(self):
        return f"{self.get_record_type_display()} - {self.tax_year}"

    def calculate_deductible_amount(self):
        """Calculate actual deductible amount based on tax category rules"""
        if self.tax_category.deduction_percentage:
            percentage_amount = (self.amount * self.tax_category.deduction_percentage) / 100
            if self.tax_category.deduction_limit_annual:
                return min(percentage_amount, self.tax_category.deduction_limit_annual)
            return percentage_amount
        return self.amount if self.tax_category.treatment == TaxCategory.TaxTreatment.DEDUCTIBLE else 0


# =============================================================================
# ASSET MANAGEMENT AND DEPRECIATION
# =============================================================================

class Asset(models.Model):
    """
    Business asset tracking with depreciation calculations.
    """
    
    class AssetType(models.TextChoices):
        EQUIPMENT = 'EQUIPMENT', 'Equipment'
        VEHICLE = 'VEHICLE', 'Vehicle'
        FURNITURE = 'FURNITURE', 'Furniture'
        BUILDING = 'BUILDING', 'Building'
        LAND = 'LAND', 'Land'
        SOFTWARE = 'SOFTWARE', 'Software'
        INTELLECTUAL = 'IP', 'Intellectual Property'
        OTHER = 'OTHER', 'Other'
    
    class DepreciationMethod(models.TextChoices):
        STRAIGHT_LINE = 'STRAIGHT', 'Straight Line'
        DECLINING_BALANCE = 'DECLINING', 'Declining Balance'
        ACCELERATED = 'ACCELERATED', 'Accelerated'
        NONE = 'NONE', 'No Depreciation'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='assets'
    )
    
    # Asset identification
    name = models.CharField(max_length=200)
    asset_type = models.CharField(max_length=12, choices=AssetType.choices)
    serial_number = models.CharField(max_length=100, blank=True)
    model_number = models.CharField(max_length=100, blank=True)
    
    # Financial details
    purchase_price = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )    current_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    salvage_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0)]
    )
    
    # Depreciation settings
    depreciation_method = models.CharField(
        max_length=12,
        choices=DepreciationMethod.choices,
        default=DepreciationMethod.STRAIGHT_LINE
    )
    useful_life_years = models.PositiveIntegerField(
        default=5,
        help_text="Expected useful life in years"
    )
    depreciation_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0,
        help_text="Annual depreciation rate percentage"
    )
    
    # Dates
    purchase_date = models.DateField()
    in_service_date = models.DateField()
    disposal_date = models.DateField(null=True, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    location = models.CharField(max_length=200, blank=True)
    condition = models.CharField(max_length=100, blank=True)
    
    # Related transaction
    purchase_transaction = models.ForeignKey(
        EnhancedTransaction,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='purchased_assets'
    )
    
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'asset_type']),
            models.Index(fields=['purchase_date']),
            models.Index(fields=['is_active']),
        ]
        ordering = ['-purchase_date']

    def __str__(self):
        return f"{self.name} ({self.get_asset_type_display()})"

    @property
    def age_in_years(self):
        """Calculate asset age in years"""
        return (timezone.now().date() - self.in_service_date).days / 365.25

    @property
    def accumulated_depreciation(self):
        """Calculate total depreciation to date"""
        if self.depreciation_method == self.DepreciationMethod.NONE:
            return Decimal('0')
        
        years_in_service = min(self.age_in_years, self.useful_life_years)
        
        if self.depreciation_method == self.DepreciationMethod.STRAIGHT_LINE:
            annual_depreciation = (self.purchase_price - self.salvage_value) / self.useful_life_years
            return Decimal(str(annual_depreciation * years_in_service))
        
        # Add other depreciation methods as needed
        return Decimal('0')

    @property
    def book_value(self):
        """Calculate current book value"""
        return self.purchase_price - self.accumulated_depreciation


# =============================================================================
# RECURRING TRANSACTIONS AND AUTOMATION
# =============================================================================

class RecurringTransactionTemplate(models.Model):
    """
    Templates for recurring transactions (subscriptions, rent, etc.).
    """
    
    class Frequency(models.TextChoices):
        DAILY = 'DAILY', 'Daily'
        WEEKLY = 'WEEKLY', 'Weekly'
        BIWEEKLY = 'BIWEEKLY', 'Bi-weekly'
        MONTHLY = 'MONTHLY', 'Monthly'
        QUARTERLY = 'QUARTERLY', 'Quarterly'
        SEMI_ANNUALLY = 'SEMI_ANUAL', 'Semi-annually'
        ANNUALLY = 'ANNUALLY', 'Annually'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='recurring_templates'
    )
    
    # Template details
    name = models.CharField(max_length=200)
    description = models.CharField(max_length=255)
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        related_name='recurring_templates'
    )
    
    # Transaction details
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    type = models.CharField(
        max_length=3,
        choices=EnhancedTransaction.TransactionType.choices
    )
    payment_method = models.CharField(
        max_length=6,
        choices=EnhancedTransaction.PaymentMethod.choices,
        default=EnhancedTransaction.PaymentMethod.BANK_TRANSFER
    )
    
    # Recurrence settings
    frequency = models.CharField(max_length=12, choices=Frequency.choices)
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    next_due_date = models.DateField()
    
    # Automation settings
    auto_generate = models.BooleanField(
        default=False,
        help_text="Automatically generate transactions"
    )
    reminder_days_before = models.PositiveIntegerField(
        default=3,
        help_text="Days before due date to send reminder"
    )
    
    # Status
    is_active = models.BooleanField(default=True)
    total_generated = models.PositiveIntegerField(default=0)
    last_generated_date = models.DateField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'is_active']),
            models.Index(fields=['next_due_date']),
            models.Index(fields=['auto_generate']),
        ]
        ordering = ['next_due_date']

    def __str__(self):
        return f"{self.name} ({self.get_frequency_display()})"

    def calculate_next_due_date(self):
        """Calculate the next due date based on frequency"""
        from dateutil.relativedelta import relativedelta
        
        if self.frequency == self.Frequency.DAILY:
            return self.next_due_date + timezone.timedelta(days=1)
        elif self.frequency == self.Frequency.WEEKLY:
            return self.next_due_date + timezone.timedelta(weeks=1)
        elif self.frequency == self.Frequency.BIWEEKLY:
            return self.next_due_date + timezone.timedelta(weeks=2)
        elif self.frequency == self.Frequency.MONTHLY:
            return self.next_due_date + relativedelta(months=1)
        elif self.frequency == self.Frequency.QUARTERLY:
            return self.next_due_date + relativedelta(months=3)
        elif self.frequency == self.Frequency.SEMI_ANNUALLY:
            return self.next_due_date + relativedelta(months=6)
        elif self.frequency == self.Frequency.ANNUALLY:
            return self.next_due_date + relativedelta(years=1)
        
        return self.next_due_date

    def generate_transaction(self):
        """Generate a transaction from this template"""
        if not self.is_active or (self.end_date and self.next_due_date > self.end_date):
            return None
        
        transaction = EnhancedTransaction.objects.create(
            profile=self.profile,
            category=self.category,
            amount=self.amount,
            type=self.type,
            payment_method=self.payment_method,
            description=f"{self.description} (Auto-generated)",
            date=self.next_due_date,
            recurring_template=self
        )
        
        # Update template
        self.total_generated += 1
        self.last_generated_date = self.next_due_date
        self.next_due_date = self.calculate_next_due_date()
        self.save()
        
        return transaction


# =============================================================================
# BUDGET PLANNING AND VARIANCE ANALYSIS
# =============================================================================

class Budget(models.Model):
    """
    Budget planning with period-based targets and variance analysis.
    """
    
    class BudgetPeriod(models.TextChoices):
        MONTHLY = 'MONTHLY', 'Monthly'
        QUARTERLY = 'QUARTERLY', 'Quarterly'
        ANNUALLY = 'ANNUALLY', 'Annually'
    
    class BudgetStatus(models.TextChoices):
        DRAFT = 'DRAFT', 'Draft'
        ACTIVE = 'ACTIVE', 'Active'
        COMPLETED = 'COMPLETED', 'Completed'
        ARCHIVED = 'ARCHIVED', 'Archived'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='budgets'
    )
    
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    
    # Period settings
    period_type = models.CharField(max_length=10, choices=BudgetPeriod.choices)
    start_date = models.DateField()
    end_date = models.DateField()
      # Budget totals
    total_income_budget = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    total_expense_budget = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0')
    )
    
    # Status
    status = models.CharField(
        max_length=10,
        choices=BudgetStatus.choices,
        default=BudgetStatus.DRAFT
    )
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['start_date', 'end_date']),
        ]
        ordering = ['-start_date']

    def __str__(self):
        return f"{self.name} ({self.start_date} to {self.end_date})"

    @property
    def net_budget(self):
        """Calculate net budget (income - expenses)"""
        return self.total_income_budget - self.total_expense_budget

    def calculate_actuals(self):
        """Calculate actual income and expenses for the budget period"""
        from django.db.models import Sum, Q
        
        actuals = EnhancedTransaction.objects.filter(
            profile=self.profile,
            date__gte=self.start_date,
            date__lte=self.end_date
        ).aggregate(
            total_income=Sum(
                'amount',
                filter=Q(type=EnhancedTransaction.TransactionType.INCOME)
            ),
            total_expenses=Sum(
                'amount',
                filter=Q(type=EnhancedTransaction.TransactionType.EXPENSE)
            )
        )
        
        return {
            'income': actuals['total_income'] or Decimal('0'),
            'expenses': actuals['total_expenses'] or Decimal('0'),
            'net': (actuals['total_income'] or Decimal('0')) - (actuals['total_expenses'] or Decimal('0'))
        }

    @property
    def variance_analysis(self):
        """Calculate budget vs actual variance"""
        actuals = self.calculate_actuals()
        
        return {
            'income_variance': actuals['income'] - self.total_income_budget,
            'expense_variance': actuals['expenses'] - self.total_expense_budget,
            'net_variance': actuals['net'] - self.net_budget,
            'income_variance_pct': (
                (actuals['income'] - self.total_income_budget) / self.total_income_budget * 100
                if self.total_income_budget else 0
            ),
            'expense_variance_pct': (
                (actuals['expenses'] - self.total_expense_budget) / self.total_expense_budget * 100
                if self.total_expense_budget else 0
            )
        }


class BudgetLineItem(models.Model):
    """
    Individual budget line items by category.
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    budget = models.ForeignKey(
        Budget,
        on_delete=models.CASCADE,
        related_name='line_items'
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name='budget_line_items'
    )
    
    budgeted_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['budget', 'category']
        ordering = ['category__name']

    def __str__(self):
        return f"{self.category.name}: {self.budgeted_amount}"

    @property
    def actual_amount(self):
        """Calculate actual spending for this category in the budget period"""
        return EnhancedTransaction.objects.filter(
            profile=self.budget.profile,
            category=self.category,
            date__gte=self.budget.start_date,
            date__lte=self.budget.end_date
        ).aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0')

    @property
    def variance(self):
        """Calculate variance between budgeted and actual"""
        return self.actual_amount - self.budgeted_amount

    @property
    def variance_percentage(self):
        """Calculate variance as percentage"""
        if self.budgeted_amount == 0:
            return 0
        return (self.variance / self.budgeted_amount) * 100


# =============================================================================
# FINANCIAL ANALYTICS AND REPORTING
# =============================================================================

class FinancialRatio(models.Model):
    """
    Financial ratio calculations and tracking for business profiles.
    """
    
    class RatioType(models.TextChoices):
        LIQUIDITY = 'LIQUIDITY', 'Liquidity Ratio'
        PROFITABILITY = 'PROFIT', 'Profitability Ratio'
        EFFICIENCY = 'EFFICIENCY', 'Efficiency Ratio'
        LEVERAGE = 'LEVERAGE', 'Leverage Ratio'
        MARKET = 'MARKET', 'Market Ratio'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='financial_ratios'
    )
    
    ratio_name = models.CharField(max_length=100)
    ratio_type = models.CharField(max_length=10, choices=RatioType.choices)
    ratio_value = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True
    )
    
    # Calculation period
    calculation_date = models.DateField()
    period_start = models.DateField()
    period_end = models.DateField()
    
    # Benchmark comparison
    industry_average = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True
    )
    target_value = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        null=True,
        blank=True
    )
    
    # Calculation details
    numerator = models.DecimalField(max_digits=15, decimal_places=2)
    denominator = models.DecimalField(max_digits=15, decimal_places=2)
    calculation_notes = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'ratio_type']),
            models.Index(fields=['calculation_date']),
        ]
        unique_together = ['profile', 'ratio_name', 'calculation_date']
        ordering = ['-calculation_date']

    def __str__(self):
        return f"{self.ratio_name}: {self.ratio_value}"

    @property
    def performance_vs_target(self):
        """Compare ratio performance against target"""
        if not self.target_value or not self.ratio_value:
            return None
        
        return {
            'difference': self.ratio_value - self.target_value,
            'percentage_diff': ((self.ratio_value - self.target_value) / self.target_value) * 100,
            'meets_target': self.ratio_value >= self.target_value
        }

    @property
    def performance_vs_industry(self):
        """Compare ratio performance against industry average"""
        if not self.industry_average or not self.ratio_value:
            return None
        
        return {
            'difference': self.ratio_value - self.industry_average,
            'percentage_diff': ((self.ratio_value - self.industry_average) / self.industry_average) * 100,
            'above_average': self.ratio_value >= self.industry_average
        }


# =============================================================================
# AUDIT TRAIL AND DATA INTEGRITY
# =============================================================================

class AuditLog(models.Model):
    """
    Comprehensive audit trail for all financial data changes.
    """
    
    class ActionType(models.TextChoices):
        CREATE = 'CREATE', 'Create'
        UPDATE = 'UPDATE', 'Update'
        DELETE = 'DELETE', 'Delete'
        VIEW = 'VIEW', 'View'
        EXPORT = 'EXPORT', 'Export'
        IMPORT = 'IMPORT', 'Import'
        SYNC = 'SYNC', 'Synchronization'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='audit_logs'
    )
    
    # Action details
    action_type = models.CharField(max_length=6, choices=ActionType.choices)
    table_name = models.CharField(max_length=100)
    record_id = models.CharField(max_length=100)
    
    # Content tracking
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.CharField(max_length=100)
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Change details
    field_changes = models.JSONField(
        null=True,
        blank=True,
        help_text="JSON object containing before/after values"
    )
    
    # Context
    user_agent = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    session_id = models.CharField(max_length=100, blank=True)
    
    # Metadata
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'timestamp']),
            models.Index(fields=['action_type', 'timestamp']),
            models.Index(fields=['table_name', 'record_id']),
        ]
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.get_action_type_display()} on {self.table_name} at {self.timestamp}"


# =============================================================================
# SYSTEM CONFIGURATION AND SETTINGS
# =============================================================================

class SystemSetting(models.Model):
    """
    System-wide and profile-specific configuration settings.
    """
    
    class SettingType(models.TextChoices):
        SYSTEM = 'SYSTEM', 'System Setting'
        PROFILE = 'PROFILE', 'Profile Setting'
        TAX = 'TAX', 'Tax Setting'
        NOTIFICATION = 'NOTIFICATION', 'Notification Setting'
        CALCULATION = 'CALCULATION', 'Calculation Setting'
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='settings',
        null=True,
        blank=True,
        help_text="Leave blank for system-wide settings"
    )
    
    setting_type = models.CharField(max_length=12, choices=SettingType.choices)
    key = models.CharField(max_length=100)
    value = models.TextField()
    data_type = models.CharField(
        max_length=20,
        choices=[
            ('string', 'String'),
            ('integer', 'Integer'),
            ('decimal', 'Decimal'),
            ('boolean', 'Boolean'),
            ('json', 'JSON'),
            ('date', 'Date'),
        ],
        default='string'
    )
    
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['profile', 'setting_type']),
            models.Index(fields=['key']),
        ]
        unique_together = ['profile', 'key']

    def __str__(self):
        profile_name = self.profile.name if self.profile else "System"
        return f"{profile_name}: {self.key}"

    def get_typed_value(self):
        """Return the value converted to its appropriate data type"""
        if self.data_type == 'integer':
            return int(self.value)
        elif self.data_type == 'decimal':
            return Decimal(self.value)
        elif self.data_type == 'boolean':
            return self.value.lower() in ('true', '1', 'yes', 'on')
        elif self.data_type == 'json':
            import json
            return json.loads(self.value)
        elif self.data_type == 'date':
            from datetime import datetime
            return datetime.fromisoformat(self.value).date()
        else:
            return self.value
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
- Budget planning and variance analysis
- Recurring transactions and automation
- Financial analytics and reporting
- Comprehensive audit trail
- Bank account reconciliation
- Investment tracking
- Expense reporting
- Cash flow forecasting

Privacy & Security:
- UUID-based primary keys for privacy
- PIN-based authentication with secure hashing
- Comprehensive audit trail for all changes
- No personally identifiable information stored without encryption

Author: Fedha Development Team
Last Updated: May 26, 2025
"""

import uuid
import hashlib
from decimal import Decimal
from datetime import datetime, timedelta
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
from django.conf import settings


# =============================================================================
# ENHANCED UUID GENERATION WITH BUSINESS/PERSONAL PREFIXES
# =============================================================================

def generate_business_uuid():
    """
    Generate UUID with 'B' prefix for business accounts.
    Format: B-{7_char_uuid}
    Example: B-A1B2C3D
    """
    short_uuid = str(uuid.uuid4()).replace('-', '')[:7].upper()
    return f"B-{short_uuid}"


def generate_personal_uuid():
    """
    Generate UUID with 'P' prefix for personal accounts.
    Format: P-{7_char_uuid}
    Example: P-X9Y8Z7W
    """
    short_uuid = str(uuid.uuid4()).replace('-', '')[:7].upper()
    return f"P-{short_uuid}"


def generate_profile_uuid(profile_type: str = 'PERS'):
    """
    Generate appropriate UUID based on profile type.
    
    Args:
        profile_type: 'BIZ' for business, 'PERS' for personal
        
    Returns:
        String UUID with appropriate prefix (9 characters total: X-XXXXXXX)
    """
    if profile_type == 'BIZ':
        return generate_business_uuid()
    elif profile_type == 'PERS':
        return generate_personal_uuid()
    else:
        # Default to personal if type not specified
        return generate_personal_uuid()


# =============================================================================
# CORE PROFILE MANAGEMENT
# =============================================================================

class Profile(models.Model):
    """
    Core profile model for both personal and business users.
    
    Privacy Features:
    - UUID primary key prevents enumeration
    - PIN-based authentication (no passwords stored)
    - Hashed PIN with application secret salt
    - Optional display name for customization
    
    Business vs Personal:
    - Profile type determines available features
    - Business profiles have additional invoice/client features    - Personal profiles focus on budget tracking and goals
    """
    
    class ProfileType(models.TextChoices):
        BUSINESS = 'BIZ', 'Business'
        PERSONAL = 'PERS', 'Personal'
    
    id = models.CharField(
        primary_key=True,
        max_length=9,  # B-XXXXXXX or P-XXXXXXX format
        editable=False,
        verbose_name="Profile ID",
        help_text="Unique identifier with B/P prefix for business/personal accounts (9 chars: X-XXXXXXX)"
    )
    
    # Enhanced: Add user_id field for 8-digit user IDs (for cross-device compatibility)
    user_id = models.CharField(
        max_length=8,
        unique=True,
        null=True,
        blank=True,
        help_text="8-digit user ID for cross-device login (e.g., 12345678)"
    )
    
    name = models.CharField(
        max_length=100,
        blank=True,
        help_text="Optional profile display name"
    )
    
    # Enhanced: Add email field for user communication
    email = models.EmailField(
        blank=True,
        null=True,
        help_text="Email address for notifications and account recovery"
    )
    
    profile_type = models.CharField(
        max_length=4,
        choices=ProfileType.choices,
        default=ProfileType.PERSONAL,
        help_text="Determines available features and UI"
    )
    pin_hash = models.CharField(
        max_length=128,
        help_text="SHA-256 hash of 4-digit PIN with application salt"
    )
    
    # Base currency and localization
    base_currency = models.CharField(
        max_length=3,
        default='KES',
        help_text="ISO 4217 currency code for primary calculations"
    )
    timezone = models.CharField(
        max_length=50,
        default='GMT+3',
        help_text="Timezone for date/time display"
    )
      # Status tracking
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(
        default=True,
        help_text="Soft delete flag - inactive profiles cannot authenticate"
    )
    
    # Enhanced: Add alias for date_created for compatibility
    @property
    def date_created(self):
        """Alias for created_at for backwards compatibility"""
        return self.created_at
    
    # Enhanced: Add is_business property for compatibility
    @property
    def is_business(self):
        """Check if this is a business profile"""
        return self.profile_type == self.ProfileType.BUSINESS
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile_type']),
            models.Index(fields=['created_at']),
            models.Index(fields=['is_active']),
            models.Index(fields=['user_id']),  # Enhanced: Index for user_id lookups
            models.Index(fields=['email']),     # Enhanced: Index for email lookups
        ]
        ordering = ['-created_at']
        verbose_name = "User Profile"
        verbose_name_plural = "User Profiles"

    def get_profile_type_display(self):
        """
        Return human-readable display name for profile type.
        
        Returns:
            String representation of the profile type
        """
        # Django automatically provides this method via TextChoices,
        # but we can customize it if needed
        type_mapping = {
            'BIZ': 'Business',
            'PERS': 'Personal'
        }
        return type_mapping.get(self.profile_type, self.profile_type)

    def __str__(self):
        display_name = self.name or "Unnamed Profile"
        return f"{display_name} ({self.get_profile_type_display()})"
    
    def save(self, *args, **kwargs):
        """
        Override save to automatically generate UUID with appropriate prefix.
        """
        if not self.id:
            self.id = generate_profile_uuid(self.profile_type)
        super().save(*args, **kwargs)    
    
    @staticmethod
    def hash_pin(raw_pin: str) -> str:
        """
        Securely hash a PIN with application salt.
        
        Args:
            raw_pin: PIN string (minimum 3 characters, alphanumeric allowed)
            
        Returns:
            SHA-256 hash of PIN + application secret
            
        Raises:
            ValueError: If PIN is less than 3 characters
        """        
        if len(raw_pin) < 3:
            raise ValueError("PIN must be at least 3 characters")
        
        salted = f"{raw_pin}{settings.SECRET_KEY}"
        return hashlib.sha256(salted.encode()).hexdigest()
    
    @staticmethod
    def generate_user_id():
        """
        Generate a unique 8-digit user ID for cross-device login.
        
        Returns:
            String: 8-digit numeric user ID (e.g., "12345678")
        """
        import random
        while True:
            # Generate 8-digit number
            user_id = f"{random.randint(10000000, 99999999)}"
            # Check if it's unique
            if not Profile.objects.filter(user_id=user_id).exists():
                return user_id
    
    def verify_pin(self, raw_pin: str) -> bool:
        """
        Verify a raw PIN against the stored hash.
        
        Args:
            raw_pin: PIN string to verify
            
        Returns:
            True if PIN matches, False otherwise
        """
        try:
            return self.pin_hash == self.hash_pin(raw_pin)
        except ValueError:
            return False

    def set_pin(self, raw_pin: str):
        """
        Set a new PIN for the profile.
        
        Args:
            raw_pin: PIN string (minimum 3 characters, alphanumeric allowed)
        """
        self.pin_hash = self.hash_pin(raw_pin)

    def record_login(self):
        """Record successful login timestamp."""
        self.last_login = timezone.now()
        self.save(update_fields=['last_login'])


# =============================================================================
# HIERARCHICAL CATEGORY SYSTEM
# =============================================================================

class Category(models.Model):
    """
    Hierarchical category system for transactions, supporting both business 
    and personal categorization with parent-child relationships.
    
    Features:
    - Self-referential hierarchy (parent categories can have subcategories)
    - Profile-specific custom categories + system defaults
    - Tax-deductible marking for business expenses
    - Industry-specific default categories
    - Support for all transaction types (income, expense, transfer, etc.)
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
    name = models.CharField(
        max_length=100,
        help_text="Category name (e.g., 'Office Supplies', 'Client Payments')"
    )
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        related_name='subcategories',
        help_text="Parent category for hierarchical organization"
    )
    type = models.CharField(
        max_length=3, 
        choices=CategoryType.choices,
        help_text="Primary categorization for financial reporting"
    )
    
    # Tax and business features
    is_tax_deductible = models.BooleanField(
        default=False,
        help_text="Mark if this category represents tax-deductible expenses"
    )
    tax_code = models.CharField(
        max_length=20,
        blank=True,
        help_text="Tax jurisdiction specific code for reporting"
    )
    
    # System management
    is_system_default = models.BooleanField(
        default=False,
        help_text="System-provided categories that apply to all profiles"
    )
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(
        default=0,
        help_text="Display order within parent category"
    )
    
    # Metadata
    description = models.TextField(
        blank=True,
        help_text="Detailed description of category usage"
    )
    created_at = models.DateTimeField(auto_now_add=True)    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'type']),
            models.Index(fields=['parent']),
            models.Index(fields=['is_system_default']),
        ]
        unique_together = [['profile', 'name', 'parent']]
        verbose_name_plural = "Categories"
        ordering = ['parent__name', 'sort_order', 'name']

    def __str__(self):
        """Return the full hierarchical path of this category."""
        path = []
        current = self
        while current:
            path.append(current.name)
            current = current.parent
        return " > ".join(reversed(path))

    @property
    def full_path(self):
        """Return the full hierarchical path of this category."""
        return str(self)

    @property
    def depth_level(self):
        """Calculate the depth level in the hierarchy (0 = root)."""
        level = 0
        current = self.parent
        while current:
            level += 1
            current = current.parent
        return level

    def get_descendants(self, include_self=False):
        """Get all descendant categories."""
        descendants = []
        if include_self:
            descendants.append(self)
        # Use the related_name 'subcategories' from the parent field
        for child in Category.objects.filter(parent=self, is_active=True):
            descendants.extend(child.get_descendants(include_self=True))
        return descendants


# =============================================================================
# CLIENT MANAGEMENT SYSTEM
# =============================================================================

class Client(models.Model):
    """
    Client management for business profiles to handle invoicing and payments.
    
    Features:
    - Complete contact information management
    - Credit limit and payment terms tracking
    - Payment history and aging analysis
    - Client-specific pricing and discounts
    - Integration with invoice and transaction systems
    """
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile, 
        on_delete=models.CASCADE, 
        related_name='clients',
        help_text="Business profile that owns this client"
    )
    
    # Basic information
    name = models.CharField(
        max_length=200,
        help_text="Client business or individual name"
    )
    email = models.EmailField(
        blank=True,
        help_text="Primary email for invoices and communication"
    )
    phone = models.CharField(
        max_length=20, 
        blank=True,
        help_text="Primary phone number"
    )
    
    # Address information
    address_line1 = models.CharField(max_length=100, blank=True)
    address_line2 = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=50, blank=True)
    state_province = models.CharField(max_length=50, blank=True)
    postal_code = models.CharField(max_length=20, blank=True)
    country = models.CharField(max_length=50, blank=True)
    
    # Financial settings
    credit_limit = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0'),
        help_text="Maximum credit allowed for this client"
    )
    payment_terms_days = models.PositiveIntegerField(
        default=30,
        help_text="Default payment terms in days (Net 30, etc.)"
    )
    discount_percentage = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Default discount percentage for this client"
    )
    
    # Business details
    tax_id = models.CharField(
        max_length=50,
        blank=True,
        help_text="Client's tax identification number"
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        help_text="Preferred currency for transactions"
    )
    
    # Status tracking
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_transaction_date = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(
        blank=True,
        help_text="Internal notes about this client"
    )    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'is_active']),
            models.Index(fields=['name']),
            models.Index(fields=['email']),
        ]
        unique_together = [['profile', 'email']]
        ordering = ['name']

    def __str__(self):
        return f"{self.name}"

    @property
    def full_address(self):
        """Return formatted full address."""
        parts = [
            self.address_line1,
            self.address_line2,
            self.city,
            self.state_province,
            self.postal_code,
            self.country
        ]
        return ", ".join(filter(None, parts))

    def get_outstanding_balance(self):
        """Calculate total outstanding invoice balance for this client."""
        from django.apps import apps
        Invoice = apps.get_model('api', 'Invoice')
        return Invoice.objects.filter(
            client=self,
            status__in=['SENT', 'OVERDUE', 'PARTIALLY_PAID']
        ).aggregate(
            total=models.Sum('total_amount')
        )['total'] or Decimal('0')

    def get_paid_balance(self):
        """Calculate total paid amount from this client."""
        from django.apps import apps
        Invoice = apps.get_model('api', 'Invoice')
        return Invoice.objects.filter(
            client=self,
            status='PAID'
        ).aggregate(
            total=models.Sum('total_amount')
        )['total'] or Decimal('0')

    @property
    def is_over_credit_limit(self):
        """Check if client has exceeded their credit limit."""
        return self.get_outstanding_balance() > self.credit_limit

    def update_last_transaction_date(self):
        """Update the last transaction date to now."""
        self.last_transaction_date = timezone.now()
        self.save(update_fields=['last_transaction_date'])


# =============================================================================
# ENHANCED TRANSACTION SYSTEM
# =============================================================================

class EnhancedTransaction(models.Model):
    """
    Enhanced transaction model with comprehensive features:
    - Multiple currencies with exchange rate tracking
    - Attachments support (receipts, documents)
    - Split transactions for complex entries
    - Recurring transaction template integration
    - Tax categorization and reporting
    - Client relationship tracking
    - Invoice payment linkage
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
        DIGITAL_WALLET = 'WALLET', 'Digital Wallet'
        CRYPTOCURRENCY = 'CRYPTO', 'Cryptocurrency'
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
        related_name='transactions',
        help_text="Categorization for reporting and budgeting"
    )
    
    # Basic transaction details
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Transaction amount in specified currency"
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        help_text="ISO 4217 currency code"
    )
    exchange_rate = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        default=Decimal('1.0'),
        help_text="Exchange rate to profile's base currency"
    )
    type = models.CharField(
        max_length=3, 
        choices=TransactionType.choices,
        help_text="Primary transaction classification"
    )
    payment_method = models.CharField(
        max_length=6,
        choices=PaymentMethod.choices,
        default=PaymentMethod.CASH,
        help_text="How the transaction was executed"
    )
    
    # Transaction metadata
    description = models.CharField(
        max_length=255,
        help_text="Brief description of the transaction"
    )
    notes = models.TextField(
        blank=True,
        help_text="Detailed notes or memo"
    )
    reference_number = models.CharField(
        max_length=100, 
        blank=True,
        help_text="External reference (check number, confirmation code, etc.)"
    )
    date = models.DateField(
        default=timezone.now,
        help_text="Date when transaction occurred"
    )
    
    # Relationships
    client = models.ForeignKey(
        Client,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
        help_text="Associated client for business transactions"
    )
    invoice = models.ForeignKey(
        'Invoice',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        help_text="Invoice this transaction pays against"
    )
    
    # Split transaction support
    parent_transaction = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='split_transactions',
        help_text="Parent transaction if this is a split"
    )
    
    # Recurring transaction template
    recurring_template = models.ForeignKey(
        'RecurringTransactionTemplate',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='generated_transactions',
        help_text="Template that generated this transaction"
    )
    
    # Status and tracking fields
    is_reconciled = models.BooleanField(
        default=False,
        help_text="Whether transaction has been reconciled with bank statement"
    )
    is_tax_relevant = models.BooleanField(
        default=False,
        help_text="Whether transaction should be included in tax reporting"
    )
    is_synced = models.BooleanField(
        default=True,
        help_text="Synchronization status with mobile apps"
    )
    
    # Attachments (simplified - could be expanded to separate model)
    receipt_url = models.URLField(
        blank=True,
        help_text="URL to uploaded receipt or document"
    )
    
    # Audit trail
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'date']),
            models.Index(fields=['type', 'date']),
            models.Index(fields=['category', 'date']),
            models.Index(fields=['client', 'date']),
            models.Index(fields=['is_tax_relevant']),
            models.Index(fields=['is_reconciled']),
        ]
        ordering = ['-date', '-created_at']
        verbose_name = "Transaction"
        verbose_name_plural = "Transactions"

    def __str__(self):
        # Get human-readable type display
        type_mapping = {
            'IN': 'Income',
            'EX': 'Expense', 
            'TR': 'Transfer',
            'ADJ': 'Adjustment'
        }
        type_display = type_mapping.get(self.type, self.type)
        return f"{type_display}: {self.currency} {self.amount} - {self.description}"

    @property
    def amount_in_base_currency(self):
        """Convert amount to profile's base currency using exchange rate."""
        return self.amount * self.exchange_rate

    def clean(self):
        """Validate transaction data."""
        if self.amount <= 0:
            raise ValidationError("Transaction amount must be positive")
        
        if self.parent_transaction and self.parent_transaction.parent_transaction:
            raise ValidationError("Split transactions cannot be nested more than one level")
        
        if self.parent_transaction and self.parent_transaction.profile != self.profile:
            raise ValidationError("Split transactions must belong to the same profile")

    def create_split_transaction(self, amount, category, description):
        # Query for existing split transactions using the manager
        existing_splits = EnhancedTransaction.objects.filter(
            parent_transaction=self
        ).aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0')
        available = self.amount - existing_splits
        if amount > available:
            raise ValidationError(f"Split amount {amount} exceeds available amount {available}")
        return EnhancedTransaction.objects.create(
            profile=self.profile,
            category=category,
            amount=amount,
            currency=self.currency,
            exchange_rate=self.exchange_rate,
            type=self.type,
            payment_method=self.payment_method,
            description=description,
            date=self.date,
            parent_transaction=self,
            is_tax_relevant=self.is_tax_relevant
        )


# =============================================================================
# INVOICE MANAGEMENT SYSTEM
# =============================================================================

class Invoice(models.Model):
    """
    Professional invoice management system for business profiles.
    
    Features:
    - Customizable invoice templates
    - Automatic numbering sequences
    - Payment tracking and aging analysis
    - Multi-currency support
    - PDF generation capability
    - Professional business workflows
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
    invoice_number = models.CharField(
        max_length=50, 
        unique=True,
        help_text="Unique invoice number (auto-generated or custom)"
    )
    reference = models.CharField(
        max_length=100, 
        blank=True,
        help_text="Client reference or PO number"
    )
    
    # Dates
    issue_date = models.DateField(
        default=timezone.now,
        help_text="Date invoice was issued"
    )
    due_date = models.DateField(
        help_text="Payment due date"
    )
    sent_date = models.DateTimeField(
        null=True, 
        blank=True,
        help_text="Date invoice was sent to client"
    )
    payment_date = models.DateTimeField(
        null=True, 
        blank=True,
        help_text="Date invoice was fully paid"
    )
    
    # Financial details
    subtotal = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total before tax and discounts"
    )
    tax_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Tax rate percentage"
    )
    tax_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0'),
        help_text="Calculated tax amount"
    )
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Discount percentage applied"
    )
    discount_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0'),
        help_text="Calculated discount amount"
    )
    total_amount = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Final invoice total"
    )
    paid_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0'),
        help_text="Amount paid to date"
    )
    
    # Invoice content and customization
    notes = models.TextField(
        blank=True,
        help_text="Internal notes visible on invoice"
    )
    terms_and_conditions = models.TextField(
        blank=True,
        help_text="Payment terms and conditions"
    )
    footer_text = models.TextField(
        blank=True,
        help_text="Footer text for invoice"
    )
    
    # Status and tracking
    status = models.CharField(
        max_length=10,
        choices=InvoiceStatus.choices,
        default=InvoiceStatus.DRAFT
    )
    currency = models.CharField(
        max_length=3, 
        default='USD',
        help_text="Invoice currency"
    )
    
    # Template and branding
    template_name = models.CharField(
        max_length=100,
        default='default',
        help_text="Invoice template to use for PDF generation"
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['client', 'status']),
            models.Index(fields=['due_date']),
            models.Index(fields=['invoice_number']),
            models.Index(fields=['issue_date']),
        ]
        ordering = ['-issue_date', '-created_at']
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.client.name}"

    @property
    def outstanding_amount(self):
        """Calculate remaining unpaid amount."""
        return self.total_amount - self.paid_amount

    @property
    def is_overdue(self):
        """Check if invoice is past due date."""
        return (
            self.due_date < timezone.now().date() and 
            self.status not in [self.InvoiceStatus.PAID, self.InvoiceStatus.CANCELLED]
        )

    @property
    def days_overdue(self):
        """Calculate days past due date."""
        if self.is_overdue:        
            return (timezone.now().date() - self.due_date).days
        return 0

    @property
    def age_in_days(self):
        """Calculate days since invoice was issued."""
        return (timezone.now().date() - self.issue_date).days

    def calculate_totals(self):
        # Calculate totals from line items using explicit query to avoid forward reference issues
        from django.apps import apps
        InvoiceLineItem = apps.get_model('api', 'InvoiceLineItem')
        line_items = InvoiceLineItem.objects.filter(invoice=self)
        line_items_total = line_items.aggregate(
            total=models.Sum('total')
        )['total'] or Decimal('0')
        self.subtotal = line_items_total
        self.discount_amount = (self.subtotal * self.discount_percentage) / 100
        discounted_subtotal = self.subtotal - self.discount_amount
        self.tax_amount = (discounted_subtotal * self.tax_rate) / 100
        self.total_amount = discounted_subtotal + self.tax_amount

    def mark_as_sent(self):
        """Mark invoice as sent and record timestamp."""
        self.status = self.InvoiceStatus.SENT
        self.sent_date = timezone.now()
        self.save(update_fields=['status', 'sent_date'])

    def record_payment(self, amount, payment_date=None):
        """Record a payment against this invoice."""
        if payment_date is None:
            payment_date = timezone.now()
        
        self.paid_amount += amount
        
        # Update status based on payment
        if self.paid_amount >= self.total_amount:
            self.status = self.InvoiceStatus.PAID
            self.payment_date = payment_date
        elif self.paid_amount > 0:
            self.status = self.InvoiceStatus.PARTIALLY_PAID
        
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
    
    description = models.CharField(
        max_length=255,
        help_text="Product or service description"
    )
    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=3,
        validators=[MinValueValidator(Decimal('0.001'))],
        help_text="Quantity of product/service"
    )
    unit_price = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0'))],
        help_text="Price per unit"
    )
    total = models.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Line total (quantity × unit_price)"
    )
    
    # Optional product/service categorization
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text="Category for expense tracking"
    )
    
    # Additional details
    unit_of_measure = models.CharField(
        max_length=20,
        blank=True,
        help_text="Unit of measure (hours, pieces, etc.)"
    )
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0'),
        validators=[MinValueValidator(0), MaxValueValidator(100)],
        help_text="Line-specific discount percentage"
    )
    
    # Sorting and organization
    sort_order = models.PositiveIntegerField(
        default=0,
        help_text="Display order on invoice"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)    
    class Meta:
        app_label = 'fedha'
        ordering = ['sort_order', 'id']
        verbose_name = "Invoice Line Item"
        verbose_name_plural = "Invoice Line Items"

    def __str__(self):
        return f"{self.description} (x{self.quantity})"

    def save(self, *args, **kwargs):
        """Auto-calculate total when saving."""
        # Apply line discount if any
        discounted_price = self.unit_price * (1 - self.discount_percentage / 100)
        self.total = self.quantity * discounted_price
        super().save(*args, **kwargs)


# =============================================================================
# LOAN MANAGEMENT SYSTEM
# =============================================================================

class Loan(models.Model):
    """
    Comprehensive loan tracking with support for complex interest calculations.
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
        SEMI_ANNUALLY = 'SEMI_ANNUALLY', 'Semi-annually'
        ANNUALLY = 'ANNUALLY', 'Annually'

    class LoanStatus(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        PAID_OFF = 'PAID_OFF', 'Paid Off'
        DEFAULTED = 'DEFAULTED', 'Defaulted'
        REFINANCED = 'REFINANCED', 'Refinanced'
        SUSPENDED = 'SUSPENDED', 'Suspended'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='loans')
    name = models.CharField(max_length=200)
    lender = models.CharField(max_length=200)
    loan_type = models.CharField(max_length=10, choices=LoanType.choices)
    account_number = models.CharField(max_length=50, blank=True)
    principal_amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0.01)])
    annual_interest_rate = models.DecimalField(max_digits=8, decimal_places=5, validators=[MinValueValidator(0), MaxValueValidator(100)])
    interest_type = models.CharField(max_length=10, choices=InterestType.choices)
    payment_frequency = models.CharField(
        max_length=15,  # Increase from current value to 15 (was likely 10)
        choices=PaymentFrequency.choices,
        default=PaymentFrequency.MONTHLY,
        help_text="Frequency of loan payments"
    )
    number_of_payments = models.PositiveIntegerField()
    payment_amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    origination_date = models.DateField()
    first_payment_date = models.DateField()
    maturity_date = models.DateField()
    current_balance = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'))
    total_paid = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'))
    payments_made = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=12, choices=LoanStatus.choices, default=LoanStatus.ACTIVE)
    late_fee_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0'))
    grace_period_days = models.PositiveIntegerField(default=0)
    collateral_value = models.DecimalField(
        max_digits=15, 
        decimal_places=2, 
        default=Decimal('0'),
        help_text="Current value of collateral securing this loan"
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:
        app_label = 'fedha'
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
        return max(0, self.number_of_payments - self.payments_made)

    @property
    def monthly_interest_rate(self):
        frequency_map = {
            'MONTHLY': 12,
            'QUARTERLY': 4,
            'SEMI_ANNUALLY': 2,
            'ANNUALLY': 1,
            'WEEKLY': 52,
            'BIWEEKLY': 26,
            'DAILY': 365
        }
        periods_per_year = frequency_map.get(self.payment_frequency, 12)
        return self.annual_interest_rate / 100 / periods_per_year

    @property
    def total_interest_paid(self):
        return self.total_paid - (self.principal_amount - self.current_balance)

    @property
    def loan_to_value_ratio(self):
        if hasattr(self, 'collateral_value') and self.collateral_value > 0:
            return (self.current_balance / self.collateral_value) * 100
        return None

    def calculate_payment_amount(self):
        if self.interest_type == self.InterestType.REDUCING_BALANCE:
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
        return self.payment_amount

class LoanPayment(models.Model):
    """
    Individual loan payments with principal/interest breakdown.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    loan = models.ForeignKey(Loan, on_delete=models.CASCADE, related_name='payments')
    payment_number = models.PositiveIntegerField()
    scheduled_date = models.DateField()
    actual_date = models.DateField(null=True, blank=True)
    scheduled_amount = models.DecimalField(max_digits=15, decimal_places=2)
    actual_amount = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    principal_amount = models.DecimalField(max_digits=15, decimal_places=2)
    interest_amount = models.DecimalField(max_digits=15, decimal_places=2)
    late_fee = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0'))
    balance_after_payment = models.DecimalField(max_digits=15, decimal_places=2)
    is_paid = models.BooleanField(default=False)
    is_late = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)    
    class Meta:
        app_label = 'fedha'
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
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='goals')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    goal_type = models.CharField(max_length=12, choices=GoalType.choices)
    target_amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0.01)])
    current_amount = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'))
    currency = models.CharField(max_length=3, default='USD')
    start_date = models.DateField(default=timezone.now)
    target_date = models.DateField()
    completion_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=10, choices=GoalStatus.choices, default=GoalStatus.ACTIVE)
    is_automated = models.BooleanField(default=False)
    linked_categories = models.ManyToManyField('Category', blank=True)
    milestone_amount = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    reminder_frequency_days = models.PositiveIntegerField(default=7)
    last_reminder_sent = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:        
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'status']),
            models.Index(fields=['target_date']),
            models.Index(fields=['goal_type']),
        ]
        ordering = ['target_date', '-created_at']

    def __str__(self):
        # Get human-readable goal type display
        goal_type_mapping = {
            'SAVINGS': 'Savings Goal',
            'DEBT': 'Debt Reduction',
            'INVESTMENT': 'Investment Target',
            'EXPENSE': 'Expense Reduction',
            'INCOME': 'Income Increase',
            'EMERGENCY': 'Emergency Fund',
            'RETIREMENT': 'Retirement Planning',
            'OTHER': 'Other'
        }
        goal_type_display = goal_type_mapping.get(self.goal_type, self.goal_type)
        return f"{self.name} - {goal_type_display}"

    @property
    def progress_percentage(self):
        if self.target_amount <= 0:
            return 0
        progress = (self.current_amount / self.target_amount) * 100
        return min(progress, 100)

    @property
    def remaining_amount(self):
        return max(0, self.target_amount - self.current_amount)

    @property
    def days_remaining(self):
        return (self.target_date - timezone.now().date()).days

    @property
    def required_daily_amount(self):
        if self.days_remaining <= 0:
            return self.remaining_amount
        return self.remaining_amount / self.days_remaining

# =============================================================================
# TAX PREPARATION AND COMPLIANCE SYSTEM
# =============================================================================

class TaxJurisdiction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    country_code = models.CharField(max_length=2)
    tax_year_start = models.CharField(max_length=5)
    standard_tax_rate = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0'))
    vat_rate = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0'))
    is_active = models.BooleanField(default=True)    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        app_label = 'fedha'
        unique_together = ['name', 'country_code']
    
    def __str__(self):
        return f"{self.name} ({self.country_code})"

class TaxCategory(models.Model):
    class TaxTreatment(models.TextChoices):
        DEDUCTIBLE = 'DEDUCTIBLE', 'Tax Deductible'
        TAXABLE_INCOME = 'TAXABLE', 'Taxable Income'
        TAX_FREE = 'TAX_FREE', 'Tax Free'
        CAPITAL_GAIN = 'CAPITAL', 'Capital Gain'
        DEPRECIATION = 'DEPRECIATION', 'Depreciation'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    jurisdiction = models.ForeignKey(TaxJurisdiction, on_delete=models.CASCADE, related_name='tax_categories')
    name = models.CharField(max_length=100)
    treatment = models.CharField(max_length=12, choices=TaxTreatment.choices)
    description = models.TextField(blank=True)
    deduction_limit_annual = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    deduction_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)    
    class Meta:
        app_label = 'fedha'
        unique_together = ['jurisdiction', 'name']
        verbose_name_plural = "Tax Categories"

    def __str__(self):
        # Get human-readable treatment display
        treatment_mapping = {
            'DEDUCTIBLE': 'Tax Deductible',
            'TAXABLE': 'Taxable Income',
            'TAX_FREE': 'Tax Free',
            'CAPITAL': 'Capital Gain',
            'DEPRECIATION': 'Depreciation'
        }
        treatment_display = treatment_mapping.get(self.treatment, self.treatment)
        return f"{self.name} ({treatment_display})"

class TaxRecord(models.Model):
    class RecordType(models.TextChoices):
        INCOME = 'INCOME', 'Income Record'
        DEDUCTION = 'DEDUCTION', 'Deduction Record'
        CREDIT = 'CREDIT', 'Tax Credit'
        PAYMENT = 'PAYMENT', 'Tax Payment'
        REFUND = 'REFUND', 'Tax Refund'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='tax_records')
    jurisdiction = models.ForeignKey(TaxJurisdiction, on_delete=models.CASCADE, related_name='tax_records')
    tax_category = models.ForeignKey(TaxCategory, on_delete=models.CASCADE, related_name='tax_records')
    record_type = models.CharField(max_length=10, choices=RecordType.choices)
    tax_year = models.PositiveIntegerField()
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    deductible_amount = models.DecimalField(max_digits=15, decimal_places=2, null=True, blank=True)
    transaction = models.ForeignKey('EnhancedTransaction', on_delete=models.CASCADE, related_name='tax_records', null=True, blank=True)
    description = models.CharField(max_length=255)
    notes = models.TextField(blank=True)
    documentation_required = models.BooleanField(default=False)
    documentation_complete = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    verified_by = models.CharField(max_length=100, blank=True)
    verification_date = models.DateTimeField(null=True, blank=True)    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'tax_year']),
            models.Index(fields=['jurisdiction', 'tax_year']),
            models.Index(fields=['record_type', 'tax_year']),
        ]
        ordering = ['-tax_year', '-created_at']

    def __str__(self):
        # Get human-readable record type display
        record_type_mapping = {
            'INCOME': 'Income Record',
            'DEDUCTION': 'Deduction Record',
            'CREDIT': 'Tax Credit',
            'PAYMENT': 'Tax Payment',
            'REFUND': 'Tax Refund'
        }
        record_type_display = record_type_mapping.get(self.record_type, self.record_type)
        return f"{record_type_display} - {self.tax_year}"

# =============================================================================
# ASSET MANAGEMENT AND DEPRECIATION
# =============================================================================

class Asset(models.Model):
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
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='assets')
    name = models.CharField(max_length=200)
    asset_type = models.CharField(max_length=12, choices=AssetType.choices)
    serial_number = models.CharField(max_length=100, blank=True)
    model_number = models.CharField(max_length=100, blank=True)
    purchase_price = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    current_value = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    salvage_value = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'), validators=[MinValueValidator(0)])
    depreciation_method = models.CharField(max_length=12, choices=DepreciationMethod.choices, default=DepreciationMethod.STRAIGHT_LINE)
    useful_life_years = models.PositiveIntegerField(default=5)
    depreciation_rate = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0'), validators=[MinValueValidator(0)])
    purchase_date = models.DateField()
    in_service_date = models.DateField()
    disposal_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    location = models.CharField(max_length=200, blank=True)
    condition = models.CharField(max_length=100, blank=True)
    purchase_transaction = models.ForeignKey('EnhancedTransaction', on_delete=models.SET_NULL, null=True, blank=True, related_name='purchased_assets')
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'asset_type']),
            models.Index(fields=['purchase_date']),
            models.Index(fields=['is_active']),
        ]
        ordering = ['-purchase_date']
    def __str__(self):
        return f"{self.name} ({self.asset_type})"

# =============================================================================
# RECURRING TRANSACTIONS AND AUTOMATION
# =============================================================================

class RecurringTransactionTemplate(models.Model):
    class Frequency(models.TextChoices):
        DAILY = 'DAILY', 'Daily'
        WEEKLY = 'WEEKLY', 'Weekly'
        BIWEEKLY = 'BIWEEKLY', 'Bi-weekly'
        MONTHLY = 'MONTHLY', 'Monthly'
        QUARTERLY = 'QUARTERLY', 'Quarterly'
        SEMI_ANNUALLY = 'SEMI_ANNUALLY', 'Semi-annually'
        ANNUALLY = 'ANNUALLY', 'Annually'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='recurring_templates')
    name = models.CharField(max_length=200)
    description = models.CharField(max_length=255)
    category = models.ForeignKey('Category', on_delete=models.SET_NULL, null=True, related_name='recurring_templates')
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    type = models.CharField(max_length=3, choices=EnhancedTransaction.TransactionType.choices)
    payment_method = models.CharField(max_length=6, choices=EnhancedTransaction.PaymentMethod.choices, default=EnhancedTransaction.PaymentMethod.BANK_TRANSFER)
    frequency = models.CharField(
        max_length=15,  # Increase from current value to 15
        choices=Frequency.choices,
        default=Frequency.MONTHLY,
        help_text="How often this transaction recurs"
    )
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    next_due_date = models.DateField()
    auto_generate = models.BooleanField(default=False)
    reminder_days_before = models.PositiveIntegerField(default=3)
    is_active = models.BooleanField(default=True)
    total_generated = models.PositiveIntegerField(default=0)    
    last_generated_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)    
    class Meta:
        app_label = 'fedha'
        indexes = [
            models.Index(fields=['profile', 'is_active']),
            models.Index(fields=['next_due_date']),
            models.Index(fields=['auto_generate']),
        ]
        ordering = ['next_due_date']

    def __str__(self):
        # Get human-readable frequency display
        frequency_mapping = {
            'DAILY': 'Daily',
            'WEEKLY': 'Weekly',
            'BIWEEKLY': 'Bi-weekly',
            'MONTHLY': 'Monthly',
            'QUARTERLY': 'Quarterly',
            'SEMI_ANNUALLY': 'Semi-annually',
            'ANNUALLY': 'Annually'
        }
        frequency_display = frequency_mapping.get(self.frequency, self.frequency)
        return f"{self.name} ({frequency_display})"

# =============================================================================
# BUDGET PLANNING AND VARIANCE ANALYSIS
# =============================================================================

class Budget(models.Model):
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
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='budgets')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    period_type = models.CharField(max_length=10, choices=BudgetPeriod.choices)
    start_date = models.DateField()
    end_date = models.DateField()
    total_income_budget = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'))
    total_expense_budget = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0'))
    status = models.CharField(max_length=10, choices=BudgetStatus.choices, default=BudgetStatus.DRAFT)
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

class BudgetLineItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    budget = models.ForeignKey(Budget, on_delete=models.CASCADE, related_name='line_items')
    category = models.ForeignKey('Category', on_delete=models.CASCADE, related_name='budget_line_items')
    budgeted_amount = models.DecimalField(max_digits=15, decimal_places=2, validators=[MinValueValidator(0)])
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        unique_together = ['budget', 'category']
        ordering = ['category__name']
    def __str__(self):
        return f"{self.category.name}: {self.budgeted_amount}"

# =============================================================================
# FINANCIAL ANALYTICS AND REPORTING
# =============================================================================

class FinancialRatio(models.Model):
    class RatioType(models.TextChoices):
        LIQUIDITY = 'LIQUIDITY', 'Liquidity Ratio'
        PROFITABILITY = 'PROFIT', 'Profitability Ratio'
        EFFICIENCY = 'EFFICIENCY', 'Efficiency Ratio'
        LEVERAGE = 'LEVERAGE', 'Leverage Ratio'
        MARKET = 'MARKET', 'Market Ratio'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='financial_ratios')
    ratio_name = models.CharField(max_length=100)
    ratio_type = models.CharField(max_length=10, choices=RatioType.choices)
    ratio_value = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
    calculation_date = models.DateField()
    period_start = models.DateField()
    period_end = models.DateField()
    industry_average = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
    target_value = models.DecimalField(max_digits=10, decimal_places=4, null=True, blank=True)
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

# =============================================================================
# AUDIT TRAIL AND DATA INTEGRITY
# =============================================================================

class AuditLog(models.Model):
    class ActionType(models.TextChoices):
        CREATE = 'CREATE', 'Create'
        UPDATE = 'UPDATE', 'Update'
        DELETE = 'DELETE', 'Delete'
        VIEW = 'VIEW', 'View'
        EXPORT = 'EXPORT', 'Export'
        IMPORT = 'IMPORT', 'Import'
        SYNC = 'SYNC', 'Synchronization'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='audit_logs')
    action_type = models.CharField(max_length=6, choices=ActionType.choices)
    table_name = models.CharField(max_length=100)
    record_id = models.CharField(max_length=100)
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.CharField(max_length=100)
    content_object = GenericForeignKey('content_type', 'object_id')
    field_changes = models.JSONField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    session_id = models.CharField(max_length=100, blank=True)
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
        # Get human-readable action type display
        action_type_mapping = {
            'CREATE': 'Create',
            'UPDATE': 'Update',
            'DELETE': 'Delete',
            'VIEW': 'View',
            'EXPORT': 'Export',
            'IMPORT': 'Import',
            'SYNC': 'Synchronization'
        }
        action_type_display = action_type_mapping.get(self.action_type, self.action_type)
        return f"{action_type_display} on {self.table_name} at {self.timestamp}"

# =============================================================================
# SYSTEM CONFIGURATION AND SETTINGS
# =============================================================================

class SystemSetting(models.Model):
    class SettingType(models.TextChoices):
        SYSTEM = 'SYSTEM', 'System Setting'
        PROFILE = 'PROFILE', 'Profile Setting'
        TAX = 'TAX', 'Tax Setting'
        NOTIFICATION = 'NOTIFICATION', 'Notification Setting'
        CALCULATION = 'CALCULATION', 'Calculation Setting'
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='settings', null=True, blank=True)
    setting_type = models.CharField(max_length=12, choices=SettingType.choices)
    key = models.CharField(max_length=100)
    value = models.TextField()
    data_type = models.CharField(max_length=20, choices=[('string', 'String'),('integer', 'Integer'),('decimal', 'Decimal'),('boolean', 'Boolean'),('json', 'JSON'),('date', 'Date')], default='string')
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

# backend/api/serializers.py
"""
Fedha Budget Tracker - API Serializers

This module defines serializers for the Fedha Budget Tracker API,
focusing on authentication flow and user management.

Key Features:
- Profile registration and login serialization
- PIN-based authentication validation
- Enhanced UUID handling with B/P prefixes
- Email credential delivery support
- Password reset functionality
- Field-level encryption for PII via EncryptedWriteMixin

Author: Fedha Development Team
Last Updated: November 15, 2025
"""

from rest_framework import serializers
from django.contrib.auth import authenticate
from django.core.mail import send_mail
from django.conf import settings
import secrets
import string
from .models import Profile, Client, EnhancedTransaction, Loan, LoanPayment


# =============================================================================
# ENCRYPTED WRITE MIXIN (EARLY DEFINITION FOR REUSE)
# =============================================================================

class EncryptedWriteMixin:
    """
    Mixin for serializers to capture plain inputs and encrypt them on save.
    Usage: add to serializer class, define ENCRYPTED_FIELDS = ['email', 'phone']
    """

    ENCRYPTED_FIELDS = []

    def create(self, validated_data):
        # Pop encrypted fields from validated_data, encrypt and set on instance
        encrypted_inputs = {}
        for fld in self.ENCRYPTED_FIELDS:
            if fld in validated_data:
                encrypted_inputs[fld] = validated_data.pop(fld)
        instance = super().create(validated_data)
        for fld, val in encrypted_inputs.items():
            instance.encrypt_and_set(fld, val)
        instance.save()
        return instance

    def update(self, instance, validated_data):
        encrypted_inputs = {}
        for fld in self.ENCRYPTED_FIELDS:
            if fld in validated_data:
                encrypted_inputs[fld] = validated_data.pop(fld)
        instance = super().update(instance, validated_data)
        for fld, val in encrypted_inputs.items():
            instance.encrypt_and_set(fld, val)
        instance.save()
        return instance


# =============================================================================
# PROFILE SERIALIZERS
# =============================================================================

class ProfileRegistrationSerializer(serializers.ModelSerializer):
    """
    Serializer for user registration with account type selection.
    Handles initial profile creation with temporary PIN.
    """
    
    email = serializers.EmailField(required=False)
    
    class Meta:
        model = Profile
        fields = ['name', 'profile_type', 'base_currency', 'timezone', 'email']
        
    def create(self, validated_data):
        """
        Create new profile with auto-generated UUID and temporary PIN.
        """
        # Generate temporary PIN for first-time login
        temp_pin = self.generate_temporary_pin()
        
        # Remove email from validated_data since it's not a model field
        email = validated_data.pop('email', None)
        
        # Create profile instance
        profile = Profile(
            name=validated_data.get('name', ''),
            profile_type=validated_data['profile_type'],
            base_currency=validated_data.get('base_currency', 'USD'),
            timezone=validated_data.get('timezone', 'UTC'),
            pin_hash=Profile.hash_pin(temp_pin)
        )
        
        # Save will automatically generate UUID with appropriate prefix
        profile.save()
        
        # Send credentials via email if email is provided
        if email:
            self.send_credentials_email(profile, temp_pin, email)
            
        return profile
    
    def generate_temporary_pin(self):
        """Generate a secure temporary PIN"""
        return ''.join(secrets.choice(string.digits) for _ in range(6))
    
    def send_credentials_email(self, profile, temp_pin, email):
        """Send login credentials via email"""
        subject = "Your Fedha Account Credentials"
        message = f"""
        Welcome to Fedha Budget Tracker!
        
        Your account has been created successfully.
        
        Profile ID: {profile.id}
        Temporary PIN: {temp_pin}
        
        Please log in using these credentials and change your PIN on first login.
        
        Thank you for choosing Fedha!
        """
        
        try:
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [email],
                fail_silently=False,
            )
        except Exception as e:
            # Log error but don't fail registration
            print(f"Failed to send email: {e}")


class ProfileLoginSerializer(serializers.Serializer):
    """
    Serializer for PIN-based authentication.
    Validates profile ID and PIN combination.
    """
    
    profile_id = serializers.CharField(max_length=9)  # Updated for new UUID format
    pin = serializers.CharField(max_length=20, min_length=3)  # More flexible PIN
    
    def validate(self, attrs):
        profile_id = attrs.get('profile_id')
        pin = attrs.get('pin')
        
        if profile_id and pin:
            try:
                profile = Profile.objects.get(id=profile_id, is_active=True)
                
                if not profile.verify_pin(pin):
                    raise serializers.ValidationError('Invalid PIN.')
                
                attrs['profile'] = profile
                return attrs
                
            except Profile.DoesNotExist:
                raise serializers.ValidationError('Invalid profile ID.')
        else:
            raise serializers.ValidationError('Must include profile ID and PIN.')


class ProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for profile information display and updates.
    """
    name = serializers.SerializerMethodField()
    
    class Meta:
        model = Profile
        fields = [
            'id', 'name', 'profile_type', 'base_currency', 
            'timezone', 'created_at', 'last_login', 'is_active'
        ]
        read_only_fields = ['id', 'created_at', 'last_login']

    def get_name(self, obj):
        try:
            return obj.decrypt_field('name')
        except Exception:
            return getattr(obj, 'name', None)


class ProfileWriteSerializer(EncryptedWriteMixin, ProfileSerializer):
    """Serializer for Profile create/update that automatically encrypts PII fields."""
    ENCRYPTED_FIELDS = ["email", "name"]
    
    class Meta(ProfileSerializer.Meta):
        pass


class PINChangeSerializer(serializers.Serializer):
    """
    Serializer for PIN change functionality.
    Used for first-time password reset and regular PIN updates.
    """
    
    current_pin = serializers.CharField(max_length=20, min_length=3)
    new_pin = serializers.CharField(max_length=20, min_length=3)
    confirm_pin = serializers.CharField(max_length=20, min_length=3)
    
    def validate(self, attrs):
        new_pin = attrs.get('new_pin')
        confirm_pin = attrs.get('confirm_pin')
        
        if new_pin != confirm_pin:
            raise serializers.ValidationError('New PIN and confirmation do not match.')
            
        # Additional PIN strength validation for numeric PINs
        if new_pin.isdigit() and len(set(new_pin)) == 1 and len(new_pin) >= 3:
            raise serializers.ValidationError('PIN cannot be all the same digit.')
            
        return attrs
    
    def validate_new_pin(self, value):
        """Validate new PIN strength"""
        # Check for weak numeric patterns
        if value.isdigit():
            weak_patterns = ['1234', '4321', '0123', '9876', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999', '0000']
            if value in weak_patterns:
                raise serializers.ValidationError('PIN cannot be a common weak pattern.')
        
        # Check for too simple alphanumeric patterns
        if value.lower() in ['123', 'abc', 'password', 'pin']:
            raise serializers.ValidationError('PIN cannot be a common word or simple pattern.')
            
        return value


# =============================================================================
# CLIENT SERIALIZERS
# =============================================================================

class ClientSerializer(serializers.ModelSerializer):
    """Serializer for Client data with decrypted PII fields."""
    email = serializers.SerializerMethodField()
    phone = serializers.SerializerMethodField()
    name = serializers.SerializerMethodField()

    class Meta:
        model = Client
        fields = [
            "id", "profile", "name", "email", "phone",
            "address_line1", "city", "credit_limit", "is_active", "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def get_email(self, obj):
        try:
            return obj.decrypt_field("email")
        except Exception:
            return getattr(obj, 'email', None)

    def get_phone(self, obj):
        try:
            return obj.decrypt_field("phone")
        except Exception:
            return getattr(obj, 'phone', None)

    def get_name(self, obj):
        try:
            return obj.decrypt_field("name")
        except Exception:
            return getattr(obj, 'name', None)


class ClientWriteSerializer(EncryptedWriteMixin, ClientSerializer):
    """Serializer for Client create/update that automatically encrypts PII fields."""
    ENCRYPTED_FIELDS = ["name", "email", "phone"]
    
    class Meta(ClientSerializer.Meta):
        pass


# =============================================================================
# TRANSACTION SERIALIZERS
# =============================================================================

class TransactionSerializer(serializers.ModelSerializer):
    """Serializer for transaction data with decrypted sensitive fields."""
    reference_number = serializers.SerializerMethodField()
    receipt_url = serializers.SerializerMethodField()
    
    class Meta:
        model = EnhancedTransaction
        fields = ['id', 'profile', 'type', 'amount', 'description', 'reference_number', 'receipt_url', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive")
        return value

    def get_reference_number(self, obj):
        try:
            return obj.decrypt_field('reference_number')
        except Exception:
            return getattr(obj, 'reference_number', None)

    def get_receipt_url(self, obj):
        try:
            return obj.decrypt_field('receipt_url')
        except Exception:
            return getattr(obj, 'receipt_url', None)


class TransactionWriteSerializer(EncryptedWriteMixin, TransactionSerializer):
    """Serializer for Transaction create/update that automatically encrypts sensitive fields."""
    ENCRYPTED_FIELDS = ["reference_number", "receipt_url"]
    
    class Meta(TransactionSerializer.Meta):
        pass


# =============================================================================
# EMAIL AND ACCOUNT SERIALIZERS
# =============================================================================

class EmailCredentialsSerializer(serializers.Serializer):
    """
    Serializer for requesting credentials via email.
    Used when user forgets their profile ID or PIN.
    """
    
    email = serializers.EmailField()
    profile_type = serializers.ChoiceField(choices=Profile.ProfileType.choices, required=False)


class AccountTypeSelectionSerializer(serializers.Serializer):
    """
    Serializer for initial account type selection.
    Used in the registration flow.
    """
    
    account_type = serializers.ChoiceField(choices=Profile.ProfileType.choices)
    user_name = serializers.CharField(max_length=100, required=False)
    email = serializers.EmailField(required=False)
    base_currency = serializers.CharField(max_length=3, default='USD')
    timezone = serializers.CharField(max_length=50, default='UTC')


# =============================================================================
# LOAN SERIALIZERS
# =============================================================================

class LoanSerializer(serializers.ModelSerializer):
    """Serializer for loan data with calculation support and decrypted sensitive fields."""
    remaining_payments = serializers.ReadOnlyField()
    monthly_interest_rate = serializers.ReadOnlyField()
    total_interest_paid = serializers.ReadOnlyField()
    loan_to_value_ratio = serializers.ReadOnlyField()
    
    lender = serializers.SerializerMethodField()
    account_number = serializers.SerializerMethodField()

    class Meta:
        model = Loan
        fields = [
            'id', 'profile', 'name', 'lender', 'loan_type', 'account_number',
            'principal_amount', 'annual_interest_rate', 'interest_type',
            'payment_frequency', 'number_of_payments', 'payment_amount',
            'origination_date', 'first_payment_date', 'maturity_date',
            'current_balance', 'total_paid', 'payments_made', 'status',
            'late_fee_amount', 'grace_period_days', 'collateral_value',
            'notes', 'created_at', 'updated_at', 'remaining_payments',
            'monthly_interest_rate', 'total_interest_paid', 'loan_to_value_ratio'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_lender(self, obj):
        try:
            return obj.decrypt_field('lender')
        except Exception:
            return getattr(obj, 'lender', None)

    def get_account_number(self, obj):
        try:
            return obj.decrypt_field('account_number')
        except Exception:
            return getattr(obj, 'account_number', None)


class LoanPaymentSerializer(serializers.ModelSerializer):
    """Serializer for loan payment data."""
    
    class Meta:
        model = LoanPayment
        fields = [
            'id', 'loan', 'payment_number', 'scheduled_date', 'actual_date',
            'scheduled_amount', 'actual_amount', 'principal_amount',
            'interest_amount', 'late_fee', 'balance_after_payment',
            'is_paid', 'is_late', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


# =============================================================================
# CALCULATOR SERIALIZERS
# =============================================================================

class LoanCalculationRequestSerializer(serializers.Serializer):
    """Serializer for loan calculation requests."""
    principal = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    annual_rate = serializers.DecimalField(max_digits=8, decimal_places=5, min_value=0, max_value=100)
    term_years = serializers.IntegerField(min_value=1, max_value=50)
    interest_type = serializers.ChoiceField(choices=Loan.InterestType.choices)
    payment_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)


class InterestRateSolverRequestSerializer(serializers.Serializer):
    """Serializer for interest rate solver requests using Newton-Raphson method."""
    principal = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    payment = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    term_years = serializers.IntegerField(min_value=1, max_value=50)
    payment_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)
    initial_guess = serializers.DecimalField(max_digits=8, decimal_places=5, default=5.0, required=False)
    tolerance = serializers.DecimalField(max_digits=10, decimal_places=8, default=0.00001, required=False)
    max_iterations = serializers.IntegerField(default=100, required=False)


class AmortizationScheduleRequestSerializer(serializers.Serializer):
    """Serializer for amortization schedule generation requests."""
    principal = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    annual_rate = serializers.DecimalField(max_digits=8, decimal_places=5, min_value=0, max_value=100)
    term_years = serializers.IntegerField(min_value=1, max_value=50)
    payment_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)


class EarlyPaymentRequestSerializer(serializers.Serializer):
    """Serializer for early payment calculation requests."""
    principal = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    annual_rate = serializers.DecimalField(max_digits=8, decimal_places=5, min_value=0, max_value=100)
    term_years = serializers.IntegerField(min_value=1, max_value=50)
    extra_payment = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0)
    payment_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)
    extra_payment_type = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)


class ROICalculationRequestSerializer(serializers.Serializer):
    """Serializer for ROI calculation requests."""
    initial_investment = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    final_value = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    time_years = serializers.DecimalField(max_digits=5, decimal_places=2, required=False, min_value=0.01)


class CompoundInterestRequestSerializer(serializers.Serializer):
    """Serializer for compound interest calculation requests."""
    principal = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=0.01)
    annual_rate = serializers.DecimalField(max_digits=8, decimal_places=5, min_value=0, max_value=100)
    time_years = serializers.DecimalField(max_digits=5, decimal_places=2, min_value=0.01)
    compounding_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices)
    additional_payment = serializers.DecimalField(max_digits=15, decimal_places=2, default=0, required=False)
    additional_frequency = serializers.ChoiceField(choices=Loan.PaymentFrequency.choices, required=False)


class PortfolioMetricsRequestSerializer(serializers.Serializer):
    """Serializer for portfolio metrics calculation requests."""
    investments = serializers.ListField(
        child=serializers.DictField(
            child=serializers.DecimalField(max_digits=15, decimal_places=8)
        ),
        min_length=1
    )


class RiskAssessmentRequestSerializer(serializers.Serializer):
    """Serializer for risk assessment questionnaire requests."""
    answers = serializers.ListField(
        child=serializers.IntegerField(min_value=1, max_value=5),
        min_length=1,
        max_length=20
    )

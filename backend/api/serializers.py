# backend/api/serializers.py
"""
Fedha Budget Tracker - API Serializers

This module defines serializers for the Fedha Budget Tracker API,
focusing on authentication flow and user management.

Author: Fedha Development Team
Last Updated: November 15, 2025
"""

from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.conf import settings

import secrets
import string
import re
from .models import Profile, Client, EnhancedTransaction, Loan, LoanPayment

# =============================================================================
# ENCRYPTED WRITE MIXIN (EARLY DEFINITION FOR REUSE)
# =============================================================================

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, 
        validators=[validate_password],
        min_length=8,
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(write_only=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password', 'password_confirm')
        extra_kwargs = {
            'email': {'required': True},
            'username': {'min_length': 3}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Password fields didn't match."})
        
        # Check for common passwords
        common_passwords = ['password', '12345678', 'qwerty', 'admin']
        if attrs['password'].lower() in common_passwords:
            raise serializers.ValidationError({"password": "Password is too common."})
            
        return attrs

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )
        return user

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
# VALIDATION HELPERS
# =============================================================================

def validate_password_strength(password):
    """Validate password strength"""
    if len(password) < 8:
        raise serializers.ValidationError("Password must be at least 8 characters long.")
    
    # Check for common patterns
    common_patterns = [
        r'12345678', r'password', r'qwerty', r'admin', r'welcome'
    ]
    for pattern in common_patterns:
        if pattern in password.lower():
            raise serializers.ValidationError("Password contains common patterns.")
    
    return password

# =============================================================================
# PROFILE SERIALIZERS
# =============================================================================

class ProfileRegistrationSerializer(serializers.ModelSerializer):
    """
    Secure serializer for user registration with password validation.
    """
    
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        validators=[validate_password_strength],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    
    class Meta:
        model = Profile
        fields = ['name', 'profile_type', 'base_currency', 'timezone', 'email', 'password', 'password_confirm']
        
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})
        return attrs

    def validate_email(self, value):
        if Profile.objects.filter(email=value).exists():
            raise serializers.ValidationError("A profile with this email already exists.")
        return value

    def create(self, validated_data):
        """
        Create new profile with secure password handling.
        """
        # Remove confirmation field
        validated_data.pop('password_confirm')
        raw_password = validated_data.pop('password')
        email = validated_data.pop('email')
        
        # Create profile instance
        profile = Profile.objects.create(
            name=validated_data.get('name', ''),
            profile_type=validated_data['profile_type'],
            base_currency=validated_data.get('base_currency', 'USD'),
            timezone=validated_data.get('timezone', 'UTC'),
            email=email
        )
        
        # Set hashed password
        profile.set_password(raw_password)
        profile.save()
        
        return profile

class ProfileLoginSerializer(serializers.Serializer):
    """
    Secure serializer for profile authentication.
    """
    
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            try:
                profile = Profile.objects.get(email=email, is_active=True)
                
                if not profile.check_password(password):
                    raise serializers.ValidationError('Invalid credentials.')
                
                attrs['profile'] = profile
                return attrs
                
            except Profile.DoesNotExist:
                raise serializers.ValidationError('Invalid credentials.')
        else:
            raise serializers.ValidationError('Must include email and password.')

class ProfileSerializer(serializers.ModelSerializer):
    """
    Serializer for profile information display and updates.
    """
    name = serializers.SerializerMethodField()
    email = serializers.SerializerMethodField()
    
    class Meta:
        model = Profile
        fields = [
            'id', 'name', 'email', 'profile_type', 'base_currency', 
            'timezone', 'created_at', 'last_login', 'is_active'
        ]
        read_only_fields = ['id', 'created_at', 'last_login']

    def get_name(self, obj):
        try:
            return obj.decrypt_field('name')
        except Exception:
            return getattr(obj, 'name', None)

    def get_email(self, obj):
        try:
            return obj.decrypt_field('email')
        except Exception:
            return getattr(obj, 'email', None)

class ProfileWriteSerializer(EncryptedWriteMixin, ProfileSerializer):
    """Serializer for Profile create/update that automatically encrypts PII fields."""
    ENCRYPTED_FIELDS = ["email", "name"]
    
    class Meta(ProfileSerializer.Meta):
        pass

# =============================================================================
# TRANSACTION CANDIDATE SERIALIZER
# =============================================================================

class TransactionCandidateSerializer(serializers.Serializer):
    """
    Serializer for transaction candidate creation.
    """
    sms_text = serializers.CharField(
        required=True,
        min_length=10,
        max_length=1000,
        help_text="SMS message text to parse"
    )
    profile_id = serializers.UUIDField(
        required=True,
        help_text="Profile ID associated with the transaction"
    )
    
    def validate_sms_text(self, value):
        """Basic SMS text validation"""
        if len(value.strip()) < 10:
            raise serializers.ValidationError("SMS text is too short.")
        return value.strip()

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

# Removed insecure serializers: PINChangeSerializer, EmailCredentialsSerializer, etc.
# These should be implemented using Django's built-in authentication system

# ... (rest of the serializers remain the same for loans, calculations, etc.)
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

Author: Fedha Development Team
Last Updated: May 26, 2025
"""

from rest_framework import serializers
from django.contrib.auth import authenticate
from django.core.mail import send_mail
from django.conf import settings
import secrets
import string
from .models import Profile, generate_profile_uuid, EnhancedTransaction


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
            
        # Store temp_pin for response
        profile.temp_pin = temp_pin
        return profile
    
    def generate_temporary_pin(self):
        """Generate a secure 6-digit temporary PIN"""
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
    
    class Meta:
        model = Profile
        fields = [
            'id', 'name', 'profile_type', 'base_currency', 
            'timezone', 'created_at', 'last_login', 'is_active'
        ]
        read_only_fields = ['id', 'created_at', 'last_login']


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


class TransactionSerializer(serializers.ModelSerializer):
    """
    Serializer for transaction data.
    """
    
    class Meta:
        model = EnhancedTransaction
        fields = ['id', 'profile', 'type', 'amount', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be positive")
        return value


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
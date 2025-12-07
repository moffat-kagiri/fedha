# backend/api/serializers.py
import hashlib
import json
from rest_framework import serializers
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from .models import Profile

class PasswordValidator:
    """Validates passwords using frontend-compatible SHA-256 hashing"""
    
    @staticmethod
    def hash_password(password: str) -> str:
        """Hash password using SHA-256 (frontend compatible)"""
        return hashlib.sha256(password.encode()).hexdigest()
    
    @staticmethod
    def verify_password(password: str, password_hash: str) -> bool:
        """Verify password against SHA-256 hash"""
        return PasswordValidator.hash_password(password) == password_hash
    
    @staticmethod
    def validate(password: str):
        """Validate password strength"""
        errors = []
        if len(password) < 8:
            errors.append("Password must be at least 8 characters long")
        if not any(c.isupper() for c in password):
            errors.append("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in password):
            errors.append("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in password):
            errors.append("Password must contain at least one digit")
        
        if errors:
            raise serializers.ValidationError(errors)


class ProfileSerializer(serializers.ModelSerializer):
    """Serialize Profile model with all fields needed by frontend"""
    
    class Meta:
        model = Profile
        fields = (
            'id', 'name', 'email', 'user_id', 'profile_type', 'base_currency',
            'timezone', 'created_at', 'last_modified', 'last_login', 'is_active'
        )
        read_only_fields = (
            'id', 'created_at', 'last_modified', 'last_login', 'user_id'
        )


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Register new user with SHA-256 password hashing"""
    password = serializers.CharField(write_only=True, required=True)
    password2 = serializers.CharField(write_only=True, required=True)
    email = serializers.EmailField(required=True)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)
    phone = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ('password', 'password2', 'email', 'first_name', 'last_name', 'phone')

    def validate(self, attrs):
        # Validate password strength
        PasswordValidator.validate(attrs['password'])
        
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({"email": "Email already registered."})
        
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        phone = validated_data.pop('phone', '')
        password = validated_data.pop('password')
        
        # Create user
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
        )
        
        # Create profile with SHA-256 password hash
        profile = Profile.objects.create(
            name=f"{validated_data['first_name']} {validated_data['last_name']}".strip(),
            email=validated_data['email'],
            profile_type=Profile.ProfileType.PERSONAL,
            base_currency='KES',  # Default for Kenya
            timezone='Africa/Nairobi',  # Default for Kenya
            password_hash=PasswordValidator.hash_password(password),
            phone=phone if phone else None,
        )
        
        return user


class UserLoginSerializer(serializers.Serializer):
    """Login with SHA-256 password verification"""
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError("Invalid email or password")
        
        try:
            # Find profile by email, not by user relationship
            profile = Profile.objects.get(email=email)
        except Profile.DoesNotExist:
            raise serializers.ValidationError("Profile not found for this account")
        
        # Verify password using SHA-256
        if not PasswordValidator.verify_password(password, profile.password_hash):
            raise serializers.ValidationError("Invalid email or password")
        
        if not user.is_active or not profile.is_active:
            raise serializers.ValidationError("Account is disabled")
        
        attrs['user'] = user
        attrs['profile'] = profile
        return attrs
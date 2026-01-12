# apps/accounts/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import User

class UserSerializer(serializers.ModelSerializer):
    """Serializer for User profile data"""
    name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'name', 'first_name', 'last_name',
            'phone', 'photo_url', 'base_currency', 'timezone',
            'last_modified', 'last_login', 'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'last_modified', 'last_login']
    
    def get_name(self, obj):
        return obj.get_full_name()

class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=False,
        style={'input_type': 'password'}
    )
    
    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'phone',
            'base_currency', 'timezone'
        ]
    
    def validate_email(self, value):
        """Ensure email is unique"""
        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()
    
    def validate(self, attrs):
        """Validate password confirmation if provided"""
        password = attrs.get('password')
        password_confirm = attrs.pop('password_confirm', None)
        
        if password_confirm and password != password_confirm:
            raise serializers.ValidationError({
                'password_confirm': 'Passwords do not match.'
            })
        
        return attrs
    
    def create(self, validated_data):
        """Create user with hashed password"""
        # Generate username from email
        email = validated_data['email']
        username = email.split('@')[0]
        
        # Ensure username is unique
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
        
        user = User.objects.create_user(
            username=username,
            email=email,
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone=validated_data.get('phone', ''),
            base_currency=validated_data.get('base_currency', 'KES'),
            timezone=validated_data.get('timezone', 'Africa/Nairobi'),
        )
        
        return user

class LoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    email = serializers.EmailField(required=True)
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )

class ProfileUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile"""
    
    class Meta:
        model = User
        fields = [
            'first_name', 'last_name', 'phone',
            'photo_url', 'base_currency', 'timezone'
        ]
    
    def update(self, instance, validated_data):
        """Update user profile fields"""
        for field, value in validated_data.items():
            setattr(instance, field, value)
        instance.save()
        return instance


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password"""
    old_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    new_password_confirm = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'}
    )
    
    def validate(self, attrs):
        """Validate passwords match"""
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({
                'new_password_confirm': 'New passwords do not match.'
            })
        return attrs
    
    def validate_old_password(self, value):
        """Validate old password is correct"""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Old password is not correct.')
        return value
    
    def save(self):
        """Save new password"""
        user = self.context['request'].user
        user.set_password(self.validated_data['new_password'])
        user.save()
        return user

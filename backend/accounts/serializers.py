# backend/accounts/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import Profile


class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        validators=[validate_password]
    )
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)
    phone_number = serializers.CharField(required=False, allow_blank=True)
    
    class Meta:
        model = Profile
        fields = [
            'email', 
            'password', 
            'first_name', 
            'last_name', 
            'phone_number'
        ]
    
    def create(self, validated_data):
        """Create user with encrypted password"""
        user = Profile.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            phone_number=validated_data.get('phone_number', ''),
        )
        
        return user


class ProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile data"""
    
    class Meta:
        model = Profile
        fields = [
            'id',
            'email',
            'first_name',
            'last_name',
            'phone_number',
            #'base_currency',
            #'user_timezone',
            #'last_modified',
            'last_login',
            #'date_joined',
        ]
        read_only_fields = ['id', 'last_modified', 'last_login', 'date_joined']
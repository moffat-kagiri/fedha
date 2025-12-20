# accounts/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from .models import Profile, Category


class ProfileSerializer(serializers.ModelSerializer):
    """Serializer for Profile model."""
    
    class Meta:
        model = Profile
        fields = [
            'id', 'email', 'phone_number', 'name', 'display_name',
            'profile_type', 'base_currency', 'timezone', 'photo_url',
            'is_active', 'created_at', 'updated_at', 'last_login',
            'last_synced', 'preferences'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_login']


class RegisterSerializer(serializers.ModelSerializer):
    """Serializer for user registration."""
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )
    password_confirm = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = Profile
        fields = [
            'email', 'phone_number', 'password', 'password_confirm',
            'name', 'display_name', 'profile_type', 'base_currency', 'timezone'
        ]
    
    def validate(self, attrs):
        """Validate passwords match."""
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({
                "password": "Password fields didn't match."
            })
        return attrs
    
    def create(self, validated_data):
        """Create user with validated data."""
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        
        user = Profile.objects.create_user(
            password=password,
            **validated_data
        )
        
        # Create default categories for new user
        self._create_default_categories(user)
        
        return user
    
    def _create_default_categories(self, profile):
        """Create default categories for new user."""
        from .models import DefaultCategory
        
        default_categories = DefaultCategory.objects.all()
        for default_cat in default_categories:
            Category.objects.create(
                profile=profile,
                name=default_cat.name,
                description=default_cat.description,
                color=default_cat.color,
                icon=default_cat.icon,
                type=default_cat.type
            )


class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    email = serializers.EmailField(required=False)
    phone_number = serializers.CharField(required=False)
    password = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        """Validate that either email or phone is provided."""
        if not attrs.get('email') and not attrs.get('phone_number'):
            raise serializers.ValidationError(
                "Either email or phone number must be provided."
            )
        return attrs


class CategorySerializer(serializers.ModelSerializer):
    """Serializer for Category model."""
    
    class Meta:
        model = Category
        fields = [
            'id', 'profile', 'name', 'description', 'color', 'icon',
            'type', 'is_active', 'is_synced', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'profile', 'created_at', 'updated_at']

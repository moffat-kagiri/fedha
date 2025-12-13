# apps/accounts/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid as uuid_lib  # FIXED

class User(AbstractUser):
    """
    Custom user model that matches Flutter Profile model
    Maps to: lib/models/profile.dart
    """
    id = models.UUIDField(primary_key=True, default=uuid_lib.uuid4, editable=False)  # FIXED
    email = models.EmailField(unique=True, db_index=True)
    phone = models.CharField(max_length=20, blank=True)
    
    # Profile fields to match Flutter
    photo_url = models.CharField(max_length=500, blank=True)
    base_currency = models.CharField(max_length=3, default='KES')
    timezone = models.CharField(max_length=50, default='Africa/Nairobi')
    
    # Timestamps
    last_modified = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True, blank=True)
    
    # Use email for login instead of username
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name']
    
    class Meta:
        db_table = 'users'
        ordering = ['-date_joined']
    
    def __str__(self):
        return self.email
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()
    
    @property
    def profile_data(self):
        """Return profile data matching Flutter Profile model"""
        return {
            'id': str(self.id),
            'name': self.get_full_name(),
            'email': self.email,
            'phone_number': self.phone,
            'photo_url': self.photo_url,
            'base_currency': self.base_currency,
            'timezone': self.timezone,
            'last_modified': self.last_modified.isoformat() if self.last_modified else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'created_at': self.date_joined.isoformat(),
        }
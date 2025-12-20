# accounts/models.py
import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class ProfileType(models.TextChoices):
    PERSONAL = 'personal', 'Personal'
    BUSINESS = 'business', 'Business'
    FAMILY = 'family', 'Family'
    STUDENT = 'student', 'Student'


class ProfileManager(BaseUserManager):
    """Custom manager for Profile model."""
    
    def create_user(self, email=None, phone_number=None, password=None, **extra_fields):
        """Create and return a regular user."""
        if not email and not phone_number:
            raise ValueError('Either email or phone number must be provided')
        
        if email:
            email = self.normalize_email(email)
        
        user = self.model(email=email, phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        """Create and return a superuser."""
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        
        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')
        
        return self.create_user(email=email, password=password, **extra_fields)


class Profile(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model that matches the PostgreSQL schema and Flutter app requirements.
    Supports authentication via email or phone number.
    
    IMPORTANT: Django's AbstractBaseUser expects a 'password' field, but our
    PostgreSQL schema uses 'password_hash'. We use db_column to map Django's
    'password' field to the database's 'password_hash' column.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(max_length=255, unique=True, null=True, blank=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    
    # Map Django's password field to database's password_hash column
    password = models.CharField(max_length=255, db_column='password_hash')
    
    name = models.CharField(max_length=255)
    display_name = models.CharField(max_length=255, null=True, blank=True)
    profile_type = models.CharField(
        max_length=20,
        choices=ProfileType.choices,
        default=ProfileType.PERSONAL
    )
    
    base_currency = models.CharField(max_length=3, default='KES')
    user_timezone = models.CharField(max_length=50, default='Africa/Nairobi')
    photo_url = models.TextField(null=True, blank=True)
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    last_login = models.DateTimeField(null=True, blank=True)
    last_synced = models.DateTimeField(null=True, blank=True)
    
    preferences = models.JSONField(default=dict, blank=True)
    
    objects = ProfileManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']
    
    class Meta:
        db_table = 'profiles'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['phone_number']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return self.email or self.phone_number or str(self.id)
    
    def get_full_name(self):
        """Return the display name or name."""
        return self.display_name or self.name
    
    def get_short_name(self):
        """Return the name."""
        return self.name


class Session(models.Model):
    """
    User session model for tracking active sessions and tokens.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='sessions'
    )
    
    session_token = models.CharField(max_length=255, unique=True)
    auth_token = models.CharField(max_length=255, unique=True, null=True, blank=True)
    device_id = models.CharField(max_length=255, null=True, blank=True)
    
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(default=timezone.now)
    last_activity = models.DateTimeField(default=timezone.now)
    
    class Meta:
        db_table = 'sessions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['session_token']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        return f"Session for {self.profile} - {self.created_at}"
    
    def is_valid(self):
        """Check if session is still valid."""
        return self.expires_at > timezone.now()
    
    def update_activity(self):
        """Update last activity timestamp."""
        self.last_activity = timezone.now()
        self.save(update_fields=['last_activity'])


class Category(models.Model):
    """
    Transaction category model.
    Can be profile-specific or global (when profile is None).
    """
    TYPE_CHOICES = [
        ('income', 'Income'),
        ('expense', 'Expense'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE,
        related_name='categories',
        null=True,
        blank=True
    )
    
    name = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    color = models.CharField(max_length=7, default='#2196F3')
    icon = models.CharField(max_length=50, default='category')
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='expense')
    
    is_active = models.BooleanField(default=True)
    is_synced = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'categories'
        ordering = ['name']
        verbose_name_plural = 'Categories'
        indexes = [
            models.Index(fields=['profile']),
            models.Index(fields=['type']),
            models.Index(fields=['is_active']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['profile', 'name'],
                name='unique_profile_category_name'
            )
        ]
    
    def __str__(self):
        return f"{self.name} ({self.type})"


class DefaultCategory(models.Model):
    """
    Template categories that are copied for new users.
    """
    name = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    color = models.CharField(max_length=7)
    icon = models.CharField(max_length=50)
    type = models.CharField(max_length=20)
    
    class Meta:
        db_table = 'default_categories'
    
    def __str__(self):
        return f"{self.name} ({self.type})"
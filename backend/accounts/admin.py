# accounts/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Profile, Session


@admin.register(Profile)
class ProfileAdmin(UserAdmin):
    """Admin interface for Profile model."""
    list_display = ['email', 'first_name', 'last_name', 'profile_type', 'is_active', 'created_at']
    list_filter = ['profile_type', 'is_active', 'created_at']
    search_fields = ['email', 'phone_number', 'first_name', 'last_name']
    ordering = ['-created_at']
    
    fieldsets = (
        (None, {'fields': ('email', 'phone_number', 'password')}),
        ('Personal Info', {'fields': ('first_name', 'last_name', 'display_name', 'photo_url')}),
        ('Profile Settings', {'fields': ('profile_type', 'base_currency', 'user_timezone')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser')}),
        ('Important Dates', {'fields': ('last_login', 'created_at', 'updated_at')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'phone_number', 'first_name', 'last_name', 'password1', 'password2'),
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    """Admin interface for Session model."""
    list_display = ['profile', 'created_at', 'expires_at', 'last_activity']
    list_filter = ['created_at', 'expires_at']
    search_fields = ['profile__email', 'session_token']
    readonly_fields = ['created_at']
    
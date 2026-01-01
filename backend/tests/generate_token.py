#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fedha_backend.settings')
django.setup()

from accounts.models import Profile
from rest_framework_simplejwt.tokens import AccessToken

# Create or get a test user
user, created = Profile.objects.get_or_create(
    email='apitest@example.com',
    defaults={
        'first_name': 'API',
        'last_name': 'Test',
    }
)

if created:
    user.set_password('TestPassword123!')
    user.save()
    print("Created new test user")
else:
    print("Using existing test user")

# Generate a valid JWT token
access_token = AccessToken.for_user(user)

print(f"\nTest user ID: {user.id}")
print(f"Test user email: {user.email}")
print(f"\nAccess Token: {str(access_token)}")

# Test the health endpoint
print("\n\nTo test, run:")
print(f'Invoke-WebRequest -Uri "http://localhost:8000/api/health/" -Headers @{{"Authorization" = "Bearer {str(access_token)}"}} | ConvertFrom-Json | ConvertTo-Json')

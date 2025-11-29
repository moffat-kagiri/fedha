"""
Fedha Budget Tracker - URL Configuration

This module defines URL patterns for the Fedha Django project.
It includes routes for the API, admin interface, and health check endpoints.

Author: Fedha Development Team
Last Updated: August 5, 2025
"""

from django.contrib import admin
from django.urls import path, include

# Health check endpoint - simple endpoint for testing connectivity
from django.http import JsonResponse
from django.utils import timezone

def health_check(request):
    """Simple health check endpoint for testing connectivity."""
    return JsonResponse({
        'status': 'healthy',
        'timestamp': timezone.now().isoformat(),
        'message': 'Fedha API is operational',
        'environment': 'development'
    })

# URL patterns for the Fedha project
urlpatterns = [
    path('admin/', admin.site.urls),
    # Health check endpoint - important for testing connectivity
    path('api/health/', health_check, name='health_check'),

    # Include API routes from the api app
    path('api/', include('api.urls')), 
    path('v1/api/', include('api.urls')), 
]
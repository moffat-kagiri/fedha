# api/urls.py
"""
Fedha Budget Tracker - API URL Configuration

Simplified URL configuration focusing on core endpoints:
- Health check
- Profile authentication (registration, login)
- SMS transaction parsing
- Enhanced profile management (8-digit user IDs, cross-device sync)

Author: Fedha Development Team  
Last Updated: November 15, 2025
"""

from django.urls import path, include
from . import views
from . import enhanced_views

urlpatterns = [
    # Health check endpoint
    path('health/', views.HealthCheckView.as_view(), name='health'),
    
    # Authentication endpoints - Basic
    path('auth/register/', views.ProfileRegistrationView.as_view(), name='auth-register'),
    path('auth/login/', views.ProfileLoginView.as_view(), name='auth-login'),
    
    # Enhanced profile endpoints - 8-digit user IDs, cross-device
    path('enhanced/register/', enhanced_views.EnhancedProfileRegistrationView.as_view(), name='enhanced-register'),
    path('enhanced/login/', enhanced_views.EnhancedProfileLoginView.as_view(), name='enhanced-login'),
    path('enhanced/sync/', enhanced_views.EnhancedProfileSyncView.as_view(), name='enhanced-sync'),
    
    # SMS transaction parsing endpoint
    path('sms-parse/', views.TransactionCandidateView.as_view(), name='sms-parse'),
]
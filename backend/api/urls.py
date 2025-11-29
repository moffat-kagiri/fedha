# api/urls.py
"""
Fedha Budget Tracker - API URL Configuration
Aligned with Flutter ApiConfig versioning and endpoints.
"""

from django.urls import path, include
from django.conf import settings
from . import views
from . import enhanced_views
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
urlpatterns = [
    # Health check (aligned with Flutter ApiConfig.apiHealthEndpoint)
    path('health/', views.HealthCheckView.as_view(), name='health'),
    
    # Authentication endpoints
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),
    
    # Secure profile endpoints
    path('profiles/register/', views.SecureProfileRegistrationView.as_view(), name='secure-register'),
    path('profiles/login/', views.SecureProfileLoginView.as_view(), name='secure-login'),
    
    # Enhanced profile endpoints
    path('enhanced/register/', enhanced_views.EnhancedProfileRegistrationView.as_view(), name='enhanced-register'),
    path('enhanced/login/', enhanced_views.EnhancedProfileLoginView.as_view(), name='enhanced-login'),
    path('enhanced/sync/', enhanced_views.EnhancedProfileSyncView.as_view(), name='enhanced-sync'),
    
    # SMS transaction parsing endpoint
    path('transactions/parse-sms/', views.TransactionCandidateView.as_view(), name='parse-sms'),
]

# Versioned API URLs (aligned with Flutter ApiConfig.apiVersion)
api_patterns = [
    path(f'{settings.API_VERSION}/', include(urlpatterns)),
]

# Include both versioned and non-versioned URLs for compatibility
urlpatterns += api_patterns
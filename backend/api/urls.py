# api/urls.py
"""
Fedha Budget Tracker - API URL Configuration

This module defines URL patterns for the Fedha Budget Tracker API,
including complete authentication flow endpoints.

Authentication Flow:
1. GET /auth/account-types/ - Get available account types
2. POST /auth/account-types/ - Select account type and create profile
3. POST /auth/login/ - Login with profile ID and PIN
4. POST /auth/change-pin/ - Change PIN (first-time or regular)
5. GET /auth/dashboard/ - Get dashboard data
6. POST /auth/email-credentials/ - Request credentials via email
7. GET /auth/status/ - Check authentication status

Author: Fedha Development Team  
Last Updated: May 26, 2025
"""

from django.urls import path
from . import views

# Authentication endpoints
auth_patterns = [
    path('account-types/', views.AccountTypeSelectionView.as_view(), name='account-types'),
    path('register/', views.ProfileRegistrationView.as_view(), name='register'),
    path('login/', views.ProfileLoginView.as_view(), name='login'),
    path('change-pin/', views.PINChangeView.as_view(), name='change-pin'),
    path('email-credentials/', views.EmailCredentialsView.as_view(), name='email-credentials'),
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
    path('status/', views.auth_status, name='auth-status'),
]

# Profile management endpoints
profile_patterns = [
    path('profiles/', views.ProfileListCreateView.as_view(), name='profile-list'),
    path('profiles/<str:pk>/', views.ProfileDetailView.as_view(), name='profile-detail'),
]

urlpatterns = [
    # Authentication routes
    *[path(f'auth/{pattern.pattern}', pattern.callback, kwargs=pattern.kwargs, name=f'auth-{pattern.name}') 
      for pattern in auth_patterns],
    
    # Profile management routes  
    *profile_patterns,
    
    # Health check endpoint
    path('health/', lambda request: JsonResponse({'status': 'healthy'}), name='health-check'),
]

# Import JsonResponse for health check
from django.http import JsonResponse
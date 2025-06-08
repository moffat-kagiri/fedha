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
from django.http import JsonResponse
from . import views

# Authentication endpoints
auth_patterns = [
    path('account-types/', views.AccountTypeSelectionView.as_view(), name='account-types'),
    path('register/', views.ProfileRegistrationView.as_view(), name='register'),
    path('login/', views.ProfileLoginView.as_view(), name='login'),
    path('change-pin/', views.PINChangeView.as_view(), name='change-pin'),
    path('email-credentials/', views.EmailCredentialsView.as_view(), name='email-credentials'),
    path('dashboard/', views.DashboardView.as_view(), name='dashboard'),
]

# Profile management endpoints
profile_patterns = [
    path('profiles/', views.ProfileListCreateView.as_view(), name='profile-list'),
    path('profiles/<str:pk>/', views.ProfileDetailView.as_view(), name='profile-detail'),
]

# Enhanced profile endpoints for 8-digit user IDs and cross-device sync
enhanced_profile_patterns = [
    path('enhanced/register/', views.EnhancedProfileRegistrationView.as_view(), name='enhanced-register'),
    path('enhanced/login/', views.EnhancedProfileLoginView.as_view(), name='enhanced-login'),
    # path('enhanced/sync/', views.EnhancedProfileSyncView.as_view(), name='enhanced-sync'),  # Commented out until view is implemented
    # path('enhanced/validate/', views.enhanced_profile_validate, name='enhanced-validate'),  # Commented out until view is implemented
]

# Financial calculator endpoints
calculator_patterns = [
    path('calculators/loan/', views.LoanCalculatorView.as_view(), name='loan-calculator'),
    path('calculators/interest-rate-solver/', views.InterestRateSolverView.as_view(), name='interest-rate-solver'),
    path('calculators/amortization-schedule/', views.AmortizationScheduleView.as_view(), name='amortization-schedule'),
    path('calculators/early-payment/', views.EarlyPaymentCalculatorView.as_view(), name='early-payment-calculator'),
    path('calculators/roi/', views.ROICalculatorView.as_view(), name='roi-calculator'),
    path('calculators/compound-interest/', views.CompoundInterestCalculatorView.as_view(), name='compound-interest-calculator'),
    path('calculators/portfolio-metrics/', views.PortfolioMetricsView.as_view(), name='portfolio-metrics'),
    path('calculators/risk-assessment/', views.RiskAssessmentView.as_view(), name='risk-assessment'),
]

urlpatterns = [
    # Authentication routes
    path('auth/account-types/', views.AccountTypeSelectionView.as_view(), name='auth-account-types'),
    path('auth/register/', views.ProfileRegistrationView.as_view(), name='auth-register'),
    path('auth/login/', views.ProfileLoginView.as_view(), name='auth-login'),
    path('auth/change-pin/', views.PINChangeView.as_view(), name='auth-change-pin'),
    path('auth/email-credentials/', views.EmailCredentialsView.as_view(), name='auth-email-credentials'),
    path('auth/dashboard/', views.DashboardView.as_view(), name='auth-dashboard'),
    
    # Profile management routes  
    *profile_patterns,
    
    # Enhanced profile routes for cross-device support
    *enhanced_profile_patterns,
    
    # Financial calculator routes
    *calculator_patterns,
    
    # Health check endpoint
    path('health/', lambda request: JsonResponse({'status': 'healthy'}), name='health-check'),
]
# Import JsonResponse for health check
from django.http import JsonResponse
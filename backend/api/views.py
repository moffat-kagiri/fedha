# backend/api/views.py
"""
Fedha Budget Tracker - API Views (Optimized)

This module defines API views for the Fedha Budget Tracker,
with optimized control flow using dictionary mappings and other patterns
to replace repetitive if-else statements.

Key Improvements:
- Dictionary-based mappings for profile types and currencies
- Centralized configuration constants
- Reduced if-else chains with lookup tables
- Better error handling patterns

Author: Fedha Development Team
Last Updated: June 8, 2025
"""

from django.shortcuts import render
from django.utils import timezone
from django.http import JsonResponse
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.core.mail import send_mail
from django.conf import settings
from typing import Dict, Any, Optional

from .models import Profile
from .serializers import (
    ProfileSerializer, 
    ProfileRegistrationSerializer, 
    ProfileLoginSerializer,
    PINChangeSerializer,
    EmailCredentialsSerializer,
    AccountTypeSelectionSerializer
)

# =============================================================================
# CONFIGURATION CONSTANTS AND MAPPINGS
# =============================================================================

# Profile type mappings
PROFILE_TYPE_MAPPINGS = {
    'business': {
        'code': 'BIZ',
        'label': 'Business',
        'description': 'For business owners, freelancers, and SMEs. Includes invoicing, client management, and tax preparation.',
        'dashboard_url': '/dashboard/business',
        'features': [
            'Invoice generation and management',
            'Client relationship management', 
            'Tax preparation and compliance',
            'Cash flow analysis',
            'Business expense tracking',
            'Loan and asset management'
        ]
    },
    'personal': {
        'code': 'PERS',
        'label': 'Personal',
        'description': 'For personal finance management and budgeting. Focus on savings, goals, and expense tracking.',
        'dashboard_url': '/dashboard/personal',
        'features': [
            'Personal budget tracking',
            'Goal setting and monitoring',
            'Expense categorization',
            'Savings tracking',
            'Personal loan management',
            'Investment tracking'
        ]
    }
}

# Reverse mapping for database codes to display types
DB_CODE_TO_TYPE = {
    'BIZ': 'business',
    'PERS': 'personal'
}

# Currency and timezone defaults
DEFAULT_SETTINGS = {
    'currency': 'USD',
    'timezone': 'UTC',
    'currencies': ['USD', 'KES', 'EUR', 'GBP', 'JPY']
}

# Response message templates
RESPONSE_MESSAGES = {
    'registration_success': 'Account created successfully',
    'registration_with_email': 'Account created successfully. Credentials sent to your email.',
    'registration_without_email': 'Account created successfully. Please save your credentials.',
    'login_success': 'Login successful',
    'pin_change_success': 'PIN changed successfully',
    'sync_success': 'Profile synchronized successfully',
    'email_sent': 'If an account exists with this email, credentials have been sent.',
    'email_failed': 'Failed to send email. Please try again later.'
}

# Error message templates
ERROR_MESSAGES = {
    'auth_failed': 'Authentication failed',
    'profile_not_found': 'Profile not found',
    'invalid_pin': 'Invalid PIN',
    'invalid_profile_type': 'Profile type must be "business" or "personal"',
    'required_fields': 'Name, profile type, and PIN are required',
    'user_id_required': 'User ID is required',
    'email_required': 'Email is required',
    'current_pin_required': 'Current PIN is required',
    'new_pin_required': 'New PIN is required',
    'incorrect_current_pin': 'Current PIN is incorrect',
    'profile_id_required': 'Profile ID required'
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_validated_data(serializer) -> Dict[str, Any]:
    """
    Safely extract validated data from serializer.
    Returns empty dict if serializer is invalid.
    """
    if hasattr(serializer, 'validated_data') and serializer.validated_data:
        return serializer.validated_data
    return {}

def get_profile_type_info(profile_type: str) -> Dict[str, Any]:
    """Get profile type information using dictionary lookup"""
    return PROFILE_TYPE_MAPPINGS.get(profile_type, PROFILE_TYPE_MAPPINGS['personal'])

def get_dashboard_url(profile_type_code: str) -> str:
    """Get dashboard URL based on profile type code"""
    display_type = DB_CODE_TO_TYPE.get(profile_type_code, 'personal')
    return PROFILE_TYPE_MAPPINGS[display_type]['dashboard_url']

def get_profile_features(profile_type_code: str) -> list:
    """Get available features based on profile type"""
    display_type = DB_CODE_TO_TYPE.get(profile_type_code, 'personal')
    return PROFILE_TYPE_MAPPINGS[display_type]['features']

def format_profile_response(profile: Profile) -> Dict[str, Any]:
    """Format profile data for API responses"""
    display_type = DB_CODE_TO_TYPE.get(profile.profile_type, 'personal')
    return {
        'user_id': getattr(profile, 'user_id', None),
        'profile_id': str(profile.id),
        'name': profile.name,
        'email': profile.email,
        'profile_type': display_type,
        'base_currency': profile.base_currency,
        'timezone': profile.timezone,
        'last_login': profile.last_login.isoformat() if profile.last_login else None
    }

def validate_required_fields(data: Dict[str, Any], required_fields: list) -> tuple:
    """Validate that all required fields are present"""
    missing_fields = [field for field in required_fields if not data.get(field)]
    if missing_fields:
        return False, f"Missing required fields: {', '.join(missing_fields)}"
    return True, None

# =============================================================================
# API VIEWS
# =============================================================================

class AccountTypeSelectionView(APIView):
    """
    API endpoint for initial account type selection.
    Returns available account types and their descriptions.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Get available account types"""
        # Use dictionary mapping instead of hardcoded arrays
        account_types = [
            {
                'value': info['code'],
                'label': info['label'],
                'description': info['description'],
                'features': info['features']
            }
            for profile_type, info in PROFILE_TYPE_MAPPINGS.items()
        ]
        
        return Response({
            'account_types': account_types,
            'default_currency': DEFAULT_SETTINGS['currency'],
            'available_currencies': DEFAULT_SETTINGS['currencies'],
            'default_timezone': DEFAULT_SETTINGS['timezone']
        })
    
    def post(self, request):
        """Process account type selection and create profile"""
        serializer = AccountTypeSelectionSerializer(data=request.data)
        
        if serializer.is_valid():
            validated_data = get_validated_data(serializer)
            
            # Build profile data using dictionary comprehension
            profile_data = {
                key: validated_data.get(field, default)
                for key, field, default in [
                    ('name', 'user_name', ''),
                    ('profile_type', 'account_type', ''),
                    ('base_currency', 'base_currency', DEFAULT_SETTINGS['currency']),
                    ('timezone', 'timezone', DEFAULT_SETTINGS['timezone']),
                    ('email', 'email', '')
                ]
            }
            
            profile_serializer = ProfileRegistrationSerializer(data=profile_data)
            
            if profile_serializer.is_valid():
                profile = profile_serializer.save()
                
                # Use dictionary lookup for response message
                message_key = 'registration_with_email' if profile_data.get('email') else 'registration_without_email'
                
                response_data = {
                    'profile_id': profile.id,
                    'profile_type': profile.profile_type,
                    'name': profile.name,
                    'message': RESPONSE_MESSAGES[message_key]
                }
                
                return Response(response_data, status=status.HTTP_201_CREATED)
            else:
                return Response(profile_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileLoginView(APIView):
    """
    API endpoint for PIN-based authentication.
    Validates profile ID and PIN combination.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileLoginSerializer(data=request.data)
        
        if serializer.is_valid():
            validated_data = get_validated_data(serializer)
            profile = validated_data.get('profile')
            
            if not profile:
                return Response(
                    {'error': ERROR_MESSAGES['auth_failed']}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Update last login
            profile.last_login = timezone.now()
            profile.save(update_fields=['last_login'])
            
            profile_serializer = ProfileSerializer(profile)
            return Response({
                'message': RESPONSE_MESSAGES['login_success'],
                'profile': profile_serializer.data,
                'requires_pin_change': self.requires_pin_change(profile),
                'dashboard_url': get_dashboard_url(profile.profile_type)
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def requires_pin_change(self, profile: Profile) -> bool:
        """Check if profile requires PIN change (first login)"""
        time_diff = timezone.now() - profile.created_at
        return time_diff.total_seconds() < 300  # 5 minutes threshold


class PINChangeView(APIView):
    """
    API endpoint for PIN change functionality.
    Handles both first-time setup and regular PIN updates.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = PINChangeSerializer(data=request.data)
        
        if serializer.is_valid():
            profile_id = request.data.get('profile_id')
            
            try:
                profile = Profile.objects.get(id=profile_id, is_active=True)
                validated_data = get_validated_data(serializer)
                  # Validate required fields
                current_pin = validated_data.get('current_pin')
                new_pin = validated_data.get('new_pin')
                
                # Check for missing fields
                if not current_pin:
                    return Response(
                        {'error': ERROR_MESSAGES['current_pin_required']}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                if not new_pin:
                    return Response(
                        {'error': ERROR_MESSAGES['new_pin_required']}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Verify current PIN
                if not profile.verify_pin(current_pin):
                    return Response(
                        {'error': ERROR_MESSAGES['incorrect_current_pin']}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Set new PIN
                profile.set_pin(new_pin)
                
                return Response({
                    'message': RESPONSE_MESSAGES['pin_change_success'],
                    'redirect_to_dashboard': True,
                    'dashboard_url': get_dashboard_url(profile.profile_type)
                })
                
            except Profile.DoesNotExist:
                return Response(
                    {'error': ERROR_MESSAGES['profile_not_found']}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class EmailCredentialsView(APIView):
    """
    API endpoint for requesting credentials via email.
    Used when user forgets their profile ID or PIN.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = EmailCredentialsSerializer(data=request.data)
        
        if serializer.is_valid():
            validated_data = get_validated_data(serializer)
            email = validated_data.get('email')
            
            if not email:
                return Response(
                    {'error': ERROR_MESSAGES['email_required']}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                send_mail(
                    'Fedha Account Recovery Request',
                    f'''
                    We received a request to recover credentials for {email}.
                    
                    If you have an account with this email, your credentials have been sent.
                    If you don't have an account, please register at our website.
                    
                    If you didn't request this, please ignore this email.
                    ''',
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    fail_silently=False,
                )
                
                return Response({
                    'message': RESPONSE_MESSAGES['email_sent']
                })
                
            except Exception as e:
                return Response(
                    {'error': RESPONSE_MESSAGES['email_failed']}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DashboardView(APIView):
    """
    API endpoint for dashboard data.
    Returns profile-specific dashboard information.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        profile_id = request.query_params.get('profile_id')
        
        if not profile_id:
            return Response(
                {'error': ERROR_MESSAGES['profile_id_required']}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            profile = Profile.objects.get(id=profile_id, is_active=True)
            display_type = DB_CODE_TO_TYPE.get(profile.profile_type, 'personal')
            
            dashboard_data = {
                'profile': ProfileSerializer(profile).data,
                'dashboard_type': display_type,
                'quick_stats': self.get_quick_stats(profile),
                'recent_activity': self.get_recent_activity(profile),
                'available_features': get_profile_features(profile.profile_type)
            }
            
            return Response(dashboard_data)
            
        except Profile.DoesNotExist:
            return Response(
                {'error': ERROR_MESSAGES['profile_not_found']}, 
                status=status.HTTP_404_NOT_FOUND
            )
    
    def get_quick_stats(self, profile):
        """Get quick statistics for dashboard"""
        return {
            'total_balance': 0,
            'monthly_income': 0,
            'monthly_expenses': 0,
            'active_goals': 0
        }
    
    def get_recent_activity(self, profile):
        """Get recent activity for dashboard"""
        return []


# =============================================================================
# ENHANCED PROFILE MANAGEMENT - NEW ENDPOINTS FOR 8-DIGIT USER IDS
# =============================================================================

class EnhancedProfileRegistrationView(APIView):
    """
    Enhanced API endpoint for profile registration with 8-digit user IDs.
    Supports cross-device profile storage and retrieval.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            # Extract registration data using dictionary comprehension
            registration_data = {
                key: request.data.get(key, default)
                for key, default in [
                    ('name', None),
                    ('profile_type', None),
                    ('pin', None),
                    ('email', None),
                    ('base_currency', 'KES'),
                    ('timezone', 'GMT+3')
                ]
            }
            
            # Validate required fields
            required_fields = ['name', 'profile_type', 'pin']
            valid, error_msg = validate_required_fields(registration_data, required_fields)
            if not valid:
                return Response(
                    {'error': error_msg}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate profile type using dictionary lookup
            if registration_data['profile_type'] not in PROFILE_TYPE_MAPPINGS:
                return Response(
                    {'error': ERROR_MESSAGES['invalid_profile_type']}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get profile type code using mapping
            profile_type_info = get_profile_type_info(registration_data['profile_type'])
            
            # Generate user ID and create profile
            user_id = Profile.generate_user_id()
            profile = Profile.objects.create(
                user_id=user_id,
                name=registration_data['name'],
                email=registration_data['email'],
                profile_type=profile_type_info['code'],
                pin_hash=Profile.hash_pin(registration_data['pin']),
                base_currency=registration_data['base_currency'],
                timezone=registration_data['timezone'],
                is_active=True
            )
            
            # Build response using helper function
            response_data = format_profile_response(profile)
            response_data.update({
                'success': True,
                'message': RESPONSE_MESSAGES['registration_success']
            })
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {'error': f'Registration failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class EnhancedProfileLoginView(APIView):
    """
    Enhanced API endpoint for profile login using 8-digit user ID and PIN.
    Supports cross-device authentication.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            # Extract login data
            login_data = {
                key: request.data.get(key)
                for key in ['user_id', 'pin']
            }
            
            # Validate required fields
            required_fields = ['user_id', 'pin']
            valid, error_msg = validate_required_fields(login_data, required_fields)
            if not valid:
                return Response(
                    {'error': error_msg}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find and authenticate profile
            try:
                profile = Profile.objects.get(user_id=login_data['user_id'], is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': ERROR_MESSAGES['profile_not_found']}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Verify PIN
            if not profile.verify_pin(login_data['pin']):
                return Response(
                    {'error': ERROR_MESSAGES['invalid_pin']}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Update last login
            profile.last_login = timezone.now()
            profile.save()
            
            # Build response using helper function
            response_data = format_profile_response(profile)
            response_data.update({
                'success': True,
                'message': RESPONSE_MESSAGES['login_success']
            })
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Login failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class LegacyProfileSyncView(APIView):
    """
    Legacy API endpoint for profile data synchronization across devices.
    Supports both upload and download of profile data.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Download profile data for synchronization"""
        try:
            user_id = request.query_params.get('user_id')
            
            if not user_id:
                return Response(
                    {'error': ERROR_MESSAGES['user_id_required']}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                profile = Profile.objects.get(user_id=user_id, is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': ERROR_MESSAGES['profile_not_found']}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Build response using helper function
            response_data = format_profile_response(profile)
            response_data.update({
                'success': True,
                'date_created': profile.date_created.isoformat() if hasattr(profile, 'date_created') and profile.date_created else None
            })
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Sync download failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Upload profile data for synchronization"""
        try:
            user_id = request.data.get('user_id')
            profile_data = request.data.get('profile_data', {})
            
            if not user_id:
                return Response(
                    {'error': ERROR_MESSAGES['user_id_required']}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                profile = Profile.objects.get(user_id=user_id, is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': ERROR_MESSAGES['profile_not_found']}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update profile fields using dictionary iteration
            updatable_fields = ['name', 'email', 'base_currency', 'timezone']
            updated = False
            
            for field in updatable_fields:
                if field in profile_data:
                    setattr(profile, field, profile_data[field])
                    updated = True
            
            if updated:
                profile.save()
            
            return Response({
                'success': True,
                'message': RESPONSE_MESSAGES['sync_success'],
                'user_id': profile.user_id,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Sync failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# =============================================================================
# LEGACY VIEWS AND ENDPOINTS
# =============================================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def legacy_profile_validate(request):
    """Validate if a profile exists by user ID (for cross-device login)"""
    try:
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response(
                {'error': ERROR_MESSAGES['user_id_required']}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        exists = Profile.objects.filter(user_id=user_id, is_active=True).exists()
        
        return Response({
            'exists': exists,
            'user_id': user_id
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Validation failed: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


class ProfileRegistrationView(generics.CreateAPIView):
    """API endpoint for user registration with auto-generated UUID and temporary PIN."""
    queryset = Profile.objects.all()
    serializer_class = ProfileRegistrationSerializer
    permission_classes = [AllowAny]
    
    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        
        if response.status_code == status.HTTP_201_CREATED and response.data:
            profile = Profile.objects.get(id=response.data['id'])
            
            response.data.update({
                'profile_id': profile.id,
                'profile_type': profile.profile_type,
                'requires_pin_change': True,
                'message': 'Registration successful. Please log in and change your PIN.'
            })
        
        return response


class ProfileListCreateView(generics.ListCreateAPIView):
    queryset = Profile.objects.filter(is_active=True)
    serializer_class = ProfileSerializer
    permission_classes = [AllowAny]

    def perform_create(self, serializer):
        pin = serializer.validated_data.get('pin')
        if pin:
            serializer.save(pin_hash=Profile.hash_pin(pin))


class ProfileDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [AllowAny]

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save()


@api_view(['GET'])
@permission_classes([AllowAny])
def auth_status(request):
    """Check if user is authenticated and return profile info"""
    profile_id = request.query_params.get('profile_id')
    
    if profile_id:
        try:
            profile = Profile.objects.get(id=profile_id, is_active=True)
            return Response({
                'authenticated': True,
                'profile': ProfileSerializer(profile).data
            })
        except Profile.DoesNotExist:
            pass
    
    return Response({'authenticated': False})


# =============================================================================
# FINANCIAL CALCULATOR API VIEWS
# =============================================================================

class LoanCalculatorView(APIView):
    """
    API endpoint for loan payment calculations.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Calculate loan payment"""
        from .serializers import LoanCalculationRequestSerializer
        
        serializer = LoanCalculationRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator, LoanParameters, InterestType, PaymentFrequency
            
            # Get validated data safely
            data: Dict[str, Any] = get_validated_data(serializer)
            
            # Check if required fields exist
            if not all(key in data for key in ['principal', 'annual_rate', 'term_years', 'interest_type', 'payment_frequency']):
                return Response(
                    {'error': 'Missing required parameters for calculation'},
                    status=status.HTTP_400_BAD_REQUEST
                )
              # Map Django enum values to calculator engine enum values
            calculator_interest_type = map_django_to_calculator_interest_type(data['interest_type'])
            calculator_payment_freq = map_django_to_calculator_payment_frequency(data['payment_frequency'])
              # Create loan parameters
            loan_params = LoanParameters(
                principal=float(data['principal']),  # type: ignore
                annual_rate=float(data['annual_rate']),  # type: ignore
                term_years=data['term_years'],  # type: ignore
                interest_type=InterestType(calculator_interest_type),  # type: ignore
                payment_frequency=get_calculator_payment_frequency_enum(data['payment_frequency'])  # type: ignore
            )
            
            result = FinancialCalculator.calculate_payment(loan_params)
            
            # Convert Decimal results to strings for JSON serialization
            return Response({
                'monthly_payment': str(result.monthly_payment),
                'total_amount': str(result.total_amount),
                'total_interest': str(result.total_interest),
                'payment_amount': str(result.payment_amount),
                'total_payments': result.total_payments
            })
            
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class InterestRateSolverView(APIView):
    """
    API endpoint for solving interest rates using Newton-Raphson method.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Solve for interest rate given payment amount"""
        from .serializers import InterestRateSolverRequestSerializer
        
        serializer = InterestRateSolverRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator, PaymentFrequency
            
            # Get validated data safely
            data: Dict[str, Any] = get_validated_data(serializer)
            
            # Check if required fields exist
            if not all(key in data for key in ['principal', 'payment', 'term_years', 'payment_frequency']):
                return Response(
                    {'error': 'Missing required parameters for calculation'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            result = FinancialCalculator.solve_interest_rate(
                principal=float(data['principal']),
                payment=float(data['payment']),
                term_years=data['term_years'],
                payment_frequency=get_calculator_payment_frequency_enum(data['payment_frequency']),
                tolerance=float(data.get('tolerance', 0.00001)),
                max_iterations=data.get('max_iterations', 100)
            )
            
            return Response({
                'annual_rate': str(result['annual_rate']),
                'converged': result['converged'],
                'iterations': result['iterations']
            })
            
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class AmortizationScheduleView(APIView):
    """
    API endpoint for generating amortization schedules.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Generate complete amortization schedule"""
        from .serializers import AmortizationScheduleRequestSerializer
        
        serializer = AmortizationScheduleRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator, PaymentFrequency
            
            data = get_validated_data(serializer)
            schedule = FinancialCalculator.generate_amortization_schedule(
                principal=float(data['principal']),
                annual_rate=float(data['annual_rate']),
                term_years=data['term_years'],
                payment_frequency=get_calculator_payment_frequency_enum(data['payment_frequency'])
            )
            
            # Convert to serializable format
            schedule_data = []
            for entry in schedule:
                schedule_data.append({
                    'payment_number': entry.payment_number,
                    'payment_amount': str(entry.payment_amount),
                    'principal_payment': str(entry.principal_payment),
                    'interest_payment': str(entry.interest_payment),
                    'remaining_balance': str(entry.remaining_balance)
                })
            
            return Response({'schedule': schedule_data})
            
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class EarlyPaymentCalculatorView(APIView):
    """
    API endpoint for calculating early payment savings.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Calculate savings from extra payments"""
        from .serializers import EarlyPaymentRequestSerializer
        
        serializer = EarlyPaymentRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator, PaymentFrequency
            
            data = get_validated_data(serializer)
            result = FinancialCalculator.calculate_early_payment_savings(
                principal=float(data['principal']),
                annual_rate=float(data['annual_rate']),
                term_years=data['term_years'],
                extra_payment=float(data['extra_payment']),
                payment_frequency=get_calculator_payment_frequency_enum(data['payment_frequency']),
                extra_payment_type=map_django_to_calculator_payment_frequency(data['extra_payment_type'])
            )
            
            return Response({
                'original_total_interest': str(result.original_total_interest),
                'original_total_payments': str(result.original_total_payments),
                'original_term_months': result.original_term_months,
                'new_total_interest': str(result.new_total_interest),
                'new_total_payments': str(result.new_total_payments),
                'new_term_months': result.new_term_months,
                'interest_savings': str(result.interest_savings),
                'time_savings_months': result.time_savings_months
            })
            
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class ROICalculatorView(APIView):
    """
    API endpoint for ROI calculations.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Calculate return on investment"""
        from .serializers import ROICalculationRequestSerializer
        
        serializer = ROICalculationRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator
            
            data = get_validated_data(serializer)
            time_years = data.get('time_years')
            time_years_float = float(time_years) if time_years else None
            
            result = FinancialCalculator.calculate_roi(
                initial_investment=float(data['initial_investment']),
                final_value=float(data['final_value']),
                time_years=time_years_float
            )
            
            response_data = {
                'roi_percentage': str(result.roi_percentage),
                'total_return': str(result.total_return)
            }
            
            if result.annualized_return is not None:
                response_data['annualized_return'] = str(result.annualized_return)
            
            return Response(response_data)
            
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class CompoundInterestCalculatorView(APIView):
    """
    API endpoint for compound interest calculations.
    """
    permission_classes = [AllowAny]
    def post(self, request):
        """Calculate compound interest with optional contributions"""
        from .serializers import CompoundInterestRequestSerializer
        
        serializer = CompoundInterestRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {'errors': serializer.errors}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
            from interest_calculator import FinancialCalculator, PaymentFrequency
            data = get_validated_data(serializer)
            additional_frequency = data.get('additional_frequency')
            additional_frequency_enum = get_calculator_payment_frequency_enum(additional_frequency) if additional_frequency else get_calculator_payment_frequency_enum('MONTHLY')
            
            result = FinancialCalculator.calculate_compound_interest(
                principal=float(data['principal']),
                annual_rate=float(data['annual_rate']),
                time_years=float(data['time_years']),
                compounding_frequency=get_calculator_payment_frequency_enum(data['compounding_frequency']),
                additional_payment=float(data.get('additional_payment', 0)),
                additional_frequency=additional_frequency_enum
            )
            
            return Response({
                'future_value': str(result.future_value),
                'total_interest': str(result.total_interest),
                'total_contributions': str(result.total_contributions)
            })
                
        except Exception as e:
            return Response(
                {'error': f'Calculation error: {str(e)}'}, 
                status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PortfolioMetricsView(APIView):
    """
    API endpoint for portfolio performance calculations.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Calculate portfolio metrics"""
        from .serializers import PortfolioMetricsRequestSerializer
        
        serializer = PortfolioMetricsRequestSerializer(data=request.data)
        if serializer.is_valid():
            try:
                import sys
                import os
                sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
                from interest_calculator import FinancialCalculator
                
                data = get_validated_data(serializer)
                
                # Check if investments data exists
                if not data or 'investments' not in data:
                    return Response(
                        {'error': 'Missing required parameter: investments'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Convert decimal fields to float for calculation
                investments = []
                for investment in data['investments']:
                    inv_data = {}
                    for key, value in investment.items():
                        inv_data[key] = float(value)
                    investments.append(inv_data)
                
                result = FinancialCalculator.calculate_portfolio_metrics(investments)
                
                # Convert results to strings for JSON serialization
                return Response({
                    'total_investment': str(result['total_investment']),
                    'total_current_value': str(result['total_current_value']),
                    'total_gain_loss': str(result['total_gain_loss']),
                    'total_return_percentage': str(result['total_return_percentage'])
                })
                
            except Exception as e:
                return Response(
                    {'error': f'Calculation error: {str(e)}'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RiskAssessmentView(APIView):
    """
    API endpoint for investment risk profile assessment.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Assess investment risk profile"""
        from .serializers import RiskAssessmentRequestSerializer
        
        serializer = RiskAssessmentRequestSerializer(data=request.data)
        if serializer.is_valid():
            try:
                import sys
                import os
                sys.path.append(os.path.join(os.path.dirname(__file__), 
                                             '..', '..', 'calculators-microservice'))
                from interest_calculator import FinancialCalculator
                
                data = get_validated_data(serializer)
                
                # Check if answers data exists
                if not data or 'answers' not in data:
                    return Response(
                        {'error': 'Missing required parameter: answers'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                result = FinancialCalculator.assess_risk_profile(
                    answers=data['answers']
                )
                
                return Response(result)
                
            except Exception as e:
                return Response(
                    {'error': f'Assessment error: {str(e)}'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# =============================================================================
# ENUM MAPPING FUNCTIONS FOR FINANCIAL CALCULATOR
# =============================================================================

def map_django_to_calculator_interest_type(django_value: str) -> str:
    """
    Map Django model InterestType enum values to calculator engine values.
    """
    mapping = {
        'SIMPLE': 'simple',
        'COMPOUND': 'compound', 
        'REDUCING': 'reducing_balance',
        'FLAT': 'flat_rate'
    }
    return mapping.get(django_value, 'compound')  # Default to compound


def map_django_to_calculator_payment_frequency(django_value: str) -> str:
    """
    Map Django model PaymentFrequency enum values to calculator engine values.
    """
    mapping = {
        'DAILY': 'daily',
        'WEEKLY': 'weekly',
        'BIWEEKLY': 'biweekly',
        'MONTHLY': 'monthly',
        'QUARTERLY': 'quarterly',
        'SEMI_ANNUALLY': 'semi_annually',
        'ANNUALLY': 'annually'
    }
    return mapping.get(django_value, 'monthly')  # Default to monthly


def get_calculator_payment_frequency_enum(django_value: str):
    """
    Get the PaymentFrequency enum value for calculator engine.
    """
    # Import here to avoid circular imports
    import sys
    import os
    sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..', 'calculators-microservice'))
    from interest_calculator import PaymentFrequency
    
    mapping = {
        'DAILY': PaymentFrequency.DAILY,
        'WEEKLY': PaymentFrequency.WEEKLY,
        'BIWEEKLY': PaymentFrequency.WEEKLY,  # Use weekly for biweekly as approximation
        'MONTHLY': PaymentFrequency.MONTHLY,
        'QUARTERLY': PaymentFrequency.QUARTERLY,
        'SEMI_ANNUALLY': PaymentFrequency.SEMI_ANNUALLY,
        'ANNUALLY': PaymentFrequency.ANNUALLY
    }
    return mapping.get(django_value, PaymentFrequency.MONTHLY)  # Default to monthly


# =============================================================================
# EXISTING CONSTANTS AND HELPER FUNCTIONS
# =============================================================================

# Error message templates
ERROR_MESSAGES = {
    'auth_failed': 'Authentication failed',
    'profile_not_found': 'Profile not found',
    'invalid_pin': 'Invalid PIN',
    'invalid_profile_type': 'Profile type must be "business" or "personal"',
    'required_fields': 'Name, profile type, and PIN are required',
    'user_id_required': 'User ID is required',
    'email_required': 'Email is required',
    'current_pin_required': 'Current PIN is required',
    'new_pin_required': 'New PIN is required',
    'incorrect_current_pin': 'Current PIN is incorrect',
    'profile_id_required': 'Profile ID required'
}

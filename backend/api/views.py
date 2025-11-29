# backend/api/views.py
"""
Fedha Budget Tracker - API Views

This module defines API views for the Fedha Budget Tracker,
with focus on authentication, profiles, and SMS transaction parsing.

Author: Fedha Development Team
Last Updated: November 15, 2025
"""

from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password, check_password
from django.core.mail import send_mail
from django.conf import settings
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.shortcuts import render
from django.utils import timezone
import json
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .services.sms_parser import RuleBasedSMSParser, TransactionCandidateFactory
import logging
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from .serializers import UserSerializer, ProfileSerializer

logger = logging.getLogger(__name__)

from typing import Dict, Any, Optional

from .models import Profile
from .serializers import (
    ProfileSerializer, 
    ProfileRegistrationSerializer, 
    ProfileLoginSerializer,
)

# =============================================================================
# CONFIGURATION CONSTANTS AND MAPPINGS
# =============================================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """
    User registration with token authentication
    """
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'user': serializer.data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)
    return Response(
        {'errors': serializer.errors}, 
        status=status.HTTP_400_BAD_REQUEST
    )

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """
    User login with token authentication
    """
    from django.contrib.auth import authenticate
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response(
            {'error': 'Username and password are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email
            }
        })
    return Response(
        {'error': 'Invalid credentials'}, 
        status=status.HTTP_401_UNAUTHORIZED
    )

# Profile type mappings - moved to settings in production
PROFILE_TYPE_MAPPINGS = {
    'business': {
        'code': 'BIZ',
        'label': 'Business',
        'description': 'For business owners, freelancers, and SMEs.',
        'dashboard_url': '/dashboard/business',
    },
    'personal': {
        'code': 'PERS',
        'label': 'Personal',
        'description': 'For personal finance management and budgeting.',
        'dashboard_url': '/dashboard/personal',
    }
}

# Reverse mapping for database codes to display types
DB_CODE_TO_TYPE = {
    'BIZ': 'business',
    'PERS': 'personal'
}

# Response messages
RESPONSE_MESSAGES = {
    'registration_success': 'Account created successfully',
    'login_success': 'Login successful',
    'profile_not_found': 'Profile not found',
    'invalid_credentials': 'Invalid email or password',
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def get_profile_type_info(profile_type: str) -> Dict[str, Any]:
    """Get profile type information using dictionary lookup"""
    return PROFILE_TYPE_MAPPINGS.get(profile_type, PROFILE_TYPE_MAPPINGS['personal'])

def get_dashboard_url(profile_type_code: str) -> str:
    """Get dashboard URL based on profile type code"""
    display_type = DB_CODE_TO_TYPE.get(profile_type_code, 'personal')
    return PROFILE_TYPE_MAPPINGS[display_type]['dashboard_url']

def format_profile_response(profile: Profile) -> Dict[str, Any]:
    """Format profile data for API responses"""
    display_type = DB_CODE_TO_TYPE.get(profile.profile_type, 'personal')
    return {
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

def create_error_response(message: str, status_code: int, details=None):
    """Create consistent error response"""
    response = {'error': message}
    if details:
        response['details'] = details
    return Response(response, status=status_code)

# =============================================================================
# API VIEWS
# =============================================================================

class HealthCheckView(APIView):
    """Simple health check endpoint for server status"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        return Response({
            'status': 'ok', 
            'message': 'Fedha backend is running',
            'timestamp': timezone.now().isoformat()
        })

class SecureProfileRegistrationView(APIView):
    """Secure API endpoint for user profile registration with password hashing"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileRegistrationSerializer(data=request.data)
        
        if not serializer.is_valid():
            return create_error_response(
                'Invalid registration data', 
                status.HTTP_400_BAD_REQUEST,
                serializer.errors
            )
        
        try:
            # Hash password before saving
            validated_data = serializer.validated_data.copy()
            raw_password = validated_data.pop('password')
            
            # Create new profile with hashed password
            profile = Profile.objects.create(
                name=validated_data['name'],
                email=validated_data['email'],
                profile_type=validated_data.get('profile_type', 'PERS'),
                base_currency=validated_data.get('base_currency', 'KES'),
                timezone=validated_data.get('timezone', 'UTC'),
            )
            
            # Set hashed password
            profile.set_password(raw_password)
            profile.save()
            
            profile_serializer = ProfileSerializer(profile)
            return Response({
                'message': RESPONSE_MESSAGES['registration_success'],
                'profile': profile_serializer.data,
            }, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            logger.error(f"Registration error: {str(e)}")
            return create_error_response(
                'Registration failed',
                status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class SecureProfileLoginView(APIView):
    """Secure API endpoint for user login with password verification"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileLoginSerializer(data=request.data)
        
        if not serializer.is_valid():
            return create_error_response(
                'Invalid login data',
                status.HTTP_400_BAD_REQUEST,
                serializer.errors
            )
        
        try:
            # Find profile by email
            profile = Profile.objects.get(
                email=serializer.validated_data['email'],
                is_active=True
            )
            
            # Verify password using hashed comparison
            if not profile.check_password(serializer.validated_data['password']):
                return create_error_response(
                    RESPONSE_MESSAGES['invalid_credentials'],
                    status.HTTP_401_UNAUTHORIZED
                )
            
            # Update last login
            profile.last_login = timezone.now()
            profile.save(update_fields=['last_login'])
            
            profile_serializer = ProfileSerializer(profile)
            return Response({
                'message': RESPONSE_MESSAGES['login_success'],
                'profile': profile_serializer.data,
                'dashboard_url': get_dashboard_url(profile.profile_type)
            })
        
        except Profile.DoesNotExist:
            return create_error_response(
                RESPONSE_MESSAGES['invalid_credentials'],
                status.HTTP_401_UNAUTHORIZED
            )
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            return create_error_response(
                'Login failed',
                status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TransactionCandidateView(APIView):
    """
    API endpoint for creating and reviewing transaction candidates from SMS.
    Uses local rule-based SMS parsing.
    """
    permission_classes = [IsAuthenticated]  # Changed to require authentication
    
    def post(self, request):
        """
        Create transaction candidate from SMS text.
        
        Request body:
        {
            "sms_text": "M-PESA Confirmed. You have withdrawn Ksh5,000...",
            "profile_id": "uuid-here"
        }
        """
        from .serializers import TransactionCandidateSerializer
        
        serializer = TransactionCandidateSerializer(data=request.data)
        if not serializer.is_valid():
            return create_error_response(
                'Invalid transaction data',
                status.HTTP_400_BAD_REQUEST,
                serializer.errors
            )
        
        try:
            sms_text = serializer.validated_data['sms_text']
            profile_id = serializer.validated_data['profile_id']
            
            # Parse SMS using local rule-based parser only
            parse_result = RuleBasedSMSParser.parse(sms_text, profile_id)
            
            if not parse_result.get('success'):
                return Response({
                    'success': False,
                    'errors': [parse_result.get('error', 'Parsing failed')],
                }, status=status.HTTP_400_BAD_REQUEST)

            candidate = TransactionCandidateFactory.from_parsed_sms({
                'success': True,
                'data': parse_result,
                'primary_method': 'rule_based',
                'fallback_used': False
            }, profile_id)

            # TODO: Save transaction candidate to database
            # candidate_obj = TransactionCandidate.objects.create(**candidate)

            return Response({
                'success': True,
                'candidate': candidate,
                'parsing_method': 'rule_based',
                'fallback_used': False,
            }, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            logger.error(f"Transaction candidate creation error: {str(e)}")
            return create_error_response(
                'Transaction processing failed',
                status.HTTP_500_INTERNAL_SERVER_ERROR
            )
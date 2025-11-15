# backend/api/views.py
"""
Fedha Budget Tracker - API Views

This module defines API views for the Fedha Budget Tracker,
with focus on authentication, profiles, and SMS transaction parsing.

Author: Fedha Development Team
Last Updated: November 15, 2025
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
from .services.sms_parser import RuleBasedSMSParser, TransactionCandidateFactory
import logging

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

# Profile type mappings
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

# Currency and timezone defaults
DEFAULT_SETTINGS = {
    'currency': 'KES',
    'timezone': 'UTC',
    'currencies': ['KES', 'USD', 'EUR', 'GBP', 'JPY']
}

# Response messages
RESPONSE_MESSAGES = {
    'registration_success': 'Account created successfully',
    'login_success': 'Login successful',
    'profile_not_found': 'Profile not found',
    'invalid_credentials': 'Invalid email or password',
}

# Error messages
ERROR_MESSAGES = {
    'missing_fields': 'Missing required fields',
    'invalid_email': 'Invalid email format',
    'password_too_short': 'Password must be at least 6 characters',
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


# =============================================================================
# API VIEWS
# =============================================================================

class HealthCheckView(APIView):
    """Simple health check endpoint for server status"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        return Response({'status': 'ok', 'message': 'Fedha backend is running'})


class ProfileRegistrationView(APIView):
    """API endpoint for user profile registration"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileRegistrationSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                # Create new profile
                profile = Profile.objects.create(
                    name=serializer.validated_data['name'],
                    email=serializer.validated_data['email'],
                    password=serializer.validated_data['password'],
                    profile_type=serializer.validated_data.get('profile_type', 'PERS'),
                    base_currency=serializer.validated_data.get('base_currency', 'KES'),
                    timezone=serializer.validated_data.get('timezone', 'UTC'),
                )
                
                profile_serializer = ProfileSerializer(profile)
                return Response({
                    'message': RESPONSE_MESSAGES['registration_success'],
                    'profile': profile_serializer.data,
                }, status=status.HTTP_201_CREATED)
            
            except Exception as e:
                logger.error(f"Registration error: {str(e)}")
                return Response(
                    {'error': str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileLoginView(APIView):
    """API endpoint for user login"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileLoginSerializer(data=request.data)
        
        if serializer.is_valid():
            try:
                # Find profile by email
                profile = Profile.objects.get(
                    email=serializer.validated_data['email'],
                    is_active=True
                )
                
                # Verify password
                if profile.password != serializer.validated_data['password']:
                    return Response(
                        {'error': RESPONSE_MESSAGES['invalid_credentials']},
                        status=status.HTTP_401_UNAUTHORIZED
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
                return Response(
                    {'error': RESPONSE_MESSAGES['invalid_credentials']},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            except Exception as e:
                logger.error(f"Login error: {str(e)}")
                return Response(
                    {'error': str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TransactionCandidateView(APIView):
    """
    API endpoint for creating and reviewing transaction candidates from SMS.
    Uses local rule-based SMS parsing.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """
        Create transaction candidate from SMS text.
        
        Request body:
        {
            "sms_text": "M-PESA Confirmed. You have withdrawn Ksh5,000...",
            "profile_id": "uuid-here"
        }
        """
        try:
            sms_text = request.data.get('sms_text')
            profile_id = request.data.get('profile_id')
            
            if not sms_text or not profile_id:
                return Response(
                    {'error': 'Missing required fields: sms_text, profile_id'},
                    status=status.HTTP_400_BAD_REQUEST
                )

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
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

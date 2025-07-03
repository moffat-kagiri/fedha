# backend/api/enhanced_views.py
"""
Fedha Budget Tracker - Enhanced Profile Management Views

This module defines enhanced API views for cross-device profile management
with 8-digit user IDs and secure server-side storage.

Key Features:
- 8-digit randomized user ID generation
- Cross-device profile synchronization
- Secure PIN-based authentication
- Server-side profile storage for persistence

Author: Fedha Development Team
Last Updated: June 2, 2025
"""
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
import random

from .models import Profile


class EnhancedProfileRegistrationView(APIView):
    """
    Enhanced API endpoint for profile registration with 8-digit user IDs.
    Supports cross-device profile storage and retrieval.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Create a new enhanced profile with 8-digit user ID"""
        try:
            # Extract profile data
            name = request.data.get('name', '')
            profile_type = request.data.get('profile_type')
            pin = request.data.get('pin')
            email = request.data.get('email')
            base_currency = request.data.get('base_currency', 'KES')
            timezone_str = request.data.get('timezone', 'GMT+3')
            
            # Validate required fields
            if not profile_type or not pin:
                return Response(
                    {'error': 'Profile type and password are required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate password length (minimum 6 characters for frontend consistency)
            if len(pin) < 6:
                return Response(
                    {'error': 'Password must be at least 6 characters'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Generate 8-digit user ID
            user_id = self.generate_8_digit_user_id()
            
            # Create profile using the Profile model's custom save method
            profile = Profile(
                id=user_id,  # Use 8-digit ID as primary key
                name=name,
                profile_type='BIZ' if profile_type == 'business' else 'PERS',
                base_currency=base_currency,
                timezone=timezone_str
            )
            
            # Set password using the model's secure hash method
            profile.set_pin(pin)
            profile.save()
            
            return Response({
                'success': True,
                'user_id': user_id,
                'profile_id': profile.id,
                'profile_type': profile_type,
                'name': name,
                'message': 'Profile created successfully'
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to create profile: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def generate_8_digit_user_id(self):
        """Generate a unique 8-digit user ID"""
        max_attempts = 100
        attempts = 0
        
        while attempts < max_attempts:
            # Generate random 8-digit number
            user_id = str(random.randint(10000000, 99999999))
            # Check if it's unique
            if not Profile.objects.filter(id=user_id).exists():
                return user_id
            attempts += 1
        
        # If we can't find a unique ID, raise an error
        raise Exception("Unable to generate unique user ID")


class EnhancedProfileLoginView(APIView):
    """
    Enhanced API endpoint for profile login with 8-digit user IDs.
    Supports cross-device authentication.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Authenticate using 8-digit user ID and PIN"""
        try:
            user_id = request.data.get('user_id')
            pin = request.data.get('pin')
            
            if not user_id or not pin:
                return Response(
                    {'error': 'User ID and password are required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Find profile by 8-digit user ID
            try:
                profile = Profile.objects.get(id=user_id, is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': 'Profile not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Verify password using the model's secure verification method
            if not profile.verify_pin(pin):
                return Response(
                    {'error': 'Invalid password'}, 
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Update last login
            profile.record_login()
            
            # Return profile data
            return Response({
                'success': True,
                'profile': {
                    'user_id': profile.id,
                    'name': profile.name,
                    'profile_type': 'business' if profile.profile_type == 'BIZ' else 'personal',
                    'base_currency': profile.base_currency,
                    'timezone': profile.timezone,
                    'created_at': profile.created_at.isoformat(),
                    'last_login': profile.last_login.isoformat() if profile.last_login else None
                },
                'message': 'Login successful'
            })
            
        except Exception as e:
            return Response(
                {'error': f'Login failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class EnhancedProfileSyncView(APIView):
    """
    Enhanced API endpoint for profile synchronization across devices.
    Handles upload/download of profile data for cross-device access.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Download profile data for synchronization"""
        try:
            user_id = request.query_params.get('user_id')
            
            if not user_id:
                return Response(
                    {'error': 'User ID is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                profile = Profile.objects.get(id=user_id, is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': 'Profile not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Return comprehensive profile data
            return Response({
                'profile': {
                    'user_id': profile.id,
                    'name': profile.name,
                    'profile_type': 'business' if profile.profile_type == 'BIZ' else 'personal',
                    'pin_hash': profile.pin_hash,  # For client-side verification
                    'base_currency': profile.base_currency,
                    'timezone': profile.timezone,
                    'created_at': profile.created_at.isoformat(),
                    'last_login': profile.last_login.isoformat() if profile.last_login else None,
                    'is_active': profile.is_active
                }
            })
            
        except Exception as e:
            return Response(
                {'error': f'Sync failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """Upload profile data for synchronization"""
        try:
            user_id = request.data.get('user_id')
            profile_data = request.data.get('profile_data', {})
            
            if not user_id:
                return Response(
                    {'error': 'User ID is required'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                profile = Profile.objects.get(id=user_id, is_active=True)
            except Profile.DoesNotExist:
                return Response(
                    {'error': 'Profile not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update profile with new data
            updated_fields = []
            
            if 'name' in profile_data:
                profile.name = profile_data['name']
                updated_fields.append('name')
            
            if 'base_currency' in profile_data:
                profile.base_currency = profile_data['base_currency']
                updated_fields.append('base_currency')
            
            if 'timezone' in profile_data:
                profile.timezone = profile_data['timezone']
                updated_fields.append('timezone')
            
            if updated_fields:
                updated_fields.append('last_modified')
                profile.save(update_fields=updated_fields)
            
            return Response({
                'success': True,
                'message': 'Profile synchronized successfully',
                'updated_fields': updated_fields
            })
            
        except Exception as e:
            return Response(
                {'error': f'Sync failed: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@api_view(['POST'])
@permission_classes([AllowAny])
def enhanced_profile_validate(request):
    """Validate that a profile exists without full authentication"""
    try:
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response(
                {'error': 'User ID is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            profile = Profile.objects.get(id=user_id, is_active=True)
            return Response({
                'exists': True,
                'profile_type': 'business' if profile.profile_type == 'BIZ' else 'personal',
                'name': profile.name
            })
        except Profile.DoesNotExist:
            return Response({
                'exists': False
            })
            
    except Exception as e:
        return Response(
            {'error': f'Validation failed: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

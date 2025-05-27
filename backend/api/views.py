# backend/api/views.py
"""
Fedha Budget Tracker - API Views

This module defines API views for the Fedha Budget Tracker,
focusing on complete authentication flow implementation.

Key Features:
- Account type selection and registration
- PIN-based authentication
- Email credential delivery
- First-time password reset
- Dashboard navigation
- Session management

Author: Fedha Development Team
Last Updated: May 26, 2025
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

from .models import Profile
from .serializers import (
    ProfileSerializer, 
    ProfileRegistrationSerializer, 
    ProfileLoginSerializer,
    PINChangeSerializer,
    EmailCredentialsSerializer,
    AccountTypeSelectionSerializer
)


class AccountTypeSelectionView(APIView):
    """
    API endpoint for initial account type selection.
    Returns available account types and their descriptions.
    """
    permission_classes = [AllowAny]
    
    def get(self, request):
        """Get available account types"""
        account_types = [
            {
                'value': 'BIZ',
                'label': 'Business',
                'description': 'For business owners, freelancers, and SMEs. Includes invoicing, client management, and tax preparation.',
                'features': [
                    'Invoice generation and management',
                    'Client relationship management', 
                    'Tax preparation and compliance',
                    'Cash flow analysis',
                    'Business expense tracking',
                    'Loan and asset management'
                ]
            },
            {
                'value': 'PERS',
                'label': 'Personal',
                'description': 'For personal finance management and budgeting. Focus on savings, goals, and expense tracking.',
                'features': [
                    'Personal budget tracking',
                    'Goal setting and monitoring',
                    'Expense categorization',
                    'Savings tracking',
                    'Personal loan management',
                    'Investment tracking'
                ]
            }
        ]
        
        return Response({
            'account_types': account_types,
            'default_currency': 'USD',
            'available_currencies': ['USD', 'KES', 'EUR', 'GBP', 'JPY'],
            'default_timezone': 'UTC'
        })
    
    def post(self, request):
        """Process account type selection and create profile"""
        serializer = AccountTypeSelectionSerializer(data=request.data)
        
        if serializer.is_valid():
            # Create profile with selected account type
            profile_data = {
                'name': serializer.validated_data.get('user_name', ''),
                'profile_type': serializer.validated_data['account_type'],
                'base_currency': serializer.validated_data.get('base_currency', 'USD'),
                'timezone': serializer.validated_data.get('timezone', 'UTC'),
                'email': serializer.validated_data.get('email', '')
            }
            
            profile_serializer = ProfileRegistrationSerializer(data=profile_data)
            
            if profile_serializer.is_valid():
                profile = profile_serializer.save()
                
                response_data = {
                    'profile_id': profile.id,
                    'profile_type': profile.profile_type,
                    'name': profile.name,
                    'message': 'Account created successfully'
                }
                
                # Include temporary PIN if email wasn't provided
                if not profile_data.get('email') and hasattr(profile, 'temp_pin'):
                    response_data['temporary_pin'] = profile.temp_pin
                    response_data['message'] = 'Account created successfully. Please save your credentials.'
                else:
                    response_data['message'] = 'Account created successfully. Credentials sent to your email.'
                
                return Response(response_data, status=status.HTTP_201_CREATED)
            else:
                return Response(profile_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileRegistrationView(generics.CreateAPIView):
    """
    API endpoint for user registration.
    Creates new profile with auto-generated UUID and temporary PIN.
    """
    queryset = Profile.objects.all()
    serializer_class = ProfileRegistrationSerializer
    permission_classes = [AllowAny]
    
    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        
        if response.status_code == status.HTTP_201_CREATED:
            profile = Profile.objects.get(id=response.data['id'])
            
            # Add additional response data
            response.data.update({
                'profile_id': profile.id,
                'profile_type': profile.profile_type,
                'requires_pin_change': True,
                'message': 'Registration successful. Please log in and change your PIN.'
            })
            
            # Include temporary PIN if available
            if hasattr(profile, 'temp_pin'):
                response.data['temporary_pin'] = profile.temp_pin
        
        return response


class ProfileLoginView(APIView):
    """
    API endpoint for PIN-based authentication.
    Validates profile ID and PIN combination.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = ProfileLoginSerializer(data=request.data)
        
        if serializer.is_valid():
            profile = serializer.validated_data['profile']
            
            # Update last login
            profile.last_login = timezone.now()
            profile.save(update_fields=['last_login'])
            
            # Create session or token here (implement as needed)
            # For now, return profile information
            
            profile_serializer = ProfileSerializer(profile)
            
            return Response({
                'message': 'Login successful',
                'profile': profile_serializer.data,
                'requires_pin_change': self.requires_pin_change(profile),
                'dashboard_url': self.get_dashboard_url(profile)
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def requires_pin_change(self, profile):
        """Check if profile requires PIN change (first login)"""
        # If last_login was just set and created_at is recent, likely first login
        time_diff = timezone.now() - profile.created_at
        return time_diff.total_seconds() < 300  # 5 minutes threshold
    
    def get_dashboard_url(self, profile):
        """Get appropriate dashboard URL based on profile type"""
        if profile.profile_type == 'BIZ':
            return '/dashboard/business'
        else:
            return '/dashboard/personal'


class PINChangeView(APIView):
    """
    API endpoint for PIN change functionality.
    Handles both first-time setup and regular PIN updates.
    """
    permission_classes = [AllowAny]  # Change to IsAuthenticated when session management is implemented
    
    def post(self, request):
        serializer = PINChangeSerializer(data=request.data)
        
        if serializer.is_valid():
            profile_id = request.data.get('profile_id')
            
            try:
                profile = Profile.objects.get(id=profile_id, is_active=True)
                current_pin = serializer.validated_data['current_pin']
                
                # Verify current PIN
                if not profile.verify_pin(current_pin):
                    return Response(
                        {'error': 'Current PIN is incorrect.'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                # Set new PIN
                new_pin = serializer.validated_data['new_pin']
                profile.set_pin(new_pin)
                
                return Response({
                    'message': 'PIN changed successfully',
                    'redirect_to_dashboard': True,
                    'dashboard_url': self.get_dashboard_url(profile)
                })
                
            except Profile.DoesNotExist:
                return Response(
                    {'error': 'Profile not found.'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def get_dashboard_url(self, profile):
        """Get appropriate dashboard URL based on profile type"""
        if profile.profile_type == 'BIZ':
            return '/dashboard/business'
        else:
            return '/dashboard/personal'


class EmailCredentialsView(APIView):
    """
    API endpoint for requesting credentials via email.
    Used when user forgets their profile ID or PIN.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = EmailCredentialsSerializer(data=request.data)
        
        if serializer.is_valid():
            email = serializer.validated_data['email']
            
            # In a real implementation, you'd search for profiles associated with this email
            # For now, we'll send a generic response to prevent email enumeration
            
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
                    'message': 'If an account exists with this email, credentials have been sent.'
                })
                
            except Exception as e:
                return Response(
                    {'error': 'Failed to send email. Please try again later.'}, 
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DashboardView(APIView):
    """
    API endpoint for dashboard data.
    Returns profile-specific dashboard information.
    """
    permission_classes = [AllowAny]  # Change to IsAuthenticated when session management is implemented
    
    def get(self, request):
        profile_id = request.query_params.get('profile_id')
        
        if not profile_id:
            return Response(
                {'error': 'Profile ID required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            profile = Profile.objects.get(id=profile_id, is_active=True)
            
            dashboard_data = {
                'profile': ProfileSerializer(profile).data,
                'dashboard_type': 'business' if profile.profile_type == 'BIZ' else 'personal',
                'quick_stats': self.get_quick_stats(profile),
                'recent_activity': self.get_recent_activity(profile),
                'available_features': self.get_available_features(profile)
            }
            
            return Response(dashboard_data)
            
        except Profile.DoesNotExist:
            return Response(
                {'error': 'Profile not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
    
    def get_quick_stats(self, profile):
        """Get quick statistics for dashboard"""
        # Placeholder - implement based on your transaction models
        return {
            'total_balance': 0,
            'monthly_income': 0,
            'monthly_expenses': 0,
            'active_goals': 0
        }
    
    def get_recent_activity(self, profile):
        """Get recent activity for dashboard"""
        # Placeholder - implement based on your transaction models
        return []
    
    def get_available_features(self, profile):
        """Get available features based on profile type"""
        if profile.profile_type == 'BIZ':
            return [
                'invoicing', 'client_management', 'tax_preparation',
                'cash_flow_analysis', 'business_expenses', 'asset_management'
            ]
        else:
            return [
                'budget_tracking', 'goal_setting', 'expense_categorization',
                'savings_tracking', 'personal_loans', 'investment_tracking'
            ]


# Legacy views for backward compatibility
class ProfileListCreateView(generics.ListCreateAPIView):
    queryset = Profile.objects.filter(is_active=True)
    serializer_class = ProfileSerializer
    permission_classes = [AllowAny]  # Change to IsAuthenticated when session management is implemented

    def perform_create(self, serializer):
        # Hash PIN before saving
        pin = self.request.data.get('pin')
        if pin:
            serializer.save(pin_hash=Profile.hash_pin(pin))


class ProfileDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [AllowAny]  # Change to IsAuthenticated when session management is implemented

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save()


# API endpoint for checking authentication status
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
# backend_v1/accounts/views.py

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import Profile
from .serializers import ProfileSerializer, RegisterSerializer
import logging

logger = logging.getLogger('accounts')


class RegisterView(APIView):
    """User registration - No authentication required"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            logger.info(f"Registration attempt for: {request.data.get('email')}")
            
            serializer = RegisterSerializer(data=request.data)
            
            if serializer.is_valid():
                user = serializer.save()
                logger.info(f"User created: {user.email}")
                
                # Generate JWT token
                refresh = RefreshToken.for_user(user)
                
                response_data = {
                    'success': True,
                    'status': 201,
                    'token': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': {
                        'id': str(user.id),
                        'email': user.email,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                    }
                }
                
                logger.info(f"Registration successful for: {user.email}")
                return Response(response_data, status=status.HTTP_201_CREATED)
            
            # Validation errors
            logger.error(f"Validation errors: {serializer.errors}")
            return Response({
                'success': False,
                'status': 400,
                'error': str(serializer.errors)
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Registration error: {str(e)}", exc_info=True)
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LoginView(APIView):
    """User login - No authentication required"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            email = request.data.get('email')
            password = request.data.get('password')
            
            logger.info(f"Login attempt for: {email}")
            
            if not email or not password:
                return Response({
                    'success': False,
                    'error': 'Email and password are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Authenticate user
            user = authenticate(request, username=email, password=password)
            
            if user is not None:
                # Generate JWT token
                refresh = RefreshToken.for_user(user)
                
                response_data = {
                    'success': True,
                    'token': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': {
                        'id': str(user.id),
                        'email': user.email,
                        'first_name': user.first_name,
                        'last_name': user.last_name,
                    }
                }
                
                logger.info(f"Login successful for: {user.email}")
                return Response(response_data, status=status.HTTP_200_OK)
            
            else:
                logger.warning(f"Failed login attempt for: {email}")
                return Response({
                    'success': False,
                    'error': 'Invalid email or password',
                    'detail': 'No active account found with the given credentials'
                }, status=status.HTTP_401_UNAUTHORIZED)
                
        except Exception as e:
            logger.error(f"Login error: {str(e)}", exc_info=True)
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LogoutView(APIView):
    """User logout - Requires authentication"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            # Optionally blacklist the refresh token
            refresh_token = request.data.get('refresh')
            if refresh_token:
                try:
                    token = RefreshToken(refresh_token)
                    token.blacklist()
                except Exception:
                    pass  # Token already blacklisted or invalid
            
            logger.info(f"User logged out: {request.user.email}")
            return Response({
                'success': True,
                'message': 'Logged out successfully'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Logout error: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ProfileView(APIView):
    """Get/Update user profile - Requires authentication"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            serializer = ProfileSerializer(request.user)
            
            return Response({
                'success': True,
                'profile': serializer.data,
                # Also return profile data at root level for compatibility
                **serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Profile fetch error: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    def patch(self, request):
        """Update user profile"""
        try:
            serializer = ProfileSerializer(
                request.user, 
                data=request.data, 
                partial=True
            )
            
            if serializer.is_valid():
                serializer.save()
                
                return Response({
                    'success': True,
                    'profile': serializer.data
                }, status=status.HTTP_200_OK)
            
            return Response({
                'success': False,
                'error': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Profile update error: {str(e)}")
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


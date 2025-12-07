# backend/api/views.py
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
from django.utils import timezone
from .serializers import UserRegistrationSerializer, UserLoginSerializer, ProfileSerializer, PasswordValidator
from .models import Profile

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Register a new user account with SHA-256 password hashing"""
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        user = serializer.save()
        # Get profile by email
        profile = Profile.objects.get(email=user.email)
        
        # Create auth token
        token, created = Token.objects.get_or_create(user=user)
        
        # Update last login
        user.last_login = timezone.now()
        user.save()
        profile.last_login = timezone.now()
        profile.save()
        
        return Response({
            'success': True,
            'token': token.key,
            'profile': ProfileSerializer(profile).data,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
            }
        }, status=status.HTTP_201_CREATED)
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """Authenticate user with SHA-256 password verification"""
    serializer = UserLoginSerializer(data=request.data)
    
    if not serializer.is_valid():
        return Response({
            'success': False,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    user = serializer.validated_data['user']
    profile = serializer.validated_data['profile']
    
    # Update last login
    user.last_login = timezone.now()
    user.save()
    profile.last_login = timezone.now()
    profile.save()
    
    # Get or create token
    token, created = Token.objects.get_or_create(user=user)
    
    return Response({
        'success': True,
        'token': token.key,
        'profile': ProfileSerializer(profile).data,
        'user': {
            'id': user.id,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
        }
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """Logout user by deleting their token"""
    request.user.auth_token.delete()
    return Response({
        'success': True,
        'message': 'Logged out successfully'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_profile(request):
    """Fetch complete profile data for logged-in user"""
    try:
        # Find profile by user email
        profile = Profile.objects.get(email=request.user.email)
        return Response({
            'success': True,
            'profile': ProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)
    except Profile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Profile not found'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_profile(request):
    """Update user profile data"""
    try:
        # Find profile by user email
        profile = Profile.objects.get(email=request.user.email)
    except Profile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Profile not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    serializer = ProfileSerializer(profile, data=request.data, partial=True)
    if serializer.is_valid():
        profile = serializer.save()
        profile.last_modified = timezone.now()
        profile.save()
        
        return Response({
            'success': True,
            'profile': ProfileSerializer(profile).data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """Change user password"""
    current_password = request.data.get('current_password')
    new_password = request.data.get('new_password')
    
    if not current_password or not new_password:
        return Response({
            'success': False,
            'error': 'current_password and new_password are required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Find profile by user email
        profile = Profile.objects.get(email=request.user.email)
    except Profile.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Profile not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Verify current password
    if not PasswordValidator.verify_password(current_password, profile.password_hash):
        return Response({
            'success': False,
            'error': 'Current password is incorrect'
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # Validate new password
    try:
        PasswordValidator.validate(new_password)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Update password hash
    profile.password_hash = PasswordValidator.hash_password(new_password)
    profile.save()
    
    return Response({
        'success': True,
        'message': 'Password changed successfully'
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Health check endpoint"""
    return Response({
        'status': 'ok',
        'message': 'Fedha backend server is running'
    }, status=status.HTTP_200_OK)
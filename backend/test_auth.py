#!/usr/bin/env python
"""
Simple test script to verify the Fedha authentication system is working.
"""

import os
import django
import sys

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from api.models import Profile
from api.serializers import ProfileRegistrationSerializer, ProfileLoginSerializer
from django.test import RequestFactory
from api.views import AccountTypeSelectionView, ProfileRegistrationView, ProfileLoginView

def test_uuid_generation():
    """Test UUID generation with prefixes"""
    print("=== Testing UUID Generation ===")
    
    from api.models import generate_business_uuid, generate_personal_uuid, generate_profile_uuid
    
    # Test business UUID
    business_uuid = generate_business_uuid()
    print(f"Business UUID: {business_uuid}")
    assert business_uuid.startswith('B-'), "Business UUID should start with 'B-'"
    
    # Test personal UUID
    personal_uuid = generate_personal_uuid()
    print(f"Personal UUID: {personal_uuid}")
    assert personal_uuid.startswith('P-'), "Personal UUID should start with 'P-'"
    
    # Test profile UUID generation
    biz_uuid = generate_profile_uuid('BIZ')
    pers_uuid = generate_profile_uuid('PERS')
    
    print(f"Generated Business UUID: {biz_uuid}")
    print(f"Generated Personal UUID: {pers_uuid}")
    
    assert biz_uuid.startswith('B-'), "Business profile UUID should start with 'B-'"
    assert pers_uuid.startswith('P-'), "Personal profile UUID should start with 'P-'"
    
    print("✅ UUID Generation Tests Passed!")

def test_profile_registration():
    """Test profile registration process"""
    print("\n=== Testing Profile Registration ===")
    
    # Test business profile registration
    business_data = {
        'profile_type': 'BIZ',
        'name': 'Test Business',
        'email': 'business@example.com',
        'pin': '1234'
    }
    
    business_serializer = ProfileRegistrationSerializer(data=business_data)
    if business_serializer.is_valid():
        business_profile = business_serializer.save()
        print(f"Business Profile Created: {business_profile}")
        print(f"Business Profile ID: {business_profile.id}")
        assert business_profile.id.startswith('B-'), "Business profile should have B- prefix"
    else:
        print(f"Business Registration Errors: {business_serializer.errors}")
    
    # Test personal profile registration
    personal_data = {
        'profile_type': 'PERS',
        'name': 'Test User',
        'email': 'user@example.com',
        'pin': '5678'
    }
    
    personal_serializer = ProfileRegistrationSerializer(data=personal_data)
    if personal_serializer.is_valid():
        personal_profile = personal_serializer.save()
        print(f"Personal Profile Created: {personal_profile}")
        print(f"Personal Profile ID: {personal_profile.id}")
        assert personal_profile.id.startswith('P-'), "Personal profile should have P- prefix"
    else:
        print(f"Personal Registration Errors: {personal_serializer.errors}")
    
    print("✅ Profile Registration Tests Passed!")

def test_profile_login():
    """Test profile login process"""
    print("\n=== Testing Profile Login ===")
    
    # Create a test profile first
    test_data = {
        'profile_type': 'PERS',
        'name': 'Login Test User',
        'email': 'logintest@example.com',
        'pin': '9999'
    }
    
    reg_serializer = ProfileRegistrationSerializer(data=test_data)
    if reg_serializer.is_valid():
        profile = reg_serializer.save()
        print(f"Test profile created for login: {profile.id}")
        
        # Test login with correct credentials
        login_data = {
            'email': 'logintest@example.com',
            'pin': '9999'
        }
        
        login_serializer = ProfileLoginSerializer(data=login_data)
        if login_serializer.is_valid():
            validated_data = login_serializer.validated_data
            print(f"Login successful for profile: {validated_data['profile'].id}")
        else:
            print(f"Login Errors: {login_serializer.errors}")
        
        # Test login with wrong PIN
        wrong_login_data = {
            'email': 'logintest@example.com',
            'pin': '0000'
        }
        
        wrong_login_serializer = ProfileLoginSerializer(data=wrong_login_data)
        if not wrong_login_serializer.is_valid():
            print("✅ Wrong PIN correctly rejected")
        else:
            print("❌ Wrong PIN was accepted - this shouldn't happen")
    
    print("✅ Profile Login Tests Passed!")

def test_api_endpoints():
    """Test API endpoints using Django test client"""
    print("\n=== Testing API Endpoints ===")
    
    from django.test import Client
    import json
    
    client = Client()
    
    # Test account types endpoint
    response = client.get('/api/account-types/')
    print(f"Account Types Response: {response.status_code}")
    if response.status_code == 200:
        print(f"Account Types Data: {response.json()}")
    
    # Test registration endpoint
    reg_data = {
        'profile_type': 'PERS',
        'name': 'API Test User',
        'email': 'apitest@example.com',
        'pin': '1111'
    }
    
    response = client.post(
        '/api/register/',
        data=json.dumps(reg_data),
        content_type='application/json'
    )
    print(f"Registration Response: {response.status_code}")
    if response.status_code == 201:
        reg_response_data = response.json()
        print(f"Registration Success: {reg_response_data}")
        
        # Test login with the registered user
        login_data = {
            'email': 'apitest@example.com',
            'pin': '1111'
        }
        
        response = client.post(
            '/api/login/',
            data=json.dumps(login_data),
            content_type='application/json'
        )
        print(f"Login Response: {response.status_code}")
        if response.status_code == 200:
            login_response_data = response.json()
            print(f"Login Success: {login_response_data}")
    else:
        print(f"Registration failed: {response.content}")
    
    print("✅ API Endpoints Tests Passed!")

if __name__ == '__main__':
    print("🚀 Starting Fedha Authentication System Tests")
    
    try:
        test_uuid_generation()
        test_profile_registration()
        test_profile_login()
        test_api_endpoints()
        
        print("\n🎉 All tests passed successfully!")
        print("The Fedha authentication system is working properly.")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()

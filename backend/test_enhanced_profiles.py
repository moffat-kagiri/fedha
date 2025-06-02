#!/usr/bin/env python
"""
Test script for Enhanced Profile endpoints
Tests the new 8-digit user ID functionality
"""

import os
import sys
import django
import requests
import json

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from api.models import Profile

def test_enhanced_profile_api():
    """Test the enhanced profile API endpoints"""
    
    # Test server is running on localhost:8000
    base_url = "http://localhost:8000/api"
    
    print("=== Testing Enhanced Profile API ===\n")
    
    # Test 1: Create a new enhanced profile
    print("1. Testing Enhanced Profile Registration...")
    registration_data = {
        "name": "Test Business User",
        "profile_type": "business",
        "pin": "1234",
        "email": "test@business.com",
        "base_currency": "KES",
        "timezone": "GMT+3"
    }
    
    try:
        response = requests.post(f"{base_url}/enhanced/register/", json=registration_data)
        print(f"Registration Status: {response.status_code}")
        
        if response.status_code == 201:
            registration_result = response.json()
            print(f"✅ Registration successful!")
            print(f"   User ID: {registration_result.get('user_id')}")
            print(f"   Profile ID: {registration_result.get('profile_id')}")
            print(f"   Name: {registration_result.get('name')}")
            
            # Store user_id for next test
            user_id = registration_result.get('user_id')
            
        else:
            print(f"❌ Registration failed: {response.text}")
            return
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to server. Please start the Django server first:")
        print("   python manage.py runserver 8000")
        return
    except Exception as e:
        print(f"❌ Registration error: {e}")
        return
    
    print()
    
    # Test 2: Login with the created profile
    print("2. Testing Enhanced Profile Login...")
    login_data = {
        "user_id": user_id,
        "pin": "1234"
    }
    
    try:
        response = requests.post(f"{base_url}/enhanced/login/", json=login_data)
        print(f"Login Status: {response.status_code}")
        
        if response.status_code == 200:
            login_result = response.json()
            print(f"✅ Login successful!")
            print(f"   Profile: {login_result.get('profile', {}).get('name')}")
            print(f"   Type: {login_result.get('profile', {}).get('profile_type')}")
            print(f"   Last Login: {login_result.get('profile', {}).get('last_login')}")
        else:
            print(f"❌ Login failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Login error: {e}")
    
    print()
    
    # Test 3: Validate profile exists
    print("3. Testing Profile Validation...")
    validation_data = {
        "user_id": user_id
    }
    
    try:
        response = requests.post(f"{base_url}/enhanced/validate/", json=validation_data)
        print(f"Validation Status: {response.status_code}")
        
        if response.status_code == 200:
            validation_result = response.json()
            print(f"✅ Validation successful!")
            print(f"   Exists: {validation_result.get('exists')}")
            print(f"   Profile Type: {validation_result.get('profile_type')}")
            print(f"   Name: {validation_result.get('name')}")
        else:
            print(f"❌ Validation failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Validation error: {e}")
    
    print()
    
    # Test 4: Sync profile data
    print("4. Testing Profile Sync (Download)...")
    
    try:
        response = requests.get(f"{base_url}/enhanced/sync/?user_id={user_id}")
        print(f"Sync Status: {response.status_code}")
        
        if response.status_code == 200:
            sync_result = response.json()
            print(f"✅ Sync successful!")
            profile_data = sync_result.get('profile', {})
            print(f"   User ID: {profile_data.get('user_id')}")
            print(f"   Name: {profile_data.get('name')}")
            print(f"   Type: {profile_data.get('profile_type')}")
            print(f"   Currency: {profile_data.get('base_currency')}")
        else:
            print(f"❌ Sync failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Sync error: {e}")
    
    print()
    
    # Test 5: Test wrong PIN
    print("5. Testing Wrong PIN...")
    wrong_login_data = {
        "user_id": user_id,
        "pin": "9999"
    }
    
    try:
        response = requests.post(f"{base_url}/enhanced/login/", json=wrong_login_data)
        print(f"Wrong PIN Status: {response.status_code}")
        
        if response.status_code == 401:
            print(f"✅ Correctly rejected wrong PIN")
        else:
            print(f"❌ Unexpected response: {response.text}")
            
    except Exception as e:
        print(f"❌ Wrong PIN test error: {e}")
    
    print()
    print("=== Enhanced Profile API Test Complete ===")


def test_direct_model():
    """Test the Profile model directly"""
    
    print("\n=== Testing Profile Model Directly ===\n")
    
    # Test 1: Create profile using model
    print("1. Testing Profile Model Creation...")
    
    try:
        # Generate user_id
        user_id = Profile.generate_user_id()
        print(f"Generated User ID: {user_id}")
        
        # Create profile
        profile = Profile(
            user_id=user_id,
            name="Direct Model Test",
            email="direct@test.com",
            profile_type=Profile.ProfileType.PERSONAL,
            base_currency="USD",
            timezone="UTC"
        )
        
        # Set PIN
        profile.set_pin("5678")
        
        # Save profile
        profile.save()
        
        print(f"✅ Profile created successfully!")
        print(f"   ID: {profile.id}")
        print(f"   User ID: {profile.user_id}")
        print(f"   Type: {profile.get_profile_type_display()}")
        print(f"   Is Business: {profile.is_business}")
        print(f"   Date Created: {profile.date_created}")
        
        # Test PIN verification
        print("\n2. Testing PIN Verification...")
        if profile.verify_pin("5678"):
            print("✅ Correct PIN verified successfully")
        else:
            print("❌ Correct PIN verification failed")
            
        if not profile.verify_pin("0000"):
            print("✅ Wrong PIN correctly rejected")
        else:
            print("❌ Wrong PIN was incorrectly accepted")
            
    except Exception as e:
        print(f"❌ Model test error: {e}")
    
    print("\n=== Profile Model Test Complete ===")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "model":
        test_direct_model()
    else:
        print("Enhanced Profile API Test Script")
        print("=" * 50)
        print("This script tests the enhanced profile functionality")
        print("with 8-digit user IDs and cross-device support.")
        print()
        print("Options:")
        print("  python test_enhanced_profiles.py        - Test API endpoints")
        print("  python test_enhanced_profiles.py model  - Test model directly")
        print()
        
        if len(sys.argv) > 1 and sys.argv[1] == "api":
            test_enhanced_profile_api()
        elif len(sys.argv) > 1 and sys.argv[1] == "model":
            test_direct_model()
        else:
            # Default to model test since it doesn't require server
            test_direct_model()

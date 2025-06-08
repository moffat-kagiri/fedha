#!/usr/bin/env python
"""
Test script for Fedha Backend API endpoints
"""
import os
import sys
import django
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.test import Client
from django.urls import reverse
import json

def test_calculator_endpoints():
    """Test the calculator API endpoints"""
    client = Client()
    
    print("Testing Financial Calculator API Endpoints...")
    print("=" * 50)
    
    # Test data for loan calculation
    loan_data = {
        'principal': 100000,
        'annual_rate': 5.0,
        'term_years': 30,
        'interest_type': 'compound',
        'payment_frequency': 'monthly'
    }
    
    # Test Loan Calculator
    print("\n1. Testing Loan Calculator...")
    try:
        response = client.post(
            '/api/calculators/loan/',
            data=json.dumps(loan_data),
            content_type='application/json'
        )
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        else:
            print(f"Error: {response.content.decode()}")
    except Exception as e:
        print(f"Exception: {e}")
    
    # Test Interest Rate Solver
    print("\n2. Testing Interest Rate Solver...")
    rate_data = {
        'principal': 100000,
        'payment': 536.82,
        'term_years': 30,
        'payment_frequency': 'monthly'
    }
    try:
        response = client.post(
            '/api/calculators/interest-rate-solver/',
            data=json.dumps(rate_data),
            content_type='application/json'
        )
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        else:
            print(f"Error: {response.content.decode()}")
    except Exception as e:
        print(f"Exception: {e}")
    
    # Test ROI Calculator
    print("\n3. Testing ROI Calculator...")
    roi_data = {
        'initial_investment': 10000,
        'final_value': 15000,
        'time_years': 5
    }
    try:
        response = client.post(
            '/api/calculators/roi/',
            data=json.dumps(roi_data),
            content_type='application/json'
        )
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        else:
            print(f"Error: {response.content.decode()}")
    except Exception as e:
        print(f"Exception: {e}")

def test_profile_endpoints():
    """Test the profile API endpoints"""
    client = Client()
    
    print("\n\nTesting Profile API Endpoints...")
    print("=" * 50)
    
    # Test Account Type Selection
    print("\n1. Testing Account Type Selection...")
    try:
        response = client.get('/api/account-type-selection/')
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print(f"Response: {response.json()}")
        else:
            print(f"Error: {response.content.decode()}")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    print("Fedha Backend API Test Suite")
    print("=" * 50)
    
    test_profile_endpoints()
    test_calculator_endpoints()
    
    print("\n" + "=" * 50)
    print("Test completed!")

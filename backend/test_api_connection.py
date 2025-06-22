#!/usr/bin/env python
"""
Quick test script to verify the loan calculator API is working
"""
import json
import requests

def test_health_endpoint():
    """Test the health endpoint"""
    try:
        response = requests.get('http://127.0.0.1:8000/api/health/')
        print(f"Health endpoint status: {response.status_code}")
        print(f"Health response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health endpoint error: {e}")
        return False

def test_loan_calculator():
    """Test the loan calculator endpoint"""
    try:
        data = {
            'principal': 100000.0,
            'annual_rate': 7.5,
            'term_years': 5,
            'interest_type': 'compound',
            'payment_frequency': 'monthly',
        }
        
        response = requests.post(
            'http://127.0.0.1:8000/api/calculators/loan/',
            headers={'Content-Type': 'application/json'},
            data=json.dumps(data)
        )
        
        print(f"Loan calculator status: {response.status_code}")
        print(f"Loan calculator response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Loan calculator error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Fedha API endpoints...")
    print("=" * 40)
    
    health_ok = test_health_endpoint()
    loan_ok = test_loan_calculator()
    
    print("=" * 40)
    print(f"Health endpoint: {'✓' if health_ok else '✗'}")
    print(f"Loan calculator: {'✓' if loan_ok else '✗'}")
    
    if health_ok and loan_ok:
        print("\n✓ All API endpoints are working!")
    else:
        print("\n✗ Some API endpoints have issues.")

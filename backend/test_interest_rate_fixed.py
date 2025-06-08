#!/usr/bin/env python3
"""
Test Interest Rate Solver with realistic data
"""

import json
import requests

BASE_URL = "http://127.0.0.1:8000/api/calculators"
HEADERS = {"Content-Type": "application/json"}

def test_interest_rate_solver():
    """Test interest rate solver with realistic data"""
    print("=== Testing Interest Rate Solver with Realistic Data ===")
    
    # Test Case 1: Known scenario - should converge to around 6% annual rate
    # $50,000 loan, $555.10 monthly payment, 10 years
    data = {
        "principal": 50000.00,
        "payment": 555.10,
        "term_years": 10,
        "payment_frequency": "MONTHLY",
        "tolerance": 0.0001,
        "max_iterations": 100
    }
    
    try:
        response = requests.post(f"{BASE_URL}/interest-rate-solver/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Interest Rate Solver Success!")
            print(f"Annual Rate: {result['annual_rate']}%")
            print(f"Converged: {result['converged']}")
            print(f"Iterations: {result['iterations']}")
        else:
            print(f"❌ Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test Case 2: Another known scenario
    print("\n=== Test Case 2: Different Parameters ===")
    data2 = {
        "principal": 200000.00,
        "payment": 1687.71,
        "term_years": 15,
        "payment_frequency": "MONTHLY",
        "tolerance": 0.0001,
        "max_iterations": 100
    }
    
    try:
        response = requests.post(f"{BASE_URL}/interest-rate-solver/", headers=HEADERS, json=data2)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Interest Rate Solver Success!")
            print(f"Annual Rate: {result['annual_rate']}%")
            print(f"Converged: {result['converged']}")
            print(f"Iterations: {result['iterations']}")
        else:
            print(f"❌ Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_interest_rate_solver()

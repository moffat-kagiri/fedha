#!/usr/bin/env python3
"""
Test Interest Rate Solver specifically
"""

import json
import requests

BASE_URL = "http://127.0.0.1:8000/api/calculators"
HEADERS = {"Content-Type": "application/json"}

def test_interest_rate_solver():
    """Test interest rate solver"""
    print("=== Testing Interest Rate Solver ===")
    
    data = {
        "principal": 100000.00,
        "payment": 1000.00,
        "term_years": 10,
        "payment_frequency": "MONTHLY",
        "initial_guess": 5.0,
        "tolerance": 0.00001,
        "max_iterations": 100
    }
    
    try:
        response = requests.post(f"{BASE_URL}/interest-rate-solver/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Interest Rate Solver Success!")
            print(f"Annual Rate: {result.get('annual_rate', 'N/A')}%")
            print(f"Converged: {result.get('converged', 'N/A')}")
            print(f"Iterations: {result.get('iterations', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    test_interest_rate_solver()

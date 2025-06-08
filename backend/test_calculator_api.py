#!/usr/bin/env python3
"""
Test script for Financial Calculator API endpoints
Tests all calculator functionality to ensure proper integration
"""

import requests
import json
import sys
from decimal import Decimal

# API Base URL
BASE_URL = "http://127.0.0.1:8000/api"

def test_endpoint(endpoint, data, description):
    """Test a single API endpoint"""
    print(f"\n{'='*60}")
    print(f"Testing: {description}")
    print(f"Endpoint: {endpoint}")
    print(f"Data: {json.dumps(data, indent=2)}")
    print(f"{'='*60}")
    
    response = None
    try:
        response = requests.post(f"{BASE_URL}/{endpoint}/", json=data, timeout=30)
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ SUCCESS")
            print(f"Response: {json.dumps(result, indent=2)}")
            return True
        else:
            print("❌ FAILED")
            print(f"Error Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ REQUEST ERROR: {e}")
    except json.JSONDecodeError as e:
        print(f"❌ JSON DECODE ERROR: {e}")
        if response:
            print(f"Raw response: {response.text}")
        return False
        return False

def run_calculator_tests():
    """Run comprehensive tests for all calculator endpoints"""
    
    print("🧮 FINANCIAL CALCULATOR API TEST SUITE")
    print("Testing all calculator endpoints...")
    
    test_results = []
    
    # Test 1: Loan Payment Calculation
    loan_data = {
        "principal": 100000.00,
        "annual_rate": 5.5,
        "term_years": 30,
        "interest_type": "reducing_balance",
        "payment_frequency": "monthly"
    }
    
    result = test_endpoint(
        "calculators/loan-payment",
        loan_data,
        "Loan Payment Calculation - $100k, 5.5%, 30 years"
    )
    test_results.append(("Loan Payment", result))
    
    # Test 2: Interest Rate Solver
    rate_solver_data = {
        "principal": 100000.00,
        "payment": 567.79,
        "term_years": 30,
        "payment_frequency": "monthly",
        "tolerance": 0.00001,
        "max_iterations": 100
    }
    
    result = test_endpoint(
        "calculators/interest-rate-solver",
        rate_solver_data,
        "Interest Rate Solver - Find rate for $567.79 payment"
    )
    test_results.append(("Interest Rate Solver", result))
    
    # Test 3: Amortization Schedule
    amortization_data = {
        "principal": 100000.00,
        "annual_rate": 5.5,
        "term_years": 5,  # Shorter term for testing
        "payment_frequency": "monthly"
    }
    
    result = test_endpoint(
        "calculators/amortization-schedule",
        amortization_data,
        "Amortization Schedule - $100k, 5.5%, 5 years"
    )
    test_results.append(("Amortization Schedule", result))
    
    # Test 4: Early Payment Calculator
    early_payment_data = {
        "principal": 200000.00,
        "annual_rate": 4.5,
        "term_years": 30,
        "extra_payment": 200.00,
        "payment_frequency": "monthly",
        "extra_payment_type": "monthly"
    }
    
    result = test_endpoint(
        "calculators/early-payment",
        early_payment_data,
        "Early Payment Calculator - $200 extra monthly"
    )
    test_results.append(("Early Payment Calculator", result))
    
    # Test 5: ROI Calculator
    roi_data = {
        "initial_investment": 10000.00,
        "final_value": 15000.00,
        "time_years": 3.0
    }
    
    result = test_endpoint(
        "calculators/roi",
        roi_data,
        "ROI Calculator - $10k to $15k over 3 years"
    )
    test_results.append(("ROI Calculator", result))
    
    # Test 6: Compound Interest Calculator
    compound_data = {
        "principal": 5000.00,
        "annual_rate": 7.0,
        "time_years": 10.0,
        "compounding_frequency": "monthly",
        "additional_payment": 200.00,
        "additional_frequency": "monthly"
    }
    
    result = test_endpoint(
        "calculators/compound-interest",
        compound_data,
        "Compound Interest - $5k principal, $200/month additional"
    )
    test_results.append(("Compound Interest", result))
    
    # Test 7: Portfolio Metrics
    portfolio_data = {
        "investments": [
            {"shares": 100, "purchase_price": 50.00, "current_price": 65.00},
            {"shares": 50, "purchase_price": 80.00, "current_price": 75.00},
            {"shares": 200, "purchase_price": 25.00, "current_price": 30.00}
        ]
    }
    
    result = test_endpoint(
        "calculators/portfolio-metrics",
        portfolio_data,
        "Portfolio Metrics - 3 investment portfolio"
    )
    test_results.append(("Portfolio Metrics", result))
    
    # Test 8: Risk Assessment
    risk_data = {
        "answers": [3, 4, 2, 3, 4, 3, 2]  # Sample risk tolerance answers
    }
    
    result = test_endpoint(
        "calculators/risk-assessment",
        risk_data,
        "Risk Assessment - Investment risk profile"
    )
    test_results.append(("Risk Assessment", result))
    
    # Print Summary
    print(f"\n{'='*60}")
    print("📊 TEST SUMMARY")
    print(f"{'='*60}")
    
    passed = sum(1 for _, result in test_results if result)
    total = len(test_results)
    
    for test_name, result in test_results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:<25} {status}")
    
    print(f"\nOverall Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! API is working correctly.")
        return True
    else:
        print(f"⚠️  {total - passed} tests failed. Check the errors above.")
        return False

if __name__ == "__main__":
    print("Starting Financial Calculator API Tests...")
    print("Make sure Django server is running on http://127.0.0.1:8000")
    
    try:
        # Test server connectivity
        response = requests.get(f"{BASE_URL}/", timeout=5)
        print(f"✅ Server is accessible (Status: {response.status_code})")
    except requests.exceptions.RequestException:
        print("❌ Cannot connect to Django server. Make sure it's running.")
        sys.exit(1)
    
    success = run_calculator_tests()
    sys.exit(0 if success else 1)

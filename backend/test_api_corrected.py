#!/usr/bin/env python3
"""
CORRECTED Financial Calculator API Test Suite
Tests all calculator functionality with correct endpoint paths and field values
"""

import requests
import json
import sys

# API Base URL
BASE_URL = "http://127.0.0.1:8000/api"

def test_endpoint(endpoint, data, description):
    """Test a single API endpoint"""
    print(f"\n{'='*60}")
    print(f"Testing: {description}")
    print(f"Endpoint: {endpoint}")
    print(f"Data: {json.dumps(data, indent=2)}")
    print(f"{'='*60}")
    
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
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def test_payment_accuracy():
    """Test payment calculation accuracy against our verified results"""
    print("\n🔍 TESTING PAYMENT CALCULATION ACCURACY")
    
    # Test the exact case from our accuracy verification: $200k, 4.5%, 30 years
    test_data = {
        "principal": 200000.00,
        "annual_rate": 4.5,
        "term_years": 30,
        "interest_type": "REDUCING",
        "payment_frequency": "MONTHLY"
    }
    
    print(f"Testing: $200,000 loan at 4.5% for 30 years")
    print(f"Expected payment: $1013.37 (from verified accuracy tests)")
    
    try:
        response = requests.post(f"{BASE_URL}/calculators/loan/", json=test_data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            payment = float(result.get('payment_amount', 0))
            print(f"✅ API Payment: ${payment:.2f}")
            
            # Check accuracy within $0.01
            expected = 1013.37
            if abs(payment - expected) < 0.01:
                print(f"✅ ACCURACY VERIFIED: Payment exactly matches expected value!")
                return True
            else:
                print(f"❌ ACCURACY ISSUE: Expected ${expected:.2f}, got ${payment:.2f}")
                return False
        else:
            print(f"❌ API ERROR: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ TEST ERROR: {e}")
        return False

def run_all_tests():
    """Run all API endpoint tests"""
    print("🧮 FINANCIAL CALCULATOR API TEST SUITE (CORRECTED)")
    
    test_results = []
    
    # Test 1: Loan Payment Calculation
    result = test_endpoint(
        "calculators/loan",
        {
            "principal": 100000.00,
            "annual_rate": 5.5,
            "term_years": 30,
            "interest_type": "REDUCING",
            "payment_frequency": "MONTHLY"
        },
        "Loan Payment Calculation - $100k, 5.5%, 30 years"
    )
    test_results.append(("Loan Payment", result))
    
    # Test 2: Interest Rate Solver
    result = test_endpoint(
        "calculators/interest-rate-solver",
        {
            "principal": 100000.00,
            "payment": 567.79,
            "term_years": 30,
            "payment_frequency": "MONTHLY"
        },
        "Interest Rate Solver - Find rate for $567.79 payment"
    )
    test_results.append(("Interest Rate Solver", result))
    
    # Test 3: Amortization Schedule
    result = test_endpoint(
        "calculators/amortization-schedule",
        {
            "principal": 100000.00,
            "annual_rate": 5.5,
            "term_years": 5,
            "payment_frequency": "MONTHLY"
        },
        "Amortization Schedule - $100k, 5.5%, 5 years"
    )
    test_results.append(("Amortization Schedule", result))
    
    # Test 4: Early Payment Calculator
    result = test_endpoint(
        "calculators/early-payment",
        {
            "principal": 200000.00,
            "annual_rate": 4.5,
            "term_years": 30,
            "extra_payment": 200.00,
            "payment_frequency": "MONTHLY",
            "extra_payment_type": "MONTHLY"
        },
        "Early Payment Calculator - $200 extra monthly"
    )
    test_results.append(("Early Payment", result))
    
    # Test 5: ROI Calculator
    result = test_endpoint(
        "calculators/roi",
        {
            "initial_investment": 10000.00,
            "final_value": 15000.00,
            "time_years": 3.0
        },
        "ROI Calculator - $10k to $15k over 3 years"
    )
    test_results.append(("ROI Calculator", result))
    
    # Test 6: Compound Interest
    result = test_endpoint(
        "calculators/compound-interest",
        {
            "principal": 5000.00,
            "annual_rate": 7.0,
            "time_years": 10.0,
            "compounding_frequency": "MONTHLY",
            "additional_payment": 200.00,
            "additional_frequency": "MONTHLY"
        },
        "Compound Interest - $5k principal, $200/month"
    )
    test_results.append(("Compound Interest", result))
    
    # Test 7: Portfolio Metrics
    result = test_endpoint(
        "calculators/portfolio-metrics",
        {
            "investments": [
                {"shares": 100, "purchase_price": 50.00, "current_price": 65.00},
                {"shares": 50, "purchase_price": 80.00, "current_price": 75.00}
            ]
        },
        "Portfolio Metrics - 2 investment portfolio"
    )
    test_results.append(("Portfolio Metrics", result))
    
    # Test 8: Risk Assessment
    result = test_endpoint(
        "calculators/risk-assessment",
        {
            "answers": [3, 4, 2, 3, 4, 3, 2]
        },
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
    return passed == total

if __name__ == "__main__":
    print("Starting CORRECTED Financial Calculator API Tests...")
    print("Make sure Django server is running on http://127.0.0.1:8000")
    
    # Test server connectivity
    try:
        response = requests.get(f"{BASE_URL}/health/", timeout=5)
        print(f"✅ Server is accessible (Status: {response.status_code})")
    except:
        print("❌ Cannot connect to Django server. Make sure it's running.")
        sys.exit(1)
    
    # Test payment accuracy first
    accuracy_ok = test_payment_accuracy()
    
    # Run all API tests
    all_tests_ok = run_all_tests()
    
    if accuracy_ok and all_tests_ok:
        print("\n🎉 ALL TESTS PASSED INCLUDING ACCURACY VERIFICATION!")
        sys.exit(0)
    elif accuracy_ok:
        print("\n✅ Calculator accuracy verified, but some API endpoints need fixing.")
        sys.exit(1)
    else:
        print("\n❌ Issues found with calculator accuracy or API integration.")
        sys.exit(1)

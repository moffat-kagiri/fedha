#!/usr/bin/env python3
"""
Comprehensive Financial Calculator API Test - Corrected Parameters
Tests all 8 financial calculator endpoints with correct enum values.
"""

import json
import requests
from decimal import Decimal


BASE_URL = "http://127.0.0.1:8000/api/calculators"
HEADERS = {"Content-Type": "application/json"}


def test_loan_calculator():
    """Test loan payment calculation with correct enum values"""
    print("\n=== Testing Loan Calculator ===")
    
    data = {
        "principal": 100000.00,
        "annual_rate": 5.5,
        "term_years": 5,
        "interest_type": "COMPOUND",  # Corrected from "reducing_balance"
        "payment_frequency": "MONTHLY"  # Corrected from "monthly"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/loan/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Loan Calculator Success!")
            print(f"Monthly Payment: {result.get('monthly_payment', 'N/A')}")
            print(f"Total Amount: {result.get('total_amount', 'N/A')}")
            print(f"Total Interest: {result.get('total_interest', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_interest_rate_solver():
    """Test interest rate solver"""
    print("\n=== Testing Interest Rate Solver ===")
    
    data = {
        "principal": 100000.00,
        "payment": 1000.00,
        "term_years": 10,
        "payment_frequency": "MONTHLY",  # Corrected
        "initial_guess": 5.0,
        "tolerance": 0.00001,
        "max_iterations": 100
    }
    
    try:
        response = requests.post(f"{BASE_URL}/interest-rate-solver/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
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


def test_amortization_schedule():
    """Test amortization schedule generation"""
    print("\n=== Testing Amortization Schedule ===")
    
    data = {
        "principal": 50000.00,
        "annual_rate": 6.0,
        "term_years": 3,
        "payment_frequency": "MONTHLY"  # Corrected
    }
    
    try:
        response = requests.post(f"{BASE_URL}/amortization-schedule/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            schedule = result.get('schedule', [])
            print("✅ Amortization Schedule Success!")
            print(f"Generated {len(schedule)} payment entries")
            if schedule:
                print(f"First payment: {schedule[0]}")
                print(f"Last payment: {schedule[-1]}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_early_payment_calculator():
    """Test early payment savings calculation"""
    print("\n=== Testing Early Payment Calculator ===")
    
    data = {
        "principal": 200000.00,
        "annual_rate": 4.5,
        "term_years": 15,
        "extra_payment": 500.00,
        "payment_frequency": "MONTHLY",  # Corrected
        "extra_payment_type": "MONTHLY"  # Corrected
    }
    
    try:
        response = requests.post(f"{BASE_URL}/early-payment/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Early Payment Calculator Success!")
            print(f"Interest Savings: {result.get('interest_savings', 'N/A')}")
            print(f"Time Savings (months): {result.get('time_savings_months', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_roi_calculator():
    """Test ROI calculation"""
    print("\n=== Testing ROI Calculator ===")
    
    data = {
        "initial_investment": 10000.00,
        "final_value": 15000.00,
        "time_years": 3.0
    }
    
    try:
        response = requests.post(f"{BASE_URL}/roi/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ ROI Calculator Success!")
            print(f"ROI Percentage: {result.get('roi_percentage', 'N/A')}%")
            print(f"Total Return: {result.get('total_return', 'N/A')}")
            print(f"Annualized Return: {result.get('annualized_return', 'N/A')}%")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_compound_interest_calculator():
    """Test compound interest calculation"""
    print("\n=== Testing Compound Interest Calculator ===")
    
    data = {
        "principal": 5000.00,
        "annual_rate": 7.5,
        "time_years": 10.0,
        "compounding_frequency": "MONTHLY",  # Corrected
        "additional_payment": 100.00,
        "additional_frequency": "MONTHLY"  # Corrected
    }
    
    try:
        response = requests.post(f"{BASE_URL}/compound-interest/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Compound Interest Calculator Success!")
            print(f"Future Value: {result.get('future_value', 'N/A')}")
            print(f"Total Interest: {result.get('total_interest', 'N/A')}")
            print(f"Total Contributions: {result.get('total_contributions', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_portfolio_metrics():
    """Test portfolio metrics calculation"""
    print("\n=== Testing Portfolio Metrics ===")
    
    data = {
        "investments": [
            {
                "initial_investment": 10000.00,
                "current_value": 12000.00
            },
            {
                "initial_investment": 5000.00,
                "current_value": 4800.00
            },
            {
                "initial_investment": 15000.00,
                "current_value": 18500.00
            }
        ]
    }
    
    try:
        response = requests.post(f"{BASE_URL}/portfolio-metrics/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Portfolio Metrics Success!")
            print(f"Total Investment: {result.get('total_investment', 'N/A')}")
            print(f"Total Current Value: {result.get('total_current_value', 'N/A')}")
            print(f"Total Gain/Loss: {result.get('total_gain_loss', 'N/A')}")
            print(f"Total Return %: {result.get('total_return_percentage', 'N/A')}%")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def test_risk_assessment():
    """Test risk assessment calculation"""
    print("\n=== Testing Risk Assessment ===")
    
    data = {
        "answers": [3, 4, 2, 5, 3, 4, 2, 1, 5, 3]  # Sample risk assessment answers
    }
    
    try:
        response = requests.post(f"{BASE_URL}/risk-assessment/", headers=HEADERS, json=data)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Risk Assessment Success!")
            print(f"Risk Profile: {result}")
            return True
        else:
            print(f"❌ Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False


def main():
    """Run all financial calculator API tests"""
    print("🧮 Fedha Financial Calculator API Test Suite (Corrected)")
    print("=" * 60)
    
    # Test all calculator endpoints
    tests = [
        test_loan_calculator,
        test_interest_rate_solver,
        test_amortization_schedule,
        test_early_payment_calculator,
        test_roi_calculator,
        test_compound_interest_calculator,
        test_portfolio_metrics,
        test_risk_assessment,
    ]
    
    passed = 0
    total = len(tests)
    
    for test_func in tests:
        if test_func():
            passed += 1
    
    print(f"\n{'='*60}")
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Financial Calculator API is working correctly.")
    else:
        print(f"⚠️  {total - passed} tests failed. Please check the errors above.")


if __name__ == "__main__":
    main()

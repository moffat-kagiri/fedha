#!/usr/bin/env python3
"""
Test the financial calculator against known loan scenarios
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'calculators-microservice'))

from interest_calculator import (
    FinancialCalculator, LoanParameters, InterestType, PaymentFrequency
)

def test_reducing_balance_scenarios():
    """Test reducing balance calculations against known values"""
    
    print("=== Testing Reducing Balance Loan Calculations ===\n")
    
    # Test Case 1: $100,000 loan, 5% annual rate, 30 years, monthly payments
    # Expected monthly payment: ~$536.82 (from standard loan calculators)
    print("Test Case 1: $100,000 loan, 5% annual, 30 years, monthly")
    params = LoanParameters(
        principal=100000,
        annual_rate=5.0,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.REDUCING_BALANCE
    )
    
    result = FinancialCalculator.calculate_payment(params)
    print(f"Calculated Payment: ${result.payment_amount:.2f}")
    print(f"Total Interest: ${result.total_interest:.2f}")
    print(f"Total Amount: ${result.total_amount:.2f}")
    
    # Now test the interest rate solver with the calculated payment
    print(f"\nTesting Interest Rate Solver with payment ${result.payment_amount:.2f}")
    rate_result = FinancialCalculator.solve_interest_rate(
        principal=100000,
        payment=result.payment_amount,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY
    )
    print(f"Solved Rate: {rate_result['annual_rate']:.4f}% (should be 5.0000%)")
    print(f"Converged: {rate_result['converged']}")
    print(f"Iterations: {rate_result['iterations']}")
    
    print("\n" + "="*60)
    
    # Test Case 2: $50,000 loan, 6.5% annual rate, 15 years, monthly payments
    print("\nTest Case 2: $50,000 loan, 6.5% annual, 15 years, monthly")
    params2 = LoanParameters(
        principal=50000,
        annual_rate=6.5,
        term_years=15,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.REDUCING_BALANCE
    )
    
    result2 = FinancialCalculator.calculate_payment(params2)
    print(f"Calculated Payment: ${result2.payment_amount:.2f}")
    print(f"Total Interest: ${result2.total_interest:.2f}")
    
    # Test the solver
    rate_result2 = FinancialCalculator.solve_interest_rate(
        principal=50000,
        payment=result2.payment_amount,
        term_years=15,
        payment_frequency=PaymentFrequency.MONTHLY
    )
    print(f"Solved Rate: {rate_result2['annual_rate']:.4f}% (should be 6.5000%)")
    print(f"Converged: {rate_result2['converged']}")
    
    print("\n" + "="*60)
    
    # Test Case 3: Known benchmark case - verify against external calculator
    # $200,000 loan at 4.5% for 30 years should give ~$1013.37/month
    print("\nTest Case 3: $200,000 loan, 4.5% annual, 30 years, monthly")
    params3 = LoanParameters(
        principal=200000,
        annual_rate=4.5,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.REDUCING_BALANCE
    )
    
    result3 = FinancialCalculator.calculate_payment(params3)
    print(f"Calculated Payment: ${result3.payment_amount:.2f} (expected ~$1013.37)")
    
    # Test solver with a known payment amount
    print("\nTesting solver with known payment $1013.37")
    rate_result3 = FinancialCalculator.solve_interest_rate(
        principal=200000,
        payment=1013.37,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY
    )
    print(f"Solved Rate: {rate_result3['annual_rate']:.4f}% (should be ~4.5000%)")
    print(f"Converged: {rate_result3['converged']}")
    print(f"Iterations: {rate_result3['iterations']}")

def test_compound_vs_reducing():
    """Test that compound interest gives same result as reducing balance for loans"""
    
    print("\n=== Testing Compound vs Reducing Balance ===\n")
    
    principal = 100000
    annual_rate = 5.0
    term_years = 30
    
    # Reducing balance
    params_reducing = LoanParameters(
        principal=principal,
        annual_rate=annual_rate,
        term_years=term_years,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.REDUCING_BALANCE
    )
    
    # Compound interest
    params_compound = LoanParameters(
        principal=principal,
        annual_rate=annual_rate,
        term_years=term_years,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.COMPOUND
    )
    
    result_reducing = FinancialCalculator.calculate_payment(params_reducing)
    result_compound = FinancialCalculator.calculate_payment(params_compound)
    
    print(f"Reducing Balance Payment: ${result_reducing.payment_amount:.2f}")
    print(f"Compound Interest Payment: ${result_compound.payment_amount:.2f}")
    print(f"Difference: ${abs(result_reducing.payment_amount - result_compound.payment_amount):.2f}")
    
    if abs(result_reducing.payment_amount - result_compound.payment_amount) < 0.01:
        print("✅ PASS: Compound and Reducing Balance give same results")
    else:
        print("❌ FAIL: Results differ significantly")

if __name__ == "__main__":
    test_reducing_balance_scenarios()
    test_compound_vs_reducing()

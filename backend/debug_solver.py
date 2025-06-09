#!/usr/bin/env python3
"""
Debug the interest rate solver step by step
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'calculators-microservice'))

from interest_calculator import FinancialCalculator, PaymentFrequency
import math

def debug_solver():
    """Debug the solver step by step"""
    
    # Test case: $100,000 loan, $536.82 payment, 30 years, monthly
    principal = 100000
    payment = 536.82
    term_years = 30
    periods = 30 * 12  # 360 months
    
    print("=== Debugging Interest Rate Solver ===")
    print(f"Principal: ${principal}")
    print(f"Payment: ${payment}")
    print(f"Term: {term_years} years ({periods} periods)")
    print()
    
    # The correct monthly rate should be 5% / 12 = 0.004167
    correct_monthly_rate = 0.05 / 12
    print(f"Expected monthly rate: {correct_monthly_rate:.6f}")
    print(f"Expected annual rate: {correct_monthly_rate * 12 * 100:.4f}%")
    print()
    
    # Test the payment formula with the correct rate
    if correct_monthly_rate == 0:
        test_payment = principal / periods
    else:
        test_payment = principal * (correct_monthly_rate * (1 + correct_monthly_rate)**periods) / ((1 + correct_monthly_rate)**periods - 1)
    
    print(f"Payment with correct rate: ${test_payment:.2f}")
    print()
    
    # Now let's see what our solver is doing
    print("=== Testing Solver Equation ===")
    rate = correct_monthly_rate
    temp = (1 + rate) ** periods
    pv_formula = payment * ((1 - (1 / temp)) / rate)
    
    print(f"Present Value formula result: ${pv_formula:.2f}")
    print(f"Difference from principal: ${pv_formula - principal:.2f}")
    print()
    
    # Test the actual solver
    result = FinancialCalculator.solve_interest_rate(
        principal=principal,
        payment=payment,
        term_years=term_years,
        payment_frequency=PaymentFrequency.MONTHLY
    )
    
    print(f"Solver result: {result['annual_rate']:.4f}%")
    print(f"Period rate: {result['period_rate']:.6f}")
    print(f"Converged: {result['converged']}")
    print(f"Iterations: {result['iterations']}")
    
    # Manual verification of solver result
    solver_monthly_rate = result['period_rate']
    temp2 = (1 + solver_monthly_rate) ** periods
    if solver_monthly_rate == 0:
        test_payment2 = principal / periods
    else:
        test_payment2 = principal * (solver_monthly_rate * (1 + solver_monthly_rate)**periods) / ((1 + solver_monthly_rate)**periods - 1)
    
    print(f"\nVerification with solver rate:")
    print(f"Payment with solver rate: ${test_payment2:.2f}")
    print(f"Target payment: ${payment:.2f}")
    print(f"Error: ${abs(test_payment2 - payment):.2f}")

if __name__ == "__main__":
    debug_solver()

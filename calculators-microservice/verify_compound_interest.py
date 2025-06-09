#!/usr/bin/env python3
"""
Verification script for compound interest calculator accuracy.
Tests the compound interest calculations against known financial formulas.
"""

import math
from interest_calculator import FinancialCalculator, PaymentFrequency

def manual_compound_interest_calculation(principal, annual_rate, years, compounding_freq):
    """Manual calculation using the compound interest formula A = P(1 + r/n)^(nt)"""
    r = annual_rate / 100
    n = compounding_freq
    t = years
    
    amount = principal * ((1 + r/n) ** (n * t))
    return amount

def manual_annuity_calculation(payment, annual_rate, years, payment_freq):
    """Manual calculation for future value of ordinary annuity: FV = PMT * [((1 + r)^n - 1) / r]"""
    r = annual_rate / 100 / payment_freq
    n = payment_freq * years
    
    if r == 0:
        return payment * n
    
    fv = payment * (((1 + r) ** n - 1) / r)
    return fv

def test_compound_interest_scenarios():
    """Test various compound interest scenarios for accuracy"""
    
    print("=== COMPOUND INTEREST VERIFICATION TESTS ===\n")
    
    # Test 1: Simple compound interest without additional payments
    print("Test 1: Principal only compound interest")
    print("-" * 50)
    principal = 10000
    rate = 6.0
    years = 5
    compounding = PaymentFrequency.MONTHLY.value
    
    # Our calculator
    result = FinancialCalculator.calculate_compound_interest(
        principal=principal,
        annual_rate=rate,
        time_years=years,
        compounding_frequency=PaymentFrequency.MONTHLY,
        additional_payment=0
    )
    
    # Manual verification
    manual_amount = manual_compound_interest_calculation(principal, rate, years, compounding)
    
    print(f"Principal: ${principal:,.2f}")
    print(f"Rate: {rate}% annually")
    print(f"Time: {years} years")
    print(f"Compounding: Monthly")
    print(f"Calculator Result: ${result.future_value:,.2f}")
    print(f"Manual Calculation: ${manual_amount:,.2f}")
    print(f"Difference: ${abs(result.future_value - manual_amount):.2f}")
    print(f"Match: {'✅ YES' if abs(result.future_value - manual_amount) < 0.01 else '❌ NO'}\n")
    
    # Test 2: Compound interest with monthly contributions
    print("Test 2: Compound interest with monthly contributions")
    print("-" * 50)
    principal = 5000
    rate = 7.0
    years = 10
    monthly_payment = 200
    
    # Our calculator
    result2 = FinancialCalculator.calculate_compound_interest(
        principal=principal,
        annual_rate=rate,
        time_years=years,
        compounding_frequency=PaymentFrequency.MONTHLY,
        additional_payment=monthly_payment,
        additional_frequency=PaymentFrequency.MONTHLY
    )
    
    # Manual verification
    manual_principal = manual_compound_interest_calculation(principal, rate, years, 12)
    manual_annuity = manual_annuity_calculation(monthly_payment, rate, years, 12)
    manual_total = manual_principal + manual_annuity
    manual_contributions = monthly_payment * 12 * years
    manual_interest = manual_total - principal - manual_contributions
    
    print(f"Principal: ${principal:,.2f}")
    print(f"Rate: {rate}% annually")
    print(f"Time: {years} years")
    print(f"Monthly Payment: ${monthly_payment}")
    print(f"Calculator Future Value: ${result2.future_value:,.2f}")
    print(f"Manual Future Value: ${manual_total:,.2f}")
    print(f"Calculator Interest: ${result2.total_interest:,.2f}")
    print(f"Manual Interest: ${manual_interest:,.2f}")
    print(f"Calculator Contributions: ${result2.total_contributions:,.2f}")
    print(f"Manual Contributions: ${manual_contributions:,.2f}")
    print(f"Future Value Match: {'✅ YES' if abs(result2.future_value - manual_total) < 0.01 else '❌ NO'}")
    print(f"Interest Match: {'✅ YES' if abs(result2.total_interest - manual_interest) < 0.01 else '❌ NO'}")
    print(f"Contributions Match: {'✅ YES' if abs(result2.total_contributions - manual_contributions) < 0.01 else '❌ NO'}\n")
    
    # Test 3: Different compounding frequencies
    print("Test 3: Different compounding frequencies")
    print("-" * 50)
    principal = 1000
    rate = 5.0
    years = 2
    
    frequencies = [
        (PaymentFrequency.ANNUALLY, "Annually"),
        (PaymentFrequency.SEMI_ANNUALLY, "Semi-annually"),
        (PaymentFrequency.QUARTERLY, "Quarterly"),
        (PaymentFrequency.MONTHLY, "Monthly"),
        (PaymentFrequency.DAILY, "Daily")
    ]
    
    for freq, name in frequencies:
        result = FinancialCalculator.calculate_compound_interest(
            principal=principal,
            annual_rate=rate,
            time_years=years,
            compounding_frequency=freq,
            additional_payment=0
        )
        
        manual = manual_compound_interest_calculation(principal, rate, years, freq.value)
        
        print(f"{name:15}: Calculator=${result.future_value:8.2f}, Manual=${manual:8.2f}, "
              f"Match={'✅' if abs(result.future_value - manual) < 0.01 else '❌'}")
    
    print("\n" + "=" * 70)
    print("VERIFICATION COMPLETE")
    print("=" * 70)

if __name__ == "__main__":
    test_compound_interest_scenarios()

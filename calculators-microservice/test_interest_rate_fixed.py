"""
Test script to verify the interest rate solver.
"""

import sys
from interest_calculator import FinancialCalculator, PaymentFrequency, InterestType


def test_reducing_balance_calculation():
    """Test the reducing balance calculation."""
    # Test case: Ksh 500,000, 5 years, 17.74% APR, monthly payments
    principal = 500000
    annual_rate = 17.74
    term_years = 5
    payment_frequency = PaymentFrequency.MONTHLY
    
    # Calculate expected payment
    params = {
        "principal": principal,
        "annual_interest_rate": annual_rate,
        "term_years": term_years,
        "interest_type": InterestType.REDUCING_BALANCE,
        "payment_frequency": payment_frequency
    }
    
    from interest_calculator import LoanParameters
    loan_params = LoanParameters(**params)
    
    result = FinancialCalculator.calculate_payment(loan_params)
    payment = result["payment"]
    
    print(f"Loan Amount: {principal:,.2f}")
    print(f"Term: {term_years} years")
    print(f"Annual Interest Rate: {annual_rate}%")
    print(f"Payment Frequency: {payment_frequency.value}")
    print(f"Monthly Payment: {payment:,.2f}")
    
    return payment


def test_interest_rate_solver(payment):
    """Test the interest rate solver with the payment from the calculation."""
    # Use the same parameters but solve for the interest rate
    principal = 500000
    term_years = 5
    payment_frequency = PaymentFrequency.MONTHLY
    
    # Solve for interest rate
    result = FinancialCalculator.solve_interest_rate(
        principal=principal,
        payment=payment,
        term_years=term_years,
        payment_frequency=payment_frequency,
        interest_type=InterestType.REDUCING_BALANCE
    )
    
    print("\nInterest Rate Solver Results:")
    print(f"Calculated Annual Rate: {result['annual_rate']:.4f}%")
    print(f"Converged: {result['converged']}")
    print(f"Iterations: {result['iterations']}")
    
    # Verify by calculating payment with solved rate
    verification_params = {
        "principal": principal,
        "annual_interest_rate": result['annual_rate'],
        "term_years": term_years,
        "interest_type": InterestType.REDUCING_BALANCE,
        "payment_frequency": payment_frequency
    }
    
    from interest_calculator import LoanParameters
    verification_loan_params = LoanParameters(**verification_params)
    
    verification_result = FinancialCalculator.calculate_payment(verification_loan_params)
    verification_payment = verification_result["payment"]
    
    print(f"\nVerification:")
    print(f"Recalculated Payment: {verification_payment:,.2f}")
    print(f"Original Payment: {payment:,.2f}")
    print(f"Difference: {abs(verification_payment - payment):,.2f}")
    
    return result['annual_rate']


if __name__ == "__main__":
    payment = test_reducing_balance_calculation()
    annual_rate = test_interest_rate_solver(payment)
    
    # Test a specific payment amount: 12,626.10
    print("\nTesting with exact payment amount of 12,626.10:")
    specific_payment = 12626.10
    specific_annual_rate = test_interest_rate_solver(specific_payment)

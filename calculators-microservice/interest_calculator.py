"""
Financial Calculator library for Fedha application.
Provides tools for loan calculations, interest rate solving, and other financial operations.
"""

import enum
import math
from decimal import Decimal
from dataclasses import dataclass
from typing import Dict, Union, List, Any, Optional


class InterestType(enum.Enum):
    """Interest calculation method types."""
    REDUCING_BALANCE = "reducing_balance"
    FLAT_RATE = "flat_rate"
    COMPOUND = "compound"


class PaymentFrequency(enum.Enum):
    """Payment frequency types."""
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    SEMI_ANNUALLY = "semi_annually"
    ANNUALLY = "annually"
    WEEKLY = "weekly"
    BI_WEEKLY = "bi_weekly"
    DAILY = "daily"


@dataclass
class LoanParameters:
    """Parameters for loan calculation."""
    principal: float
    annual_interest_rate: float
    term_years: int
    interest_type: InterestType
    payment_frequency: PaymentFrequency


class FinancialCalculator:
    """Financial calculation engine for Fedha application."""
    
    @staticmethod
    def get_periods_per_year(payment_frequency: PaymentFrequency) -> int:
        """Convert payment frequency to number of periods per year."""
        frequency_map = {
            PaymentFrequency.MONTHLY: 12,
            PaymentFrequency.QUARTERLY: 4,
            PaymentFrequency.SEMI_ANNUALLY: 2,
            PaymentFrequency.ANNUALLY: 1,
            PaymentFrequency.WEEKLY: 52,
            PaymentFrequency.BI_WEEKLY: 26,
            PaymentFrequency.DAILY: 365,
        }
        return frequency_map[payment_frequency]
    
    @staticmethod
    def calculate_payment(params: LoanParameters) -> Dict[str, Any]:
        """Calculate loan payment based on loan parameters."""
        principal = params.principal
        annual_rate = params.annual_interest_rate / 100
        term_years = params.term_years
        interest_type = params.interest_type
        payment_frequency = params.payment_frequency
        
        periods_per_year = FinancialCalculator.get_periods_per_year(payment_frequency)
        total_periods = term_years * periods_per_year
        rate_per_period = annual_rate / periods_per_year
        
        if interest_type == InterestType.REDUCING_BALANCE:
            # Standard amortization formula for reducing balance
            if rate_per_period > 0:
                payment = principal * (rate_per_period * (1 + rate_per_period) ** total_periods) / ((1 + rate_per_period) ** total_periods - 1)
            else:
                payment = principal / total_periods
        
        elif interest_type == InterestType.FLAT_RATE:
            # Flat rate formula
            total_interest = principal * annual_rate * term_years
            payment = (principal + total_interest) / total_periods
        
        elif interest_type == InterestType.COMPOUND:
            # Compound interest with regular payments
            future_value = principal * (1 + rate_per_period) ** total_periods
            payment = future_value / total_periods
            
        # Calculate total interest and total payment
        total_payment = payment * total_periods
        total_interest = total_payment - principal
        
        return {
            "payment": payment,
            "total_interest": total_interest,
            "total_payment": total_payment,
            "periods": total_periods,
            "rate_per_period": rate_per_period
        }
    
    @staticmethod
    def solve_interest_rate(
        principal: float, 
        payment: float, 
        term_years: int, 
        payment_frequency: PaymentFrequency,
        interest_type: InterestType = InterestType.REDUCING_BALANCE,
        tolerance: float = 0.00001,
        max_iterations: int = 100
    ) -> Dict[str, Any]:
        """
        Solve for the interest rate using Newton-Raphson method.
        
        For reducing balance loans, use the standard amortization formula:
        P = L[c(1 + c)^n]/[(1 + c)^n - 1]
        
        Where:
        P = payment amount per period
        L = principal loan amount
        c = interest rate per period
        n = total number of payments
        """
        periods_per_year = FinancialCalculator.get_periods_per_year(payment_frequency)
        total_periods = term_years * periods_per_year
        
        # Different calculation methods based on interest type
        if interest_type == InterestType.FLAT_RATE:
            # For flat rate, the calculation is much simpler
            # P = (L + I)/n where I = L*r*t
            # So r = (P*n - L)/(L*t)
            total_payment = payment * total_periods
            annual_rate = (total_payment - principal) / (principal * term_years) * 100
            return {"annual_rate": annual_rate, "converged": True, "iterations": 1}
            
        elif interest_type == InterestType.REDUCING_BALANCE:
            # Start with an initial guess of 10%
            rate_guess = 0.10 / periods_per_year
            
            iteration = 0
            converged = False
            
            while iteration < max_iterations and not converged:
                # Use amortization formula:
                # P = L[c(1 + c)^n]/[(1 + c)^n - 1]
                
                # Calculate payment at current rate guess
                if rate_guess <= 0:
                    rate_guess = 0.0001 / periods_per_year  # Avoid division by zero
                
                # For reducing balance, the value of function at current rate guess
                term1 = (1 + rate_guess) ** total_periods
                calc_payment = principal * rate_guess * term1 / (term1 - 1)
                
                # Calculate the function value: f(r) = calculated_payment - actual_payment
                f_r = calc_payment - payment
                
                # If the calculated payment is close enough to actual payment, we're done
                if abs(f_r) < tolerance:
                    converged = True
                    break
                
                # Calculate derivative of the function: f'(r)
                # Derivative is complex, using numerical approximation
                delta = max(0.0000001, rate_guess * 0.001)
                term1_plus_delta = (1 + rate_guess + delta) ** total_periods
                calc_payment_plus_delta = principal * (rate_guess + delta) * term1_plus_delta / (term1_plus_delta - 1)
                f_prime_r = (calc_payment_plus_delta - calc_payment) / delta
                
                # Newton-Raphson update: r_new = r_old - f(r)/f'(r)
                if abs(f_prime_r) < 0.000001:  # Avoid division by very small numbers
                    rate_guess = rate_guess * 0.9  # Make smaller adjustment
                else:
                    rate_guess = rate_guess - f_r / f_prime_r
                
                # Ensure rate stays positive and reasonable
                if rate_guess <= 0:
                    rate_guess = 0.0001 / periods_per_year
                elif rate_guess > 1:  # Cap at 100% per period
                    rate_guess = 0.5
                
                iteration += 1
            
            # Convert period rate to annual rate
            annual_rate = rate_guess * periods_per_year * 100
            
            return {
                "annual_rate": annual_rate,
                "converged": converged,
                "iterations": iteration
            }
        
        else:  # Compound interest
            # For compound interest, using simplified calculation
            # This is an approximation and would need refinement
            total_payment = payment * total_periods
            annual_rate = ((total_payment / principal) ** (1/term_years) - 1) * 100
            
            return {
                "annual_rate": annual_rate,
                "converged": True,
                "iterations": 1
            }
            
    @staticmethod
    def generate_amortization_schedule(
        principal: float,
        annual_interest_rate: float,
        term_years: int,
        payment_frequency: PaymentFrequency,
        interest_type: InterestType = InterestType.REDUCING_BALANCE
    ) -> List[Dict[str, Any]]:
        """Generate a complete amortization schedule."""
        periods_per_year = FinancialCalculator.get_periods_per_year(payment_frequency)
        total_periods = term_years * periods_per_year
        rate_per_period = annual_interest_rate / 100 / periods_per_year
        
        # Calculate payment amount first
        params = LoanParameters(
            principal=principal,
            annual_interest_rate=annual_interest_rate,
            term_years=term_years,
            interest_type=interest_type,
            payment_frequency=payment_frequency
        )
        result = FinancialCalculator.calculate_payment(params)
        payment = result["payment"]
        
        schedule = []
        remaining_balance = principal
        
        for period in range(1, total_periods + 1):
            if interest_type == InterestType.REDUCING_BALANCE:
                # Standard amortization for reducing balance
                interest_payment = remaining_balance * rate_per_period
                principal_payment = payment - interest_payment
                
                # Handle final payment rounding issues
                if period == total_periods:
                    principal_payment = remaining_balance
                    payment = principal_payment + interest_payment
                
                remaining_balance -= principal_payment
                if remaining_balance < 0:
                    remaining_balance = 0
                    
            elif interest_type == InterestType.FLAT_RATE:
                # For flat rate, interest is fixed based on original principal
                interest_payment = principal * rate_per_period
                principal_payment = payment - interest_payment
                remaining_balance -= principal_payment
                
            else:  # Compound
                # Simplified compound interest schedule
                interest_payment = remaining_balance * rate_per_period
                principal_payment = payment - interest_payment
                remaining_balance = (remaining_balance + interest_payment) - payment
            
            schedule.append({
                "period": period,
                "payment": payment,
                "principal_payment": principal_payment,
                "interest_payment": interest_payment,
                "remaining_balance": remaining_balance
            })
            
        return schedule

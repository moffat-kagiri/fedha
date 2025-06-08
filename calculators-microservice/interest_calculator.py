# Loan/interest solvers
import math
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

class InterestType(Enum):
    SIMPLE = "simple"
    COMPOUND = "compound"
    REDUCING_BALANCE = "reducing_balance"
    FLAT_RATE = "flat_rate"

class PaymentFrequency(Enum):
    MONTHLY = 12
    QUARTERLY = 4
    SEMI_ANNUALLY = 2
    ANNUALLY = 1
    WEEKLY = 52
    DAILY = 365

@dataclass
class LoanParameters:
    principal: float
    annual_rate: float
    term_years: int
    payment_frequency: PaymentFrequency
    interest_type: InterestType

@dataclass
class PaymentCalculationResult:
    payment_amount: float
    total_interest: float
    total_amount: float
    monthly_payment: float
    total_payments: int

@dataclass
class AmortizationEntry:
    payment_number: int
    payment_amount: float
    principal_payment: float
    interest_payment: float
    remaining_balance: float

@dataclass
class EarlyPaymentResult:
    original_total_interest: float
    original_total_payments: float
    original_term_months: int
    new_total_interest: float
    new_total_payments: float
    new_term_months: int
    interest_savings: float
    time_savings_months: int

@dataclass
class ROIResult:
    roi_percentage: float
    annualized_return: Optional[float]
    total_return: float

@dataclass
class CompoundInterestResult:
    future_value: float
    total_interest: float
    total_contributions: float

class FinancialCalculator:
    """Comprehensive financial calculator with loan and investment calculations."""
    
    @staticmethod
    def calculate_payment(params: LoanParameters) -> PaymentCalculationResult:
        """Calculate loan payment based on interest type and frequency."""
        
        if params.interest_type == InterestType.SIMPLE:
            return FinancialCalculator._calculate_simple_interest_payment(params)
        elif params.interest_type == InterestType.COMPOUND:
            return FinancialCalculator._calculate_compound_interest_payment(params)
        elif params.interest_type == InterestType.REDUCING_BALANCE:
            return FinancialCalculator._calculate_reducing_balance_payment(params)
        elif params.interest_type == InterestType.FLAT_RATE:
            return FinancialCalculator._calculate_flat_rate_payment(params)
        else:
            raise ValueError(f"Unsupported interest type: {params.interest_type}")
    
    @staticmethod
    def _calculate_simple_interest_payment(params: LoanParameters) -> PaymentCalculationResult:
        """Calculate payment for simple interest loan."""
        total_interest = params.principal * (params.annual_rate / 100) * params.term_years
        total_amount = params.principal + total_interest
        total_payments = params.term_years * params.payment_frequency.value
        payment_amount = total_amount / total_payments
        monthly_payment = total_amount / (params.term_years * 12)
        
        return PaymentCalculationResult(
            payment_amount=payment_amount,
            total_interest=total_interest,
            total_amount=total_amount,
            monthly_payment=monthly_payment,
            total_payments=total_payments
        )
    
    @staticmethod
    def _calculate_compound_interest_payment(params: LoanParameters) -> PaymentCalculationResult:
        """Calculate payment for compound interest loan."""
        n = params.payment_frequency.value
        r = params.annual_rate / 100
        t = params.term_years
        
        # Compound amount: A = P(1 + r/n)^(nt)
        compound_amount = params.principal * ((1 + r/n) ** (n * t))
        total_interest = compound_amount - params.principal
        total_payments = params.term_years * params.payment_frequency.value
        payment_amount = compound_amount / total_payments
        monthly_payment = compound_amount / (params.term_years * 12)
        
        return PaymentCalculationResult(
            payment_amount=payment_amount,
            total_interest=total_interest,
            total_amount=compound_amount,
            monthly_payment=monthly_payment,
            total_payments=total_payments
        )
    
    @staticmethod
    def _calculate_reducing_balance_payment(params: LoanParameters) -> PaymentCalculationResult:
        """Calculate payment for reducing balance (amortizing) loan."""
        n = params.payment_frequency.value
        r = params.annual_rate / 100 / n  # Period interest rate
        num_payments = params.term_years * n
        
        if r == 0:
            # Handle zero interest case
            payment_amount = params.principal / num_payments
            total_interest = 0
        else:
            # Standard amortization formula: PMT = P * [r(1+r)^n] / [(1+r)^n - 1]
            payment_amount = params.principal * (r * (1 + r)**num_payments) / ((1 + r)**num_payments - 1)
            total_interest = (payment_amount * num_payments) - params.principal
        
        total_amount = params.principal + total_interest
        monthly_payment = payment_amount if params.payment_frequency == PaymentFrequency.MONTHLY else (total_amount / (params.term_years * 12))
        
        return PaymentCalculationResult(
            payment_amount=payment_amount,
            total_interest=total_interest,
            total_amount=total_amount,
            monthly_payment=monthly_payment,
            total_payments=num_payments
                )

    @staticmethod
    def _calculate_flat_rate_payment(params: LoanParameters) -> PaymentCalculationResult:
        """Calculate payment for flat rate loan."""
        # Flat rate calculates interest on original principal for entire term
        total_interest = params.principal * (params.annual_rate / 100) * params.term_years
        total_amount = params.principal + total_interest
        total_payments = params.term_years * params.payment_frequency.value
        payment_amount = total_amount / total_payments
        monthly_payment = total_amount / (params.term_years * 12)
        
        return PaymentCalculationResult(
            payment_amount=payment_amount,
            total_interest=total_interest,
            total_amount=total_amount,
            monthly_payment=monthly_payment,
            total_payments=total_payments
        )

    @staticmethod
    def solve_interest_rate(principal: float, payment: float, term_years: int, 
                          payment_frequency: PaymentFrequency = PaymentFrequency.MONTHLY,
                          tolerance: float = 1e-6, max_iterations: int = 100) -> Dict[str, float]:
        """Solve for interest rate using Newton-Raphson method."""
        
        periods = term_years * payment_frequency.value
        
        # Validate inputs
        if payment * periods <= principal:
            # Insufficient payment to cover principal - no positive interest rate solution
            return {
                'annual_rate': 0.0,
                'period_rate': 0.0,
                'iterations': 0,
                'converged': False
            }
        
        # Initial guess - use a better estimate based on simple interest approximation
        estimated_total_interest = (payment * periods) - principal
        initial_guess = (estimated_total_interest / principal) / term_years
        rate = max(initial_guess / payment_frequency.value, 0.001 / payment_frequency.value)
        
        # Initialize variables
        f = float('inf')
        converged = False
        i = 0
        
        for i in range(max_iterations):
            if abs(rate) < 1e-10:
                # Handle near-zero rate case
                f = payment * periods - principal
                f_prime = periods
            else:
                # Calculate function value and derivative using standard loan formula
                temp = (1 + rate) ** periods
                if temp == 1:
                    f = payment * periods - principal
                    f_prime = periods
                else:
                    # Present value of annuity formula: PV = PMT * [(1 - (1+r)^-n) / r]
                    f = payment * ((1 - (1 / temp)) / rate) - principal
                    # Derivative calculation
                    temp_inv = 1 / temp
                    f_prime = payment * (
                        (temp_inv * periods / rate + temp_inv / (1 + rate) - 1 / rate) / rate
                    )
            
            # Check convergence on function value
            if abs(f) < tolerance:
                converged = True
                break
            
            # Avoid division by zero
            if abs(f_prime) < 1e-12:
                break
            
            # Newton-Raphson update
            rate_change = f / f_prime
            new_rate = rate - rate_change
            
            # Prevent negative or excessively high rates
            new_rate = max(new_rate, -0.5 / payment_frequency.value)
            new_rate = min(new_rate, 2.0 / payment_frequency.value)  # Cap at 200% annual
            
            # Check convergence on rate change
            if abs(rate_change) < tolerance:
                converged = True
                break
            
            rate = new_rate
        
        annual_rate = rate * payment_frequency.value * 100
        
        return {
            'annual_rate': annual_rate,
            'period_rate': rate,
            'iterations': i + 1,
            'converged': converged
        }
    
    @staticmethod
    def generate_amortization_schedule(principal: float, annual_rate: float, term_years: int,
                                     payment_frequency: PaymentFrequency = PaymentFrequency.MONTHLY) -> List[AmortizationEntry]:
        """Generate complete amortization schedule."""
        
        n = payment_frequency.value
        period_rate = annual_rate / 100 / n
        num_payments = term_years * n
        
        if period_rate == 0:
            payment_amount = principal / num_payments
        else:
            payment_amount = principal * (period_rate * (1 + period_rate)**num_payments) / ((1 + period_rate)**num_payments - 1)
        
        schedule = []
        remaining_balance = principal
        
        for i in range(1, num_payments + 1):
            interest_payment = remaining_balance * period_rate
            principal_payment = payment_amount - interest_payment
            
            # Handle final payment rounding
            if i == num_payments:
                principal_payment = remaining_balance
                payment_amount = principal_payment + interest_payment
            
            remaining_balance -= principal_payment
            
            # Avoid negative balance due to floating point precision
            if remaining_balance < 0:
                remaining_balance = 0
            
            schedule.append(AmortizationEntry(
                payment_number=i,
                payment_amount=payment_amount,
                principal_payment=principal_payment,
                interest_payment=interest_payment,
                remaining_balance=remaining_balance
            ))
        
        return schedule
    
    @staticmethod
    def calculate_early_payment_savings(principal: float, annual_rate: float, term_years: int,
                                      extra_payment: float, payment_frequency: PaymentFrequency = PaymentFrequency.MONTHLY,
                                      extra_payment_type: str = "monthly") -> EarlyPaymentResult:
        """Calculate savings from extra loan payments."""
        
        n = payment_frequency.value
        period_rate = annual_rate / 100 / n
        total_periods = term_years * n
        
        # Calculate original loan details
        if period_rate == 0:
            payment = principal / total_periods
        else:
            payment = principal * (period_rate * (1 + period_rate)**total_periods) / ((1 + period_rate)**total_periods - 1)
        
        original_total_payments = payment * total_periods
        original_total_interest = original_total_payments - principal
        
        # Calculate new loan with extra payments
        remaining_balance = principal
        total_interest_paid = 0
        total_payments_made = 0
        payments_made = 0
        
        if extra_payment_type.lower() == "monthly":
            # Monthly extra payments
            while remaining_balance > 0.01 and payments_made < total_periods * 2:  # Safety limit
                interest_payment = remaining_balance * period_rate
                principal_payment = payment - interest_payment + extra_payment
                
                if principal_payment >= remaining_balance:
                    # Final payment
                    total_interest_paid += interest_payment
                    total_payments_made += interest_payment + remaining_balance
                    remaining_balance = 0
                else:
                    remaining_balance -= principal_payment
                    total_interest_paid += interest_payment
                    total_payments_made += payment + extra_payment
                
                payments_made += 1
        else:
            # One-time extra payment (applied to first payment)
            first_payment = True
            while remaining_balance > 0.01 and payments_made < total_periods * 2:
                interest_payment = remaining_balance * period_rate
                principal_payment = payment - interest_payment + (extra_payment if first_payment else 0)
                
                if principal_payment >= remaining_balance:
                    # Final payment
                    total_interest_paid += interest_payment
                    total_payments_made += interest_payment + remaining_balance
                    remaining_balance = 0
                else:
                    remaining_balance -= principal_payment
                    total_interest_paid += interest_payment
                    total_payments_made += payment + (extra_payment if first_payment else 0)
                
                payments_made += 1
                first_payment = False
        
        return EarlyPaymentResult(
            original_total_interest=original_total_interest,
            original_total_payments=original_total_payments,
            original_term_months=total_periods,
            new_total_interest=total_interest_paid,
            new_total_payments=total_payments_made,
            new_term_months=payments_made,
            interest_savings=original_total_interest - total_interest_paid,
            time_savings_months=total_periods - payments_made
        )
    
    @staticmethod
    def calculate_roi(initial_investment: float, final_value: float, 
                     time_years: Optional[float] = None) -> ROIResult:
        """Calculate Return on Investment (ROI)."""
        
        total_return = final_value - initial_investment
        roi_percentage = (total_return / initial_investment) * 100
        
        annualized_return = None
        if time_years and time_years > 0:
            annualized_return = ((final_value / initial_investment) ** (1 / time_years) - 1) * 100
        
        return ROIResult(
            roi_percentage=roi_percentage,
            annualized_return=annualized_return,
            total_return=total_return
        )
    
    @staticmethod
    def calculate_compound_interest(principal: float, annual_rate: float, time_years: float,
                                  compounding_frequency: PaymentFrequency = PaymentFrequency.MONTHLY,
                                  additional_payment: float = 0,
                                  additional_frequency: PaymentFrequency = PaymentFrequency.MONTHLY) -> CompoundInterestResult:
        """Calculate compound interest with optional regular contributions."""
        
        n = compounding_frequency.value
        r = annual_rate / 100
        
        # Compound interest on principal: A = P(1 + r/n)^(nt)
        compound_amount = principal * ((1 + r/n) ** (n * time_years))
        
        # Additional contributions (future value of annuity)
        additional_amount = 0
        total_contributions = 0
        
        if additional_payment > 0:
            additional_n = additional_frequency.value
            periodic_rate = r / additional_n
            periods = additional_n * time_years
            
            if periodic_rate > 0:
                additional_amount = additional_payment * (((1 + periodic_rate) ** periods - 1) / periodic_rate)
            else:
                additional_amount = additional_payment * periods
            
            total_contributions = additional_payment * additional_frequency.value * time_years
        
        future_value = compound_amount + additional_amount
        total_interest = future_value - principal - total_contributions
        
        return CompoundInterestResult(
            future_value=future_value,
            total_interest=total_interest,
            total_contributions=total_contributions
        )
    
    @staticmethod
    def calculate_portfolio_metrics(investments: List[Dict[str, float]]) -> Dict[str, float]:
        """Calculate portfolio performance metrics."""
        
        total_investment = sum(inv['shares'] * inv['purchase_price'] for inv in investments)
        total_current_value = sum(inv['shares'] * inv['current_price'] for inv in investments)
        total_gain_loss = total_current_value - total_investment
        total_return_percentage = (total_gain_loss / total_investment * 100) if total_investment > 0 else 0
        
        return {
            'total_investment': total_investment,
            'total_current_value': total_current_value,
            'total_gain_loss': total_gain_loss,
            'total_return_percentage': total_return_percentage
        }
    
    @staticmethod
    def assess_risk_profile(answers: List[int]) -> Dict[str, str]:
        """Assess investment risk profile based on questionnaire answers."""
        
        total_score = sum(answers)
        average_score = total_score / len(answers)
        
        if average_score <= 1:
            profile = 'Conservative'
            recommendation = ('Focus on bonds, CDs, and money market funds. '
                            'Consider 80% bonds, 20% stocks allocation.')
        elif average_score <= 2:
            profile = 'Moderately Conservative'
            recommendation = ('Balanced approach with stable investments. '
                            'Consider 60% bonds, 40% stocks allocation.')
        elif average_score <= 3:
            profile = 'Moderate'
            recommendation = ('Balanced growth and income strategy. '
                            'Consider 50% stocks, 50% bonds allocation.')
        elif average_score <= 4:
            profile = 'Moderately Aggressive'
            recommendation = ('Growth-focused with some stability. '
                            'Consider 70% stocks, 30% bonds allocation.')
        else:
            profile = 'Aggressive'
            recommendation = ('Maximum growth potential with higher risk. '
                            'Consider 90% stocks, 10% bonds allocation.')
        
        return {
            'risk_profile': profile,
            'recommendation': recommendation,
            'score': str(average_score)
        }

# Example usage and testing functions
def test_calculator():
    """Test the financial calculator functions."""
    
    print("=== Financial Calculator Test Suite ===\n")
    
    # Test 1: Loan Payment Calculation
    print("1. Testing Loan Payment Calculation:")
    params = LoanParameters(
        principal=100000,
        annual_rate=5.5,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY,
        interest_type=InterestType.REDUCING_BALANCE
    )
    result = FinancialCalculator.calculate_payment(params)
    print(f"   Principal: ${params.principal:,.2f}")
    print(f"   Rate: {params.annual_rate}%")
    print(f"   Term: {params.term_years} years")
    print(f"   Monthly Payment: ${result.payment_amount:,.2f}")
    print(f"   Total Interest: ${result.total_interest:,.2f}")
    print(f"   Total Amount: ${result.total_amount:,.2f}\n")
    
    # Test 2: Interest Rate Solving
    print("2. Testing Interest Rate Solver:")
    rate_result = FinancialCalculator.solve_interest_rate(
        principal=100000,
        payment=567.79,
        term_years=30,
        payment_frequency=PaymentFrequency.MONTHLY
    )
    print(f"   Principal: $100,000")
    print(f"   Payment: $567.79")
    print(f"   Term: 30 years")
    print(f"   Calculated Rate: {rate_result['annual_rate']:.3f}%")
    print(f"   Iterations: {rate_result['iterations']}")
    print(f"   Converged: {rate_result['converged']}\n")
    
    # Test 3: ROI Calculation
    print("3. Testing ROI Calculation:")
    roi = FinancialCalculator.calculate_roi(
        initial_investment=10000,
        final_value=15000,
        time_years=3
    )
    print(f"   Initial Investment: $10,000")
    print(f"   Final Value: $15,000")
    print(f"   Time: 3 years")
    print(f"   ROI: {roi.roi_percentage:.2f}%")
    print(f"   Annualized Return: {roi.annualized_return:.2f}%")
    print(f"   Total Return: ${roi.total_return:,.2f}\n")
    
    # Test 4: Compound Interest
    print("4. Testing Compound Interest:")
    compound = FinancialCalculator.calculate_compound_interest(
        principal=5000,
        annual_rate=7,
        time_years=10,
        compounding_frequency=PaymentFrequency.MONTHLY,
        additional_payment=200,
        additional_frequency=PaymentFrequency.MONTHLY
    )
    print(f"   Principal: $5,000")
    print(f"   Rate: 7%")
    print(f"   Time: 10 years")
    print(f"   Additional: $200/month")
    print(f"   Future Value: ${compound.future_value:,.2f}")
    print(f"   Total Interest: ${compound.total_interest:,.2f}")
    print(f"   Total Contributions: ${compound.total_contributions:,.2f}\n")
    
    # Test 5: Early Payment Savings
    print("5. Testing Early Payment Savings:")
    early_payment = FinancialCalculator.calculate_early_payment_savings(
        principal=200000,
        annual_rate=4.5,
        term_years=30,
        extra_payment=200,
        payment_frequency=PaymentFrequency.MONTHLY,
        extra_payment_type="monthly"
    )
    print(f"   Principal: $200,000")
    print(f"   Rate: 4.5%")
    print(f"   Term: 30 years")
    print(f"   Extra Payment: $200/month")
    print(f"   Interest Savings: ${early_payment.interest_savings:,.2f}")
    print(f"   Time Savings: {early_payment.time_savings_months} months")
    print(f"   New Term: {early_payment.new_term_months} months\n")

if __name__ == "__main__":
    test_calculator()
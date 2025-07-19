from interest_calculator import FinancialCalculator, PaymentFrequency

# Test 1: Simple compound interest verification
print("=== COMPOUND INTEREST VERIFICATION ===\n")

# Test case 1: Principal only, monthly compounding
principal = 10000
rate = 6.0
years = 5

result = FinancialCalculator.calculate_compound_interest(
    principal=principal,
    annual_rate=rate,
    time_years=years,
    compounding_frequency=PaymentFrequency.MONTHLY,
    additional_payment=0
)

# Manual calculation using A = P(1 + r/n)^(nt)
manual = principal * ((1 + rate/100/12) ** (12 * years))

print("Test 1: Principal Only Compound Interest")
print("-" * 40)
print(f"Principal: ${principal:,.2f}")
print(f"Rate: {rate}% annually (monthly compounding)")
print(f"Time: {years} years")
print(f"Calculator Result: ${result.future_value:,.2f}")
print(f"Manual Formula: ${manual:,.2f}")
print(f"Difference: ${abs(result.future_value - manual):.2f}")
print(f"Accurate: {'YES' if abs(result.future_value - manual) < 0.01 else 'NO'}")
print()

# Test case 2: With monthly contributions
print("Test 2: With Monthly Contributions")
print("-" * 40)
principal2 = 5000
rate2 = 7.0
years2 = 10
monthly_payment = 200

result2 = FinancialCalculator.calculate_compound_interest(
    principal=principal2,
    annual_rate=rate2,
    time_years=years2,
    compounding_frequency=PaymentFrequency.MONTHLY,
    additional_payment=monthly_payment,
    additional_frequency=PaymentFrequency.MONTHLY
)

# Manual verification
# Future value of principal: P(1 + r/n)^(nt)
fv_principal = principal2 * ((1 + rate2/100/12) ** (12 * years2))

# Future value of annuity: PMT * [((1 + r)^n - 1) / r]
r_monthly = rate2/100/12
n_payments = 12 * years2
fv_annuity = monthly_payment * (((1 + r_monthly) ** n_payments - 1) / r_monthly)

manual_total = fv_principal + fv_annuity
manual_contributions = monthly_payment * 12 * years2
manual_interest = manual_total - principal2 - manual_contributions

print(f"Principal: ${principal2:,.2f}")
print(f"Rate: {rate2}% annually")
print(f"Time: {years2} years")
print(f"Monthly Payment: ${monthly_payment}")
print(f"Calculator Future Value: ${result2.future_value:,.2f}")
print(f"Manual Future Value: ${manual_total:,.2f}")
print(f"FV Difference: ${abs(result2.future_value - manual_total):.2f}")
print(f"Calculator Interest: ${result2.total_interest:,.2f}")
print(f"Manual Interest: ${manual_interest:,.2f}")
print(f"Interest Difference: ${abs(result2.total_interest - manual_interest):.2f}")
print(f"Calculator Contributions: ${result2.total_contributions:,.2f}")
print(f"Manual Contributions: ${manual_contributions:,.2f}")
print(f"Contributions Match: {'YES' if abs(result2.total_contributions - manual_contributions) < 0.01 else 'NO'}")
print(f"Future Value Accurate: {'YES' if abs(result2.future_value - manual_total) < 0.01 else 'NO'}")
print(f"Interest Accurate: {'YES' if abs(result2.total_interest - manual_interest) < 0.01 else 'NO'}")
print()

print("=== VERIFICATION COMPLETE ===")

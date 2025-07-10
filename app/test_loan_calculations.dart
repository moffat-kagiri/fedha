// Test file to verify loan calculations match Kenyan bank standards
import 'dart:io';
import 'lib/models/financial_models.dart';
import 'lib/services/financial_calculator_service.dart';

void main() {
  print('=== Testing Loan Calculations ===\n');

  // Test case: KSh 100,000 loan at 15% annual rate for 12 months
  final testParams = LoanParameters(
    principal: 100000,
    annualRate: 15.0, // 15% annual
    termMonths: 12,
    paymentFrequency: PaymentFrequency.monthly,
    interestType: InterestType.reducingBalance,
  );

  // Calculate payment
  final result = FinancialCalculatorService.calculateLoanPayment(testParams);

  print('--- Reducing Balance Calculation ---');
  print('Principal: KSh ${testParams.principal.toStringAsFixed(2)}');
  print('Interest Rate: ${testParams.annualRate!.toStringAsFixed(2)}% annual');
  print('Term: ${testParams.termMonths} months');
  print('');
  print('Monthly Payment: KSh ${result.paymentAmount.toStringAsFixed(2)}');
  print('Total Amount: KSh ${result.totalAmount.toStringAsFixed(2)}');
  print('Total Interest: KSh ${result.totalInterest.toStringAsFixed(2)}');
  print('');

  // Generate amortization schedule for first 3 months
  final schedule = FinancialCalculatorService.generateAmortizationSchedule(
    params: testParams,
  );

  print('--- First 3 Payments of Amortization Schedule ---');
  for (int i = 0; i < 3 && i < schedule.schedule.length; i++) {
    final entry = schedule.schedule[i];
    print('Payment ${entry.paymentNumber}:');
    print('  Payment: KSh ${entry.paymentAmount.toStringAsFixed(2)}');
    print('  Principal: KSh ${entry.principalPayment.toStringAsFixed(2)}');
    print('  Interest: KSh ${entry.interestPayment.toStringAsFixed(2)}');
    print('  Balance: KSh ${entry.remainingBalance.toStringAsFixed(2)}');
    print('');
  }

  // Test interest rate solver
  print('--- Testing Interest Rate Solver ---');
  final rateResult = FinancialCalculatorService.solveInterestRate(
    principal: 100000,
    paymentAmount: result.paymentAmount,
    termMonths: 12,
    paymentFrequency: PaymentFrequency.monthly,
    interestType: InterestType.reducingBalance,
  );

  if (rateResult.converged) {
    print(
      'Solved Interest Rate: ${(rateResult.annualRate * 100).toStringAsFixed(4)}%',
    );
    print('Expected Rate: ${testParams.annualRate!.toStringAsFixed(4)}%');
    print(
      'Difference: ${((rateResult.annualRate * 100) - testParams.annualRate!).abs().toStringAsFixed(6)}%',
    );
    print('Converged in ${rateResult.iterations} iterations');
  } else {
    print('Rate solver failed to converge');
  }

  // Manual verification calculation
  print('\n--- Manual Verification (First Payment) ---');
  final monthlyRate = testParams.annualRate! / 100 / 12;
  final manualInterest = testParams.principal * monthlyRate;
  final manualPrincipal = result.paymentAmount - manualInterest;
  print('Manual Interest: KSh ${manualInterest.toStringAsFixed(2)}');
  print('Manual Principal: KSh ${manualPrincipal.toStringAsFixed(2)}');
  print(
    'Schedule Interest: KSh ${schedule.schedule[0].interestPayment.toStringAsFixed(2)}',
  );
  print(
    'Schedule Principal: KSh ${schedule.schedule[0].principalPayment.toStringAsFixed(2)}',
  );
  print(
    'Match: ${(manualInterest - schedule.schedule[0].interestPayment).abs() < 0.01 ? "✓" : "✗"}',
  );
}

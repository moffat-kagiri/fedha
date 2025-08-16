import 'dart:math' as math;

/// Utility class for loan calculations
class LoanCalculator {
  /// Calculate monthly payment for a loan
  static double calculateMonthlyPayment({
    required double principal,
    required double annualInterestRate,
    required int termInMonths,
  }) {
    // Handle edge cases
    if (principal <= 0 || termInMonths <= 0) return 0;
    if (annualInterestRate <= 0) return principal / termInMonths;
    
    // Convert annual rate to monthly
    final monthlyRate = annualInterestRate / 100 / 12;
    
    // Amortization formula
    final payment = principal * 
        (monthlyRate * math.pow(1 + monthlyRate, termInMonths)) /
        (math.pow(1 + monthlyRate, termInMonths) - 1);
    
    return payment;
  }
  
  /// Calculate APR using Newton-Raphson method
  /// This works for both compound and reducing-balance loan models
  static double calculateApr({
    required double principal,
    required double payment,
    required int numberOfPayments,
    required int paymentsPerYear,
  }) {
    // If payment * numberOfPayments equals principal, interest rate is 0
    if ((payment * numberOfPayments - principal).abs() < 0.01) {
      return 0.0;
    }
    
    // Initial guess: 5% annual rate
    double rate = 0.05 / paymentsPerYear;
    double tolerance = 1e-8;
    int maxIterations = 100;
    
    for (int i = 0; i < maxIterations; i++) {
      double presentValue = _calculatePresentValue(payment, rate, numberOfPayments);
      double derivative = _calculateDerivative(payment, rate, numberOfPayments);
      
      if (derivative.abs() < tolerance) break;
      
      double newRate = rate - (presentValue - principal) / derivative;
      
      if ((newRate - rate).abs() < tolerance) {
        rate = newRate;
        break;
      }
      
      rate = newRate;
      
      // Ensure rate stays positive
      if (rate < 0) rate = 0.001 / paymentsPerYear;
      if (rate > 1) rate = 1.0; // Cap at 100% per period
    }
    
    // Convert periodic rate to effective annual percentage rate
    final effectiveAnnual = math.pow(1 + rate, paymentsPerYear) - 1;
    return effectiveAnnual * 100;
  }

  static double _calculatePresentValue(double payment, double rate, double periods) {
    if (rate.abs() < 1e-10) return payment * periods;
    return payment * (1 - math.pow(1 + rate, -periods)) / rate;
  }

  static double _calculateDerivative(double payment, double rate, double periods) {
    if (rate.abs() < 1e-10) return -payment * periods * (periods + 1) / 2;
    double factor1 = (1 - math.pow(1 + rate, -periods)) / (rate * rate);
    double factor2 = periods * math.pow(1 + rate, -periods - 1) / rate;
    return payment * (factor1 - factor2);
  }
  
  /// Calculate total interest paid over the life of a loan
  static double calculateTotalInterest({
    required double principal,
    required double payment,
    required int numberOfPayments,
  }) {
    return payment * numberOfPayments - principal;
  }
}

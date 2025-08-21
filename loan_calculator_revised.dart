import 'dart:math' as math;
import '../models/enums.dart';

/// Utility class for comprehensive loan calculations supporting multiple interest models
class LoanCalculator {
  /// Calculate periodic payment for a loan based on interest model
  static double calculatePayment({
    required double principal,
    required double annualInterestRate,
    required int termInYears,
    required int paymentsPerYear,
    required InterestModel interestModel,
  }) {
    // Validate inputs
    if (principal <= 0 || termInYears <= 0 || paymentsPerYear <= 0) return 0;
    
    final periodicRate = annualInterestRate / 100 / paymentsPerYear;
    final totalPayments = termInYears * paymentsPerYear;

    switch (interestModel) {
      case InterestModel.simple:
        return _calculateSimpleInterestPayment(
          principal,
          annualInterestRate,
          termInYears,
          paymentsPerYear,
        );
      case InterestModel.compound:
        return _calculateCompoundInterestPayment(
          principal,
          periodicRate,
          totalPayments,
        );
      case InterestModel.reducingBalance:
        return _calculateReducingBalancePayment(
          principal,
          periodicRate,
          totalPayments,
        );
    }
  }

  /// Calculate APR for specified interest model
  static double calculateApr({
    required double principal,
    required double payment,
    required int termInYears,
    required int paymentsPerYear,
    required InterestModel interestModel,
  }) {
    if (principal <= 0 || termInYears <= 0 || paymentsPerYear <= 0) return 0;

    final totalPayments = termInYears * paymentsPerYear;

    switch (interestModel) {
      case InterestModel.simple:
        return _calculateSimpleApr(
          principal,
          payment,
          totalPayments,
          paymentsPerYear,
        );
      case InterestModel.compound:
        return _calculateCompoundApr(
          principal,
          payment,
          totalPayments,
          paymentsPerYear,
        );
      case InterestModel.reducingBalance:
        return _calculateReducingBalanceApr(
          principal,
          payment,
          totalPayments,
          paymentsPerYear,
        );
    }
  }

  // Simple Interest Calculations
  static double _calculateSimpleInterestPayment(
    double principal,
    double annualRate,
    int termInYears,
    int paymentsPerYear,
  ) {
    final totalInterest = principal * (annualRate / 100) * termInYears;
    return (principal + totalInterest) / (termInYears * paymentsPerYear);
  }

  static double _calculateSimpleApr(
    double principal,
    double payment,
    int totalPayments,
    int paymentsPerYear,
  ) {
    final totalPaid = payment * totalPayments;
    final totalInterest = totalPaid - principal;
    final years = totalPayments / paymentsPerYear;
    return (totalInterest / principal / years) * 100;
  }

  // Compound Interest Calculations
  static double _calculateCompoundInterestPayment(
    double principal,
    double periodicRate,
    int totalPayments,
  ) {
    final totalAmount = principal * math.pow(1 + periodicRate, totalPayments);
    return totalAmount / totalPayments;
  }

  static double _calculateCompoundApr(
    double principal,
    double payment,
    int totalPayments,
    int paymentsPerYear,
  ) {
    final totalPaid = payment * totalPayments;
    final years = totalPayments / paymentsPerYear;
    final annualRate = (math.pow(totalPaid / principal, 1 / years) - 1) * 100;
    return annualRate;
  }

  // Reducing Balance (Amortized) Calculations
  static double _calculateReducingBalancePayment(
    double principal,
    double periodicRate,
    int totalPayments,
  ) {
    if (periodicRate == 0) return principal / totalPayments;
    
    return principal *
        (periodicRate * math.pow(1 + periodicRate, totalPayments)) /
        (math.pow(1 + periodicRate, totalPayments) - 1);
  }

  static double _calculateReducingBalanceApr(
    double principal,
    double payment,
    int totalPayments,
    int paymentsPerYear,
  ) {
    // Newton-Raphson method for iterative APR calculation
    double rate = 0.05 / paymentsPerYear; // Initial guess
    const double tolerance = 1e-8;
    const int maxIterations = 100;

    for (int i = 0; i < maxIterations; i++) {
      final pv = _calculatePresentValue(payment, rate, totalPayments.toDouble());
      final deriv = _calculateDerivative(payment, rate, totalPayments.toDouble());
      
      if (deriv.abs() < tolerance) break;
      
      final newRate = rate - (pv - principal) / deriv;
      if ((newRate - rate).abs() < tolerance) break;
      
      rate = newRate.clamp(0.001 / paymentsPerYear, 1.0);
    }

    final effectiveAnnual = math.pow(1 + rate, paymentsPerYear) - 1;
    return effectiveAnnual * 100;
  }

  // Helper methods for Newton-Raphson calculation
  static double _calculatePresentValue(double payment, double rate, double periods) {
    if (rate == 0) return payment * periods;
    return payment * (1 - math.pow(1 + rate, -periods)) / rate;
  }

  static double _calculateDerivative(double payment, double rate, double periods) {
    if (rate == 0) return -payment * periods * (periods + 1) / 2;
    return payment * (
      (math.pow(1 + rate, -periods) - 1) / (rate * rate) +
      periods * math.pow(1 + rate, -periods - 1) / rate
    );
  }

  /// Calculate total interest paid over the life of a loan
  static double calculateTotalInterest({
    required double principal,
    required double payment,
    required int totalPayments,
  }) {
    return (payment * totalPayments) - principal;
  }
}
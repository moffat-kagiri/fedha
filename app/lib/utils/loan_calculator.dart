import 'dart:math' as math;
import '../models/enums.dart';

/// Utility class for loan calculations
class LoanCalculator {
  /// Supported interest calculation models
  static const List<InterestModel> interestModels = InterestModel.values;
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
  /// Calculate APR for specified interest model
  /// [model] can be simple interest, compound interest, or reducing balance (amortized)
  static double calculateApr({
    required double principal,
    required double payment,
    required int numberOfPayments,
    required int paymentsPerYear,
    InterestModel model = InterestModel.reducingBalance,
  }) {
    // Compute years duration
    final years = numberOfPayments / paymentsPerYear;
    switch (model) {
      case InterestModel.simple:
        // Simple interest APR = (total interest / principal) / years
        final totalPaid = payment * numberOfPayments;
        final totalInterest = totalPaid - principal;
        if (principal <= 0 || years <= 0) return 0.0;
        return (totalInterest / principal) / years * 100;
      case InterestModel.compound:
        // Compound APR: (totalPaid/principal)^(1/years) - 1
        final totalPaidC = payment * numberOfPayments;
        if (principal <= 0 || years <= 0) return 0.0;
        final factor = totalPaidC / principal;
        final effective = math.pow(factor, 1 / years) - 1;
        return effective * 100;
      case InterestModel.reducingBalance:
      default:
        // Amortized (reducing balance) via Newton-Raphson
        if ((payment * numberOfPayments - principal).abs() < 0.01) {
          return 0.0;
        }
        double rate = 0.05 / paymentsPerYear;
        const double tolerance = 1e-8;
        const int maxIterations = 100;
        for (int i = 0; i < maxIterations; i++) {
          final pv = _calculatePresentValue(payment, rate, numberOfPayments.toDouble());
          final deriv = _calculateDerivative(payment, rate, numberOfPayments.toDouble());
          if (deriv.abs() < tolerance) break;
          final newRate = rate - (pv - principal) / deriv;
          if ((newRate - rate).abs() < tolerance) {
            rate = newRate;
            break;
          }
          rate = newRate;
          if (rate < 0) rate = 0.001 / paymentsPerYear;
          if (rate > 1) rate = 1.0;
        }
        final effectiveAnnual = math.pow(1 + rate, paymentsPerYear) - 1;
        return effectiveAnnual * 100;
    }
  }

  static double _calculatePresentValue(double payment, double rate, double periods) {
    if (rate.abs() < 1e-10) return payment * periods;
    return payment * (1 - math.pow(1 + rate, -periods)) / rate;
  }

  static double _calculateDerivative(double payment, double rate, double periods) {
    // Derivative of present value w.r.t rate for annuity PV = payment * (1 - (1+r)^-periods) / rate
    if (rate.abs() < 1e-10) {
      // When rate ~ 0, use Taylor-series approximation
      return -payment * periods * (periods + 1) / 2;
    }
    final q = math.pow(1 + rate, -periods);
    // numerator: d/dr [ (1 - q)/rate ] = (periods*rate*q/(1+rate) - (1 - q))
    final numerator = periods * rate * q / (1 + rate) - (1 - q);
    return payment * numerator / (rate * rate);
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

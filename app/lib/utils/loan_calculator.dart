import 'dart:math' as math;
import '../models/enums.dart';

/// Utility class for comprehensive loan calculations supporting multiple interest models
class LoanCalculator {
  /// Calculate periodic payment for a loan based on interest model
  static double calculatePayment({
    required double principal,
    required double annualInterestRate,
    required double termInYears,
    required int paymentsPerYear,
    required InterestModel interestModel,
  }) {
    // Validate inputs
    if (principal <= 0 || termInYears <= 0 || paymentsPerYear <= 0) return 0;
    final periodicRate = annualInterestRate / 100 / paymentsPerYear;
    // Convert term in years to total number of payments (rounded)
    final int totalPayments = (termInYears * paymentsPerYear).round();

    switch (interestModel) {
      case InterestModel.simple:
        return _calculateSimpleInterestPayment(
          principal,
          annualInterestRate,
          // termInYears may be fractional, convert to whole years
          termInYears.round(),
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
    required double termInYears,
    required int paymentsPerYear,
    required InterestModel interestModel,
  }) {
    if (principal <= 0 || termInYears <= 0 || paymentsPerYear <= 0) return 0;

  // Convert term in years to total number of payments (rounded)
    final int totalPayments = (termInYears * paymentsPerYear).round();

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
    // Compute APR from compound growth factor and ensure double type
    return (math.pow(totalPaid / principal, 1 / years) - 1).toDouble() * 100;
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
    // Handle edge cases
    if (principal <= 0 || payment <= 0 || totalPayments <= 0 || paymentsPerYear <= 0) {
      throw ArgumentError("All parameters must be positive");
    }
    
    // If payment is too small to pay off principal
    if (payment * totalPayments < principal) {
      throw ArgumentError("Payment is too small to pay off the principal");
    }
    
    // If payment exactly equals principal divided by payments (0% interest)
    if ((payment * totalPayments - principal).abs() < 1e-10) {
      return 0.0;
    }

    // Convert to monthly rate calculation
    double rateLower = 0.0;
    double rateUpper = 1.0; // 100% as upper bound
    double rate = 0.15 / paymentsPerYear; // Initial guess at 15% annual

    const int maxIterations = 100;
    const double tolerance = 1e-12;
    
    for (int i = 0; i < maxIterations; i++) {
      double balance = principal;
      double derivative = 0.0;
      double functionValue = -principal;
      
      // Calculate the present value and its derivative
      for (int period = 1; period <= totalPayments; period++) {
        double discountFactor = math.pow(1 + rate, period) as double;
        functionValue += payment / discountFactor;
        derivative -= period * payment / (discountFactor * (1 + rate));
      }
      
      // Check for convergence
      if (functionValue.abs() < tolerance) {
        break;
      }
      
      // Avoid division by zero
      if (derivative.abs() < tolerance) {
        // Use bisection method as fallback
        double rateMid = (rateLower + rateUpper) / 2;
        double fMid = _calculatePresentValue(principal, payment, totalPayments, rateMid);
        
        if (fMid > 0) {
          rateLower = rateMid;
        } else {
          rateUpper = rateMid;
        }
        
        rate = (rateLower + rateUpper) / 2;
      } else {
        // Newton-Raphson update
        double newRate = rate - functionValue / derivative;
        
        // Ensure the new rate is within bounds
        if (newRate <= rateLower || newRate >= rateUpper) {
          // If Newton-Raphson goes out of bounds, use bisection
          newRate = (rateLower + rateUpper) / 2;
        }
        
        // Update bounds
        double fNew = _calculatePresentValue(principal, payment, totalPayments, newRate);
        if (fNew > 0) {
          rateLower = newRate;
        } else {
          rateUpper = newRate;
        }
        
        rate = newRate;
      }
      
      // Check for convergence
      if ((rateUpper - rateLower) < tolerance) {
        break;
      }
    }
    
  // Return nominal APR (periodic rate * number of periods per year)
  return rate * paymentsPerYear * 100;
  }

  // Helper function to calculate present value
  static double _calculatePresentValue(
    double principal,
    double payment,
    int totalPayments,
    double rate
  ) {
    double pv = -principal;
    for (int period = 1; period <= totalPayments; period++) {
      pv += payment / (math.pow(1 + rate, period) as double);
    }
    return pv;
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

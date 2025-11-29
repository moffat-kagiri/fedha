import 'dart:math';
import '../data/app_database.dart';

/// Utility class for investment calculations: NPV, IRR, and annual profit margin.
class InvestmentCalculator {
  /// Calculates Net Present Value for given discount rate (as decimal) and cash flows.
  /// cashFlows[0] is time 0 (usually negative initial investment).
  static double npv(double discountRate, List<double> cashFlows) {
    double value = 0.0;
    for (int t = 0; t < cashFlows.length; t++) {
      value += cashFlows[t] / pow(1 + discountRate, t);
    }
    return value;
  }

  /// Estimates the Internal Rate of Return for a series of cash flows.
  /// Uses a simple bisection method between -0.99 and 1.0.
  static double irr(List<double> cashFlows,
      {double low = -0.99, double high = 1.0, int maxIter = 100, double tol = 1e-6}) {
    double mid = 0.0;
    for (int i = 0; i < maxIter; i++) {
      mid = (low + high) / 2;
      double value = npv(mid, cashFlows);
      if (value > 0) {
        low = mid;
      } else {
        high = mid;
      }
      if ((high - low).abs() < tol) break;
    }
    return mid;
  }

  /// Calculates average annual profit margin: (total inflows / -initial - 1) / years.
  /// Returns decimal (e.g. 0.12 for 12%).
  static double annualProfitMargin(List<double> cashFlows) {
    if (cashFlows.length < 2 || cashFlows[0] >= 0) return 0.0;
    final double initial = cashFlows[0]; // negative
    final int years = cashFlows.length - 1;
    final double totalInflows = cashFlows
        .sublist(1)
        .fold(0.0, (sum, cf) => sum + cf);
    final double ratio = totalInflows / -initial;
    return (ratio - 1) / years;
  }
}

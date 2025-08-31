import 'package:drift/drift.dart';

import '../app_database.dart';

extension BudgetExtensions on Budget {
  double get remainingAmount {
    final spent = spentAmount ?? 0.0;
    return limitMinor - spent;
  }
  
  double get spentPercentage {
    if (limitMinor <= 0) return 0.0;
    final spent = spentAmount ?? 0.0;
    return (spent / limitMinor * 100).clamp(0.0, 100.0);
  }

  bool get isOverBudget {
    final spent = spentAmount ?? 0.0;
    return spent > limitMinor;
  }
  
  double get totalBudget => limitMinor;
  double get totalSpent => spentAmount ?? 0.0;
  
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // Helper for currency formatting
  String get formattedLimit => "${(limitMinor / 100).toStringAsFixed(2)} $currency";
  String get formattedSpent => "${((spentAmount ?? 0.0) / 100).toStringAsFixed(2)} $currency";
  String get formattedRemaining => "${(remainingAmount / 100).toStringAsFixed(2)} $currency";
}

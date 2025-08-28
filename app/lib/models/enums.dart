// Removed json_annotation import and part directive since no generated code is needed for enums
// import 'package:json_annotation/json_annotation.dart';
// part 'enums.g.dart';

// Profile Types

enum ProfileType {
  personal,
  business,
  family,
  student
}

// Goal Types

enum GoalType {
  savings,
  debtReduction,
  insurance,
  emergencyFund,
  investment,
  other,
}

// Goal Status

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled
}

// Transaction Types

enum TransactionType {
  income,
  expense,
  savings,
}

// Payment Methods

enum PaymentMethod {
  cash,
  card,
  bank,
  mobile,
  online,
  cheque
}

// Transaction Categories

enum TransactionCategory {
  food,
  transport,
  entertainment,
  utilities,
  healthcare,
  shopping,
  education,
  business,
  investment,
  other
}

// Budget Periods

enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly
}

// Budget Status

enum BudgetStatus {
  active,
  inactive,
  exceeded,
  completed
}

// Invoice Status

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled
}

// Transaction Status

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded
}

// Recurring Type

enum RecurringType {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly
}

// Notification Type

enum NotificationType {
  transactionAlert,
  budgetWarning,
  goalProgress,
  billReminder,
  accountUpdate,
  securityAlert
}

// Account Type

enum AccountType {
  cash,
  bankAccount,
  creditCard,
  investment,
  loan,
  savings,
  mobile
}

// Interest calculation models

enum InterestModel {
  simple,
  compound,
  reducingBalance,
}

// Invoice Line Item
class InvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
    );
  }
}

// Budget Line Item
class BudgetLineItem {
  final String categoryId;
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;

  BudgetLineItem({
    required this.categoryId,
    required this.categoryName,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get spentPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount * 100).clamp(0.0, 100.0) : 0.0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
    };
  }

  factory BudgetLineItem.fromJson(Map<String, dynamic> json) {
    return BudgetLineItem(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      allocatedAmount: (json['allocated_amount'] ?? 0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
    );
  }
}


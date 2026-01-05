// enums.dart

enum ProfileType {
  personal,
  business,
  family,
  student
}

// Add the missing GoalPriority enum
enum GoalPriority {
  low,
  medium,
  high,
  critical,
}

enum GoalType {
  savings,
  debtReduction,
  insurance,
  emergencyFund,
  investment,
  other,
}

enum GoalStatus {
  active,
  completed,
  paused,
  cancelled
}

enum TransactionCategory {
  food,
  transport,
  utilities,
  entertainment,
  healthcare,
  groceries,
  diningOut,
  shopping,
  education,
  salary,
  business,
  investment,
  gift,
  otherIncome,
  otherExpense,
  emergencyFund,
  rent,
  retirement,
  other,
  savings,
  otherSavings,
  // Add other categories as needed
}

enum Type {
  income,
  expense,
  savings,
}

enum PaymentMethod {
  cash,
  card,
  bank,
  mobile,
  online,
  cheque
}

enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly
}

enum BudgetStatus {
  active,
  inactive,
  exceeded,
  completed
}

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded
}

enum RecurringType {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly
}

enum NotificationType {
  transactionAlert,
  budgetWarning,
  goalProgress,
  billReminder,
  accountUpdate,
  securityAlert
}

enum AccountType {
  cash,
  bankAccount,
  creditCard,
  investment,
  loan,
  savings,
  mobile
}

enum InterestModel {
  simple,
  compound,
  reducingBalance,
}

// In enums.dart
enum LoanStatus {
  active,
  paid,
  defaulted,
  negotiated,
}

// Add this extension if you want to get the string name
extension LoanStatusExtension on LoanStatus {
  String get name => toString().split('.').last;
}

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

class BudgetLineItem {
  final String category;
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;

  BudgetLineItem({
    required this.category,
    required this.categoryName,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
  });

  double get remainingAmount => allocatedAmount - spentAmount;
  double get spentPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount * 100).clamp(0.0, 100.0) : 0.0;
  bool get isOverBudget => spentAmount > allocatedAmount;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'category_name': categoryName,
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
    };
  }

  factory BudgetLineItem.fromJson(Map<String, dynamic> json) {
    return BudgetLineItem(
      category: json['category'] ?? '',
      categoryName: json['category_name'] ?? '',
      allocatedAmount: (json['allocated_amount'] ?? 0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
    );
  }
}

import 'package:hive/hive.dart';

part 'enums.g.dart';

// Profile Types
@HiveType(typeId: 20)
enum ProfileType {
  @HiveField(0)
  personal,
  @HiveField(1)
  business,
  @HiveField(2)
  family,
  @HiveField(3)
  student
}

// Goal Types
@HiveType(typeId: 21)
enum GoalType {
  @HiveField(0)
  savings,
  @HiveField(1)
  debtReduction,
  @HiveField(2)
  investment,
  @HiveField(3)
  expenseReduction,
  @HiveField(4)
  emergencyFund,
  @HiveField(5)
  incomeIncrease,
  @HiveField(6)
  retirement,
  @HiveField(7)
  other
}

// Goal Status
@HiveType(typeId: 22)
enum GoalStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  paused,
  @HiveField(3)
  cancelled
}

// Transaction Types
@HiveType(typeId: 23)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  transfer,
  @HiveField(3)
  savings
}

// Payment Methods
@HiveType(typeId: 24)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  card,
  @HiveField(2)
  bank,
  @HiveField(3)
  mobile,
  @HiveField(4)
  online,
  @HiveField(5)
  cheque
}

// Transaction Categories
@HiveType(typeId: 25)
enum TransactionCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  transport,
  @HiveField(2)
  entertainment,
  @HiveField(3)
  utilities,
  @HiveField(4)
  healthcare,
  @HiveField(5)
  shopping,
  @HiveField(6)
  education,
  @HiveField(7)
  business,
  @HiveField(8)
  investment,
  @HiveField(9)
  other
}

// Budget Periods
@HiveType(typeId: 31)
enum BudgetPeriod {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  quarterly,
  @HiveField(4)
  yearly
}

// Budget Status
@HiveType(typeId: 32)
enum BudgetStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  inactive,
  @HiveField(2)
  exceeded,
  @HiveField(3)
  completed
}

// Invoice Status
@HiveType(typeId: 26)
enum InvoiceStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  sent,
  @HiveField(2)
  paid,
  @HiveField(3)
  overdue,
  @HiveField(4)
  cancelled
}

// Transaction Status
@HiveType(typeId: 27)
enum TransactionStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  failed,
  @HiveField(3)
  cancelled,
  @HiveField(4)
  refunded
}

// Recurring Type
@HiveType(typeId: 28)
enum RecurringType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  biweekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  quarterly,
  @HiveField(5)
  yearly
}

// Notification Type
@HiveType(typeId: 29)
enum NotificationType {
  @HiveField(0)
  transactionAlert,
  @HiveField(1)
  budgetWarning,
  @HiveField(2)
  goalProgress,
  @HiveField(3)
  billReminder,
  @HiveField(4)
  accountUpdate,
  @HiveField(5)
  securityAlert
}

// Account Type
@HiveType(typeId: 30)
enum AccountType {
  @HiveField(0)
  cash,
  @HiveField(1)
  bankAccount,
  @HiveField(2)
  creditCard,
  @HiveField(3)
  investment,
  @HiveField(4)
  loan,
  @HiveField(5)
  savings,
  @HiveField(6)
  mobile
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

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

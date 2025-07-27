import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 6)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double budgetAmount;

  @HiveField(4)
  double spentAmount;

  @HiveField(5)
  String categoryId;

  @HiveField(6)
  String period; // 'monthly', 'weekly', 'yearly'

  @HiveField(7)
  DateTime startDate;

  @HiveField(8)
  DateTime endDate;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;
  
  @HiveField(12)
  bool isSynced;

  Budget({
    required this.id,
    required this.name,
    this.description,
    required this.budgetAmount,
    this.spentAmount = 0.0,
    required this.categoryId,
    this.period = 'monthly',
    this.isSynced = false,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  double get remainingAmount => budgetAmount - spentAmount;
  
  double get spentPercentage {
    if (budgetAmount <= 0) return 0.0;
    return (spentAmount / budgetAmount * 100).clamp(0.0, 100.0);
  }

  bool get isOverBudget => spentAmount > budgetAmount;
  
  // Additional getters expected by dashboard
  double get totalBudget => budgetAmount;
  double get totalSpent => spentAmount;
  
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'category_id': categoryId,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      budgetAmount: (json['budget_amount'] ?? 0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
      categoryId: json['category_id'] ?? '',
      period: json['period'] ?? 'monthly',
      startDate: json['start_date'] != null 
        ? DateTime.parse(json['start_date']) 
        : DateTime.now(),
      endDate: json['end_date'] != null 
        ? DateTime.parse(json['end_date']) 
        : DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Budget(id: $id, name: $name, spent: ${spentPercentage.toStringAsFixed(1)}%)';
  }
}

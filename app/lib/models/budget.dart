import 'package:json_annotation/json_annotation.dart';
part 'budget.g.dart';

@JsonSerializable()
class Budget {
  String id;
  String name;
  String? description;
  double budgetAmount;
  double spentAmount; 
  String categoryId;  
  String period; // 'monthly', 'weekly', 'yearly'  
  DateTime startDate;  
  DateTime endDate;  
  bool isActive;  
  DateTime createdAt;  
  DateTime updatedAt;  
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

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetToJson(this);
}

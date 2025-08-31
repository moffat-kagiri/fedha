import 'package:json_annotation/json_annotation.dart';
part 'budget.g.dart';

@JsonSerializable()
class Budget {
  String id;
  String name;
  double limitAmount;
  String? currency;
  String? categoryId;
  DateTime startDate;
  DateTime? endDate;
  bool? isRecurring;
  String profileId;
  double? spentAmount;  // Computed from transactions, not stored

  Budget({
    required this.id,
    required this.name,
    required this.limitAmount,
    this.currency = 'KES',
    this.categoryId,
    required this.startDate,
    this.endDate,
    this.isRecurring = false,
    required this.profileId,
    this.spentAmount = 0.0,
  });

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

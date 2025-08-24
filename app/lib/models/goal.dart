import 'enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal.g.dart';

@JsonSerializable()
class Goal {
  String id;
  String name;
  String? description;
  double targetAmount;
  double currentAmount;
  DateTime targetDate;
  String priority; // 'high', 'medium', 'low'
  String status; // 'active', 'completed', 'paused'
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
  GoalType goalType;
  String currency;
  String? profileId;
  bool isSynced;

  Goal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.priority = 'medium',
    this.status = 'active',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.goalType = GoalType.savings,
    this.currency = 'KES',
    this.profileId,
    this.isSynced = false,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'priority': priority,
      'status': status,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      targetAmount: (json['target_amount'] ?? 0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0).toDouble(),
      targetDate: json['target_date'] != null 
        ? DateTime.parse(json['target_date']) 
        : DateTime.now().add(const Duration(days: 365)),
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'active',
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
    return 'Goal(id: $id, name: $name, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}

@JsonSerializable()
class Budget {
   String id;
   String name;
   String? description;
   double budgetAmount;
   // … other fields, getters, constructors, toJson/fromJson, etc.
}

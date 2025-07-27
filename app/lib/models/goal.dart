import 'package:hive/hive.dart';
import 'enums.dart';

part 'goal.g.dart';

@HiveType(typeId: 5)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  DateTime targetDate;

  @HiveField(6)
  String priority; // 'high', 'medium', 'low'

  @HiveField(7)
  String status; // 'active', 'completed', 'paused'

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  GoalType goalType;

  @HiveField(12)
  String currency;

  @HiveField(13)
  String? profileId;
  
  @HiveField(14)
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

import 'enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal.g.dart';

/// Represents a financial goal with tracking capabilities
/// 
/// A Goal tracks progress towards a financial target with features for
/// contributions, progress calculation, and status management.
@JsonSerializable()
class Goal {
  /// Unique identifier for the goal
  final String id;

  /// Display name of the goal
  final String name;

  /// Optional description providing more context about the goal
  final String? description;

  /// Target amount to be saved/invested
  @JsonKey(name: 'target_amount')
  final double targetAmount;

  /// Current amount saved/invested towards the goal
  @JsonKey(name: 'current_amount')
  double currentAmount;

  /// Target completion date for the goal
  @JsonKey(name: 'target_date')
  final DateTime targetDate;

  /// Priority level of the goal
  final GoalPriority priority;

  /// Current status of the goal
  final GoalStatus status;

  /// Whether the goal is currently active
  @JsonKey(name: 'is_active')
  final bool isActive;

  /// Type/category of the goal
  @JsonKey(name: 'goal_type')
  final GoalType goalType;

  /// Currency code for the goal amounts (default: KES - Kenyan Shilling)
  final String currency;

  /// Associated profile ID (for multi-user support)
  @JsonKey(name: 'profile_id')
  final String? profileId;

  /// Whether the goal has been synced to remote server
  @JsonKey(name: 'is_synced')
  final bool isSynced;

  /// When the goal was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// When the goal was last updated
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  /// Creates a new financial goal
  Goal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.priority = GoalPriority.medium,
    this.status = GoalStatus.active,
    this.isActive = true,
    this.goalType = GoalType.savings,
    this.currency = 'KES',
    this.profileId,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Gets the progress percentage (0-100)
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Gets the remaining amount needed to complete the goal
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Checks if the goal has been completed (current >= target)
  bool get isCompleted => currentAmount >= targetAmount;

  /// Checks if the goal is overdue (past target date and not completed)
  bool get isOverdue => DateTime.now().isAfter(targetDate) && !isCompleted;

  /// Gets days remaining until target date (negative if overdue)
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  /// Adds a contribution to the goal and updates progress
  /// 
  /// [amount] - The amount to add (can be negative for withdrawals)
  /// Returns a new Goal instance with updated amounts
  Goal addContribution(double amount) {
    final newCurrentAmount = (currentAmount + amount).clamp(0.0, double.infinity);
    final newStatus = newCurrentAmount >= targetAmount ? GoalStatus.completed : status;
    
    return copyWith(
      currentAmount: newCurrentAmount,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy of this goal with updated fields
  Goal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    GoalPriority? priority,
    GoalStatus? status,
    bool? isActive,
    GoalType? goalType,
    String? currency,
    String? profileId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      goalType: goalType ?? this.goalType,
      currency: currency ?? this.currency,
      profileId: profileId ?? this.profileId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a Goal from JSON data
  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  /// Converts this Goal to JSON data
  Map<String, dynamic> toJson() => _$GoalToJson(this);

  /// Gets a human-readable progress description
  String get progressDescription {
    if (isCompleted) {
      return 'Goal completed!';
    } else if (progressPercentage >= 75) {
      return 'Almost there!';
    } else if (progressPercentage >= 50) {
      return 'Halfway there!';
    } else if (progressPercentage >= 25) {
      return 'Making progress';
    } else {
      return 'Getting started';
    }
  }

  /// Gets a display-friendly priority string
  String get priorityDisplay {
    switch (priority) {
      case GoalPriority.low:
        return 'Low';
      case GoalPriority.medium:
        return 'Medium';
      case GoalPriority.high:
        return 'High';
      case GoalPriority.critical:
        return 'Critical';
    }
  }

  /// Gets a display-friendly status string
  String get statusDisplay {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
    }
  }

  /// Gets a display-friendly type string
  String get typeDisplay {
    switch (goalType) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.investment:
        return 'Investment';
      case GoalType.debt:
        return 'Debt Repayment';
      case GoalType.emergency:
        return 'Emergency Fund';
      case GoalType.other:
        return 'Other';
    }
  }

  @override
  String toString() {
    return 'Goal(id: $id, name: $name, progress: ${progressPercentage.toStringAsFixed(1)}%, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
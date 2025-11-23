import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'goal.g.dart';

@JsonSerializable(explicitToJson: true)
class Goal {
  String id;
  String name;
  String? description;
  double targetAmount;
  double currentAmount;
  DateTime targetDate;
  DateTime? completedDate;
  DateTime createdAt;
  DateTime updatedAt;

  @JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson)
  final GoalPriority priority;

  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final GoalStatus status;

  GoalType goalType;
  String? icon;
  String profileId;

  Goal({
    String? id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.completedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    GoalPriority? priority,
    GoalStatus? status,
    required this.goalType,
    this.icon,
    required this.profileId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        priority = priority ?? GoalPriority.medium,
        status = status ?? GoalStatus.active;

  // Add these conversion methods for JSON serialization
  static GoalPriority _priorityFromJson(String priority) {
    return GoalPriority.values.firstWhere(
      (e) => e.toString().split('.').last == priority,
      orElse: () => GoalPriority.medium,
    );
  }

  static String _priorityToJson(GoalPriority priority) {
    return priority.toString().split('.').last;
  }

  static GoalStatus _statusFromJson(String status) {
    return GoalStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => GoalStatus.active,
    );
  }

  static String _statusToJson(GoalStatus status) {
    return status.toString().split('.').last;
  }

  /// Calculates the progress percentage towards the goal
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Checks if the goal is completed
  bool get isCompleted => status == GoalStatus.completed;

  /// Adds a contribution to the current amount and updates status if needed
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
    DateTime? completedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    GoalPriority? priority,
    GoalStatus? status,
    GoalType? goalType,
    String? icon,
    String? profileId,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      goalType: goalType ?? this.goalType,
      icon: icon ?? this.icon,
      profileId: profileId ?? this.profileId,
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

  // Fix the GoalType switch cases
  String get goalTypeName {
    switch (goalType) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.debtReduction:
        return 'Debt Reduction';
      case GoalType.investment:
        return 'Investment';
      case GoalType.emergencyFund:
        return 'Emergency Fund';
      case GoalType.insurance:
        return 'Insurance';
      case GoalType.other:
        return 'Other';
    }
  }

  IconData get goalTypeIcon {
    switch (goalType) {
      case GoalType.savings:
        return Icons.savings_rounded;
      case GoalType.debtReduction:
        return Icons.credit_card_off_rounded;
      case GoalType.investment:
        return Icons.trending_up_rounded;
      case GoalType.emergencyFund:
        return Icons.emergency_rounded;
      case GoalType.insurance:
        return Icons.health_and_safety_rounded;
      case GoalType.other:
        return Icons.flag_rounded;
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
      case GoalStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Gets a display-friendly type string
  String get typeDisplay {
    switch (goalType) {
      case GoalType.savings:
        return 'Savings';
      case GoalType.investment:
        return 'Investment';
      case GoalType.debtReduction:
        return 'Debt Repayment';
      case GoalType.emergencyFund:
        return 'Emergency Fund';
      case GoalType.insurance:
        return 'Insurance';
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
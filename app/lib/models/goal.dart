import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';
import 'package:uuid/uuid.dart';

part 'goal.g.dart';

@JsonSerializable(explicitToJson: true)
class Goal {
  final String? id; // Local Flutter UUID
  final String? remoteId; // PostgreSQL backend ID (nullable until synced)
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String profileId;
  final GoalType goalType;
  final GoalStatus status;
  final GoalPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final DateTime? completedDate;
  final String? currency;

  Goal({
    String? id,
    this.remoteId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.profileId,
    required this.goalType,
    this.status = GoalStatus.active,
    this.priority = GoalPriority.medium,
    DateTime? createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.completedDate,
    this.currency,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
  
  /// Check if goal has been synced to backend
  bool get hasRemoteId => remoteId != null && remoteId!.isNotEmpty;

  /// Calculates the progress percentage towards the goal
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount * 100).clamp(0.0, 100.0);
  }

  /// Checks if the goal is completed
  bool get isCompleted => status == GoalStatus.completed;

  /// Checks if goal is overdue
  bool get isOverdue => !isCompleted && targetDate.isBefore(DateTime.now());

  /// Days remaining until target date
  int get daysRemaining {
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  /// Amount needed to complete the goal
  double get amountNeeded => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Daily savings needed to reach goal on time
  double get dailySavingsNeeded {
    final days = daysRemaining;
    if (days <= 0) return amountNeeded;
    return amountNeeded / days;
  }

  /// Monthly savings needed to reach goal on time
  double get monthlySavingsNeeded {
    final months = (daysRemaining / 30).ceil();
    if (months <= 0) return amountNeeded;
    return amountNeeded / months;
  }

  /// Adds a contribution to the current amount and updates status if needed
  Goal addContribution(double amount) {
    final newCurrentAmount = (currentAmount + amount).clamp(0.0, targetAmount);
    final newStatus = newCurrentAmount >= targetAmount ? GoalStatus.completed : status;
    final newCompletedDate = newStatus == GoalStatus.completed ? DateTime.now() : completedDate;

    return copyWith(
      currentAmount: newCurrentAmount,
      status: newStatus,
      completedDate: newCompletedDate,
    );
  }

  /// Creates a copy of this goal with updated fields
  Goal copyWith({
    String? id,
    String? remoteId,
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
    String? profileId,
    bool? isSynced,
    String? currency,
  }) {
    return Goal(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      goalType: goalType ?? this.goalType,
      profileId: profileId ?? this.profileId,
      isSynced: isSynced ?? this.isSynced,
      currency: currency ?? this.currency,
    );
  }

  /// Empty goal factory constructor
  factory Goal.empty() {
    return Goal(
      name: 'Unnamed Goal',
      targetAmount: 0,
      currentAmount: 0,
      goalType: GoalType.savings,
      status: GoalStatus.active,
      targetDate: DateTime.now(),
      profileId: '',
      isSynced: false,
      currency: 'KES',
    );
  }

  /// Creates a Goal from JSON data
  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  /// Converts this Goal to JSON data
  Map<String, dynamic> toJson() => _$GoalToJson(this);

  // =============================================
  // ENHANCED GOAL TYPE ICON & THEME IMPLEMENTATION
  // =============================================

  /// Enhanced goal type information with icons, colors, and descriptions
  GoalTypeTheme get typeTheme {
    switch (goalType) {
      case GoalType.savings:
        return const GoalTypeTheme(
          icon: Icons.savings_rounded,
          color: Color(0xFF007A39), // Green
          description: 'Build your savings for future needs',
        );
      case GoalType.debtReduction:
        return const GoalTypeTheme(
          icon: Icons.credit_card_off_rounded,
          color: Color(0xFFD32F2F), // Red
          description: 'Pay down debts and reduce interest payments',
        );
      case GoalType.investment:
        return const GoalTypeTheme(
          icon: Icons.trending_up_rounded,
          color: Color(0xFF1976D2), // Blue
          description: 'Grow your wealth through investments',
        );
      case GoalType.emergencyFund:
        return const GoalTypeTheme(
          icon: Icons.emergency_rounded,
          color: Color(0xFFFF9800), // Orange
          description: 'Prepare for unexpected expenses',
        );
      case GoalType.insurance:
        return const GoalTypeTheme(
          icon: Icons.health_and_safety_rounded,
          color: Color(0xFF7B1FA2), // Purple
          description: 'Protect yourself and your assets',
        );
      case GoalType.other:
        return const GoalTypeTheme(
          icon: Icons.flag_rounded,
          color: Color(0xFF757575), // Grey
          description: 'Custom financial goal',
        );
    }
  }

  /// Gets the icon for this goal type
  IconData get icon => typeTheme.icon;

  /// Gets the color for this goal type
  Color get color => typeTheme.color;

  /// Gets a human-readable progress description
  String get progressDescription {
    if (isCompleted) {
      return 'Goal completed! 🎉';
    } else if (progressPercentage >= 90) {
      return 'Almost there! Just ${amountNeeded.toStringAsFixed(0)} left';
    } else if (progressPercentage >= 75) {
      return 'Great progress! ${progressPercentage.toStringAsFixed(0)}% complete';
    } else if (progressPercentage >= 50) {
      return 'Halfway there! Keep going';
    } else if (progressPercentage >= 25) {
      return 'Making steady progress';
    } else if (progressPercentage > 0) {
      return 'Getting started - every bit counts!';
    } else {
      return 'Ready to begin your journey';
    }
  }

  /// Gets a display-friendly priority string with emoji
  String get priorityDisplay {
    switch (priority) {
      case GoalPriority.low:
        return 'Low 🔽';
      case GoalPriority.medium:
        return 'Medium ⏸️';
      case GoalPriority.high:
        return 'High 🔼';
      case GoalPriority.critical:
        return 'Critical 🚨';
    }
  }

  /// Gets priority color
  Color get priorityColor {
    switch (priority) {
      case GoalPriority.low:
        return Colors.grey;
      case GoalPriority.medium:
        return Colors.blue;
      case GoalPriority.high:
        return Colors.orange;
      case GoalPriority.critical:
        return Colors.red;
    }
  }

  /// Enhanced goal type name with emoji
  String get goalTypeDisplay {
    switch (goalType) {
      case GoalType.savings:
        return 'Savings 💰';
      case GoalType.debtReduction:
        return 'Debt Reduction 💳';
      case GoalType.investment:
        return 'Investment 📈';
      case GoalType.emergencyFund:
        return 'Emergency Fund 🛡️';
      case GoalType.insurance:
        return 'Insurance 🏥';
      case GoalType.other:
        return 'Other 🎯';
    }
  }

  /// Simple goal type name (no emoji)
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

  /// Gets a display-friendly status string with icon
  String get statusDisplay {
    switch (status) {
      case GoalStatus.active:
        return isOverdue ? 'Overdue ⚠️' : 'Active 📍';
      case GoalStatus.completed:
        return 'Completed ✅';
      case GoalStatus.paused:
        return 'Paused ⏸️';
      case GoalStatus.cancelled:
        return 'Cancelled ❌';
    }
  }

  /// Status color
  Color get statusColor {
    switch (status) {
      case GoalStatus.active:
        return isOverdue ? Colors.orange : Colors.green;
      case GoalStatus.completed:
        return const Color(0xFF007A39);
      case GoalStatus.paused:
        return Colors.blueGrey;
      case GoalStatus.cancelled:
        return Colors.red;
    }
  }

  /// Progress color based on completion
  Color get progressColor {
    if (isCompleted) return const Color(0xFF007A39);
    if (isOverdue) return Colors.orange;
    if (progressPercentage >= 75) return Colors.green;
    if (progressPercentage >= 50) return Colors.lightGreen;
    if (progressPercentage >= 25) return Colors.yellow;
    return Colors.grey;
  }

  @override
  String toString() {
    return 'Goal(id: $id, remoteId: $remoteId, name: $name, progress: ${progressPercentage.toStringAsFixed(1)}%, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Goal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Gets the progress as a decimal (0.0 to 1.0)
  double get progress {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Gets progress as percentage string
  String get progressPercentageString {
    return '${progressPercentage.toStringAsFixed(1)}%';
  }

  /// Gets progress description with amount
  String get progressAmountDescription {
    return 'KSh ${currentAmount.toStringAsFixed(0)} of KSh ${targetAmount.toStringAsFixed(0)}';
  }

  /// Calculates how much to save per day to reach target
  double get requiredDailySavings {
    final days = daysRemaining;
    if (days <= 0) return amountNeeded;
    return amountNeeded / days;
  }

  /// Calculates how much to save per week
  double get requiredWeeklySavings {
    final weeks = (daysRemaining / 7).ceil();
    if (weeks <= 0) return amountNeeded;
    return amountNeeded / weeks;
  }

  /// Gets progress milestone (25%, 50%, 75%, 100%)
  String get progressMilestone {
    final percentage = progressPercentage;
    if (percentage >= 100) return '🎉 Goal Completed!';
    if (percentage >= 75) return 'Almost there! (75%+)';
    if (percentage >= 50) return 'Halfway there! (50%+)';
    if (percentage >= 25) return 'Good start! (25%+)';
    return 'Getting started';
  }

  /// Returns the date when goal will be completed at current rate
  DateTime? get estimatedCompletionDate {
    if (currentAmount == 0) return null;
    
    final daysSinceStart = DateTime.now().difference(createdAt).inDays;
    if (daysSinceStart == 0) return null;
    
    final dailyRate = currentAmount / daysSinceStart;
    if (dailyRate == 0) return null;
    
    final daysToComplete = amountNeeded / dailyRate;
    return DateTime.now().add(Duration(days: daysToComplete.ceil()));
  }

  /// Days since goal was created
  int get daysSinceStart {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Is goal on track to be completed by target date?
  bool get isOnTrack {
    if (isCompleted) return true;
    if (estimatedCompletionDate == null) return false;
    return estimatedCompletionDate!.isBefore(targetDate) || 
          estimatedCompletionDate!.isAtSameMomentAs(targetDate);
  }
}

// =============================================
// SUPPORTING CLASSES FOR ENHANCED THEMING
// =============================================

/// Enhanced theming information for goal types
class GoalTypeTheme {
  final IconData icon;
  final Color color;
  final String description;

  const GoalTypeTheme({
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Extension methods for Goal lists
extension GoalListExtensions on List<Goal> {
  /// Filter goals by status
  List<Goal> whereStatus(GoalStatus status) =>
      where((goal) => goal.status == status).toList();

  /// Filter goals by type
  List<Goal> whereType(GoalType type) =>
      where((goal) => goal.goalType == type).toList();

  /// Get active goals
  List<Goal> get active => whereStatus(GoalStatus.active);

  /// Get completed goals
  List<Goal> get completed => whereStatus(GoalStatus.completed);

  /// Get overdue goals
  List<Goal> get overdue => where((goal) => goal.isOverdue).toList();

  /// Sort by priority (critical to low)
  List<Goal> sortedByPriority() => List.of(this)
    ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

  /// Sort by due date (nearest first)
  List<Goal> sortedByDueDate() => List.of(this)
    ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

  /// Sort by progress (highest first)
  List<Goal> sortedByProgress() => List.of(this)
    ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));

  /// Total amount of all goals
  double get totalTargetAmount =>
      fold(0.0, (sum, goal) => sum + goal.targetAmount);

  /// Total current amount across all goals
  double get totalCurrentAmount =>
      fold(0.0, (sum, goal) => sum + goal.currentAmount);

  /// Overall progress percentage
  double get overallProgress {
    if (totalTargetAmount == 0) return 0.0;
    return (totalCurrentAmount / totalTargetAmount * 100).clamp(0.0, 100.0);
  }
}
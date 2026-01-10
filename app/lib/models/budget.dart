import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
part 'budget.g.dart';

@JsonSerializable()
class Budget {
  String id;
  String? remoteId; // ✅ ADDED: Backend ID for sync
  String name;
  String? description;
  double budgetAmount;
  double spentAmount; 
  String category;
  String profileId; // ✅ ADD THIS
  String period;
  DateTime startDate;
  DateTime endDate;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced; // ✅ ADD THIS
  String currency;
  Budget({
    required this.id,
    this.remoteId, // ✅ ADDED: Optional remote ID
    required this.name,
    this.description,
    required this.budgetAmount,
    this.spentAmount = 0.0,
    required this.category,
    required this.profileId, 
    this.period = 'monthly',
    this.isSynced = false, 
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.currency = 'KES',
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

  Budget copyWith({
    String? id,
    String? remoteId, // ✅ ADDED: Support remoteId in copyWith
    String? name,
    String? description,
    double? budgetAmount,
    double? spentAmount,
    String? category,
    String? profileId,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currency,
    }) {
    return Budget(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId, // ✅ ADDED: Copy remoteId
      name: name ?? this.name,
      description: description ?? this.description,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      category: category ?? this.category,
      profileId: profileId ?? this.profileId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? 'KES',
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
  
  /// Empty budget for comparison (used in sync operations)
  factory Budget.empty() {
    return Budget(
      id: '',
      name: '',
      budgetAmount: 0,
      category: '',
      profileId: '',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      currency: 'KES',
    );
  }

  // For local storage (simple)
  Map<String, dynamic> toLocalJson() {
    return _$BudgetToJson(this); // budgetAmount, spentAmount, etc.
  }

  // For Django API (snake_case)
  Map<String, dynamic> toJson() {
    final json = _$BudgetToJson(this);
    
    // Map to Django field names
    json['budget_amount'] = budgetAmount;
    json['spent_amount'] = spentAmount;
    json['start_date'] = startDate.toIso8601String();
    json['end_date'] = endDate.toIso8601String();
    json['is_active'] = isActive;
    json['is_synced'] = isSynced;
    
    // Remove Dart-specific fields
    json.remove('budgetAmount');
    json.remove('spentAmount');
    json.remove('startDate');
    json.remove('endDate');
    json.remove('isActive');
    json.remove('isSynced');
    
    return json;
  }

  // ADD fromJson for Django:
  factory Budget.fromDjangoJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id']?.toString() ?? '',
      remoteId: json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      budgetAmount: (json['budget_amount'] ?? 0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      profileId: json['profile']?.toString() ?? json['profile_id']?.toString() ?? '',
      period: json['period'] ?? 'monthly',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? true,
      isSynced: json['is_synced'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool isDateInRange(DateTime date) {
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isCurrent => isDateInRange(DateTime.now());

  String get statusDisplay {
    if (isUpcoming) return 'Upcoming';
    if (isExpired) return 'Completed';
    return 'Active';
  }

  Color get statusColor {
    if (isUpcoming) return Colors.blue;
    if (isExpired) return Colors.grey;
    return Colors.green;
  }
}

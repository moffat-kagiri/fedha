import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'loan.g.dart';

@JsonSerializable(explicitToJson: true)
class Loan {
  final String id;
  final String? remoteId;
  final String name;
  
  @JsonKey(name: 'principal_amount')
  final double principalAmount;
  
  final String currency;
  
  @JsonKey(name: 'interest_rate')
  final double interestRate;
  
  @JsonKey(name: 'interest_model')
  final String interestModel;
  
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  
  @JsonKey(name: 'profile_id')
  final String profileId;
  
  final String? description;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? deletedAt;  // ✅ NEW: Track when deleted
  final DateTime createdAt;
  final DateTime? updatedAt;
  Loan({
    String? id,
    this.remoteId,
    required this.name,
    required this.principalAmount,
    required this.currency,
    required this.interestRate,
    required this.interestModel,
    required this.startDate,
    required this.endDate,
    required this.profileId,
    this.description,
    this.isSynced = false,
    this.isDeleted = false,
    this.deletedAt,  // ✅ NEW
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Check if loan has been synced to backend
  bool get hasRemoteId => remoteId != null && remoteId!.isNotEmpty;

  /// Calculates the total interest over the loan term
  double get totalInterest {
    final years = endDate.difference(startDate).inDays / 365.0;
    return principalAmount * (interestRate / 100.0) * years;
  }

  /// Calculates the total repayment amount
  double get totalRepayment => principalAmount + totalInterest;

  /// Gets the monthly payment amount
  double get monthlyPayment {
    final months = (endDate.difference(startDate).inDays / 30.0).ceil();
    if (months == 0) return totalRepayment;
    return totalRepayment / months;
  }

  /// Checks if the loan is currently active (based on date range)
  bool get isActive {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  /// Checks if the loan is overdue
  bool get isOverdue => DateTime.now().isAfter(endDate);

  /// Days remaining until loan ends
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Months remaining
  int get monthsRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return ((endDate.difference(now).inDays) / 30).ceil();
  }

  /// Creates a copy of this loan with updated fields
  Loan copyWith({
    String? id,
    String? remoteId,
    String? name,
    double? principalAmount,
    String? currency,
    double? interestRate,
    String? interestModel,
    DateTime? startDate,
    DateTime? endDate,
    String? profileId,
    String? description,
    bool? isSynced,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      principalAmount: principalAmount ?? this.principalAmount,
      currency: currency ?? this.currency,
      interestRate: interestRate ?? this.interestRate,
      interestModel: interestModel ?? this.interestModel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileId: profileId ?? this.profileId,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Empty loan for comparison (used in sync operations)
  factory Loan.empty() {
    return Loan(
      name: '',
      principalAmount: 0.0,
      currency: 'KES',
      interestRate: 0.0,
      interestModel: 'simple',
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      profileId: '',
      id: '',
    );
  }

  /// Creates a Loan from JSON data
  factory Loan.fromJson(Map<String, dynamic> json) => _$LoanFromJson(json);

  /// Converts this Loan to JSON data
  Map<String, dynamic> toJson() => _$LoanToJson(this);

  /// Gets progress percentage (based on time elapsed)
  double get progressPercentage {
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) return 0.0;
    
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final percentage = (daysPassed / totalDays * 100).clamp(0.0, 100.0);
    
    return percentage;
  }

  /// Gets remaining balance (estimated based on time)
  double get remainingBalance {
    final progress = progressPercentage / 100.0;
    return totalRepayment * (1.0 - progress);
  }

  /// Display string for loan status based on dates
  String get statusDisplay {
    if (isOverdue) return 'Overdue ⚠️';
    if (isActive) return 'Active 📍';
    return 'Completed ✅';
  }

  /// Status color based on loan state
  Color get statusColor {
    if (isOverdue) return Colors.orange;
    if (isActive) return Colors.green;
    return const Color(0xFF007A39);
  }

  @override
  String toString() {
    return 'Loan(id: $id, remoteId: $remoteId, name: $name, '
        'principal: $principalAmount $currency, '
        'interest: ${interestRate.toStringAsFixed(1)}%, '
        'model: $interestModel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Loan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extension methods for Loan lists
extension LoanListExtensions on List<Loan> {
  /// Get active loans (currently within date range)
  List<Loan> get active => where((loan) => loan.isActive).toList();

  /// Get overdue loans (past end date)
  List<Loan> get overdue => where((loan) => loan.isOverdue).toList();

  /// Get completed loans (past end date but not overdue in status sense)
  List<Loan> get completed => where((loan) => !loan.isActive && !loan.isOverdue).toList();

  /// Sort by due date (nearest first)
  List<Loan> sortedByDueDate() => List.of(this)
    ..sort((a, b) => a.endDate.compareTo(b.endDate));

  /// Sort by principal amount (highest first)
  List<Loan> sortedByAmount() => List.of(this)
    ..sort((a, b) => b.principalAmount.compareTo(a.principalAmount));

  /// Sort by interest rate (highest first)
  List<Loan> sortedByInterestRate() => List.of(this)
    ..sort((a, b) => b.interestRate.compareTo(a.interestRate));

  /// Total principal amount of all loans
  double get totalPrincipalAmount =>
      fold(0.0, (sum, loan) => sum + loan.principalAmount);

  /// Total interest of all loans
  double get totalInterest =>
      fold(0.0, (sum, loan) => sum + loan.totalInterest);

  /// Total repayment amount
  double get totalRepayment => totalPrincipalAmount + totalInterest;
}
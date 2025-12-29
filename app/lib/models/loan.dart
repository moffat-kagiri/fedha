import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'loan.g.dart';

@JsonSerializable(explicitToJson: true)
class Loan {
  final String id; // Local Flutter UUID
  final String? remoteId; // PostgreSQL backend ID (nullable until synced)
  final String name;
  @JsonKey(name: 'principal_minor')
  final double principalMinor;
  final String currency;
  @JsonKey(name: 'interest_rate')
  final double interestRate;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'profile_id')
  final String profileId;
  
  @JsonKey(
    name: 'status',
    fromJson: _loanStatusFromJson,
    toJson: _loanStatusToJson,
  )
  final LoanStatus status;
  
  final String? description;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Loan({
    String? id,
    this.remoteId,
    required this.name,
    required this.principalMinor,
    required this.currency,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.profileId,
    this.status = LoanStatus.active,
    this.description,
    this.isSynced = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // JSON conversion helpers for LoanStatus enum
  static LoanStatus _loanStatusFromJson(String json) {
    return LoanStatus.values.firstWhere(
      (e) => e.name == json.toLowerCase(),
      orElse: () => LoanStatus.active,
    );
  }

  static String _loanStatusToJson(LoanStatus status) {
    return status.name;
  }

  /// Check if loan has been synced to backend
  bool get hasRemoteId => remoteId != null && remoteId!.isNotEmpty;

  /// Gets the principal amount in major units
  double get principalAmount => principalMinor / 100.0;

  /// Sets the principal amount in major units
  Loan withPrincipalAmount(double amount) {
    return copyWith(principalMinor: amount * 100);
  }

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

  /// Checks if the loan is active
  bool get isActive {
    final now = DateTime.now();
    return status == LoanStatus.active && 
           startDate.isBefore(now) && 
           endDate.isAfter(now);
  }

  /// Checks if the loan is overdue
  bool get isOverdue {
    final now = DateTime.now();
    return status == LoanStatus.active && endDate.isBefore(now);
  }

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
    double? principalMinor,
    String? currency,
    double? interestRate,
    DateTime? startDate,
    DateTime? endDate,
    String? profileId,
    LoanStatus? status,
    String? description,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      principalMinor: principalMinor ?? this.principalMinor,
      currency: currency ?? this.currency,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      profileId: profileId ?? this.profileId,
      status: status ?? this.status,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Creates a Loan from JSON data
  factory Loan.fromJson(Map<String, dynamic> json) => _$LoanFromJson(json);

  /// Converts this Loan to JSON data
  Map<String, dynamic> toJson() => _$LoanToJson(this);

  /// Gets a display-friendly status string with emoji
  String get statusDisplay {
    switch (status) {
      case LoanStatus.active:
        return isOverdue ? 'Overdue ⚠️' : 'Active 📍';
      case LoanStatus.paid:
        return 'Paid ✅';
      case LoanStatus.defaulted:
        return 'Defaulted ❌';
      case LoanStatus.negotiated:
        return 'Negotiated 🤝';
    }
  }

  /// Status color
  Color get statusColor {
    switch (status) {
      case LoanStatus.active:
        return isOverdue ? Colors.orange : Colors.green;
      case LoanStatus.paid:
        return const Color(0xFF007A39);
      case LoanStatus.defaulted:
        return Colors.red;
      case LoanStatus.negotiated:
        return Colors.purple;
    }
  }

  /// Gets progress percentage (for active loans)
  double get progressPercentage {
    if (status == LoanStatus.paid) return 100.0;
    
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) return 0.0;
    
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final percentage = (daysPassed / totalDays * 100).clamp(0.0, 100.0);
    
    return percentage;
  }

  /// Gets remaining balance (estimated)
  double get remainingBalance {
    if (status == LoanStatus.paid) return 0.0;
    
    final progress = progressPercentage / 100.0;
    return totalRepayment * (1.0 - progress);
  }

  @override
  String toString() {
    return 'Loan(id: $id, remoteId: $remoteId, name: $name, principal: ${principalAmount.toStringAsFixed(2)} $currency, interest: ${interestRate.toStringAsFixed(1)}%)';
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
  /// Filter loans by status
  List<Loan> whereStatus(LoanStatus status) =>
      where((loan) => loan.status == status).toList();

  /// Get active loans
  List<Loan> get active => where((loan) => loan.isActive).toList();

  /// Get overdue loans
  List<Loan> get overdue => where((loan) => loan.isOverdue).toList();

  /// Get paid loans
  List<Loan> get paid => whereStatus(LoanStatus.paid);

  /// Sort by due date (nearest first)
  List<Loan> sortedByDueDate() => List.of(this)
    ..sort((a, b) => a.endDate.compareTo(b.endDate));

  /// Sort by amount (highest first)
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
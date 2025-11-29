import 'package:json_annotation/json_annotation.dart';

part 'loan.g.dart';

/// Domain model for a loan, matching the Drift [Loans] table.
@JsonSerializable()
class Loan {
  /// Primary key (auto-incremented in the database).
  final int? id;

  /// Name or title of the loan.
  final String name;

  /// Principal amount in minor units (e.g., cents).
  @JsonKey(name: 'principal_minor')
  final double principalMinor;

  /// ISO 4217 currency code (e.g., 'KES', 'USD').
  final String currency;

  /// Interest rate as a percentage (e.g., 5.5 for 5.5%).
  @JsonKey(name: 'interest_rate')
  final double interestRate;

  /// Date the loan starts.
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  /// Date the loan ends or matures.
  @JsonKey(name: 'end_date')
  final DateTime endDate;

  /// Associated profile ID.
  @JsonKey(name: 'profile_id')
  final String profileId; 

  Loan({
    this.id,
    required this.name,
    required this.principalMinor,
    required this.currency,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.profileId,
  });

  /// Creates a new [Loan] from a JSON map.
  factory Loan.fromJson(Map<String, dynamic> json) => _$LoanFromJson(json);

  /// Converts this [Loan] into a JSON map.
  Map<String, dynamic> toJson() => _$LoanToJson(this);
}

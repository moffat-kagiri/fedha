import 'dart:math' as math;
import 'package:json_annotation/json_annotation.dart';

part 'money.g.dart';

/// A simple Money value object representing amounts in minor units (e.g., cents)
/// with a currency code.
@JsonSerializable()
class Money {
  /// Amount in minor units (e.g. cents).
  final int minorUnits;

  /// ISO 4217 currency code, e.g. 'USD', 'KES'.
  final String currency;

  const Money({
    required this.minorUnits,
    required this.currency,
  });

  /// Create Money from a decimal amount (major units) and currency.
  /// e.g. Money.fromDecimal(12.34, 'USD') => minorUnits = 1234
  factory Money.fromDecimal(
    double amount,
    String currency, {
    int fractionDigits = 2,
  }) {
    final factor = math.pow(10, fractionDigits).toDouble();
    final minor = (amount * factor).round();
    return Money(minorUnits: minor, currency: currency);
  }

  /// Creates a Money instance from JSON.
  factory Money.fromJson(Map<String, dynamic> json) =>
      _$MoneyFromJson(json);

  /// Converts this Money to JSON.
  Map<String, dynamic> toJson() => _$MoneyToJson(this);

  /// Returns the decimal (major units) representation.
  double toDecimal({int fractionDigits = 2}) {
    final factor = math.pow(10, fractionDigits).toDouble();
    return minorUnits / factor;
  }

  @override
  String toString() => '${toDecimal().toStringAsFixed(2)} $currency';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          minorUnits == other.minorUnits &&
          currency == other.currency;

  @override
  int get hashCode => minorUnits.hashCode ^ currency.hashCode;
}

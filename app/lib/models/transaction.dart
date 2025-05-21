// lib/models/transaction.dart
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class Transaction {
  @HiveField(0)
  final String uuid;
  @HiveField(1)
  final double amount;

  @HiveField(2)
  @JsonKey(
    name: 'type',
    toJson: _transactionTypeToJson,
    fromJson: _transactionTypeFromJson,
  )
  final TransactionType type;

  @HiveField(3)
  @JsonKey(
    name: 'category',
    toJson: _categoryToJson,
    fromJson: _categoryFromJson,
  )
  final TransactionCategory category;

  @HiveField(4)
  @JsonKey(name: 'date', toJson: _dateToJson, fromJson: _dateFromJson)
  final DateTime date;

  @HiveField(5)
  @JsonKey(name: 'notes')
  final String? notes;

  @HiveField(6)
  @JsonKey(name: 'is_synced', defaultValue: false)
  bool isSynced;

  @HiveField(7)
  @JsonKey(name: 'profile_id')
  final String profileId;

  Transaction({
    required this.amount,
    required this.type,
    required this.category,
    required this.profileId,
    this.notes,
    String? uuid,
    DateTime? date,
    this.isSynced = false,
  }) : uuid = uuid ?? const Uuid().v4(),
       date = date ?? DateTime.now();
  // Constructor for creating a transaction from JSON
  // JSON Serialization
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  // Type Converters
  static String _transactionTypeToJson(TransactionType type) => type.name;
  static TransactionType _transactionTypeFromJson(String json) =>
      TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == json.toLowerCase(),
        orElse: () => throw FormatException('Invalid TransactionType: $json'),
      );

  static String _categoryToJson(TransactionCategory category) => category.name;
  static TransactionCategory _categoryFromJson(String json) =>
      TransactionCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == json.toLowerCase(),
        orElse:
            () => throw FormatException('Invalid TransactionCategory: $json'),
      );

  // Date Converters (UTC for backend, local for app)
  static String _dateToJson(DateTime date) => date.toUtc().toIso8601String();
  static DateTime _dateFromJson(String json) => DateTime.parse(json).toLocal();

  @override
  String toString() {
    return 'Transaction(uuid: $uuid, amount: $amount, type: $type, '
        'category: $category, date: $date, profileId: $profileId)';
  }
}

// ... other parameters ...

// Enums with matching values to Django choices
// Enums with matching values to Django choices
enum TransactionType {
  income, // Maps to Django's 'IN'
  expense, // Maps to Django's 'EX'
}

enum TransactionCategory {
  sales, // Maps to Django's 'SALE'
  marketing, // Maps to Django's 'MRKT'
  groceries, // Maps to Django's 'GROC'
  rent, // Maps to Django's 'RENT'
  other, // Maps to Django's 'OTHR'
}

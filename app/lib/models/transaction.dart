// lib/models/transaction.dart
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
@JsonSerializable(explicitToJson: true)
class Transaction extends HiveObject {
  @HiveField(0)
  String uuid;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  TransactionCategory category;

  @HiveField(4)
  DateTime date;
  @HiveField(5)
  String? notes;

  @HiveField(6)
  String? description;

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  String profileId;

  @HiveField(9)
  DateTime updatedAt;
  Transaction({
    String? uuid,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    this.description,
    this.isSynced = false,
    required this.profileId,
    DateTime? updatedAt,
  }) : uuid = uuid ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime.now();
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
        'category: $category, date: $date, updatedAt: $updatedAt, profileId: $profileId)';
  }
}

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

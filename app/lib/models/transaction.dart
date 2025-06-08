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
  savings, // Maps to Django's 'SAV' - money transferred to savings
}

enum TransactionCategory {
  // Business Income Categories
  sales, // Maps to Django's 'SALE'
  services, // Maps to Django's 'SERV'
  // Personal Income Categories
  salary, // Maps to Django's 'SALY'
  freelance, // Maps to Django's 'FREE'
  gifts, // Maps to Django's 'GIFT'
  // Common Income Categories
  investments, // Maps to Django's 'INVT'
  // Business Expense Categories
  marketing, // Maps to Django's 'MRKT'
  equipment, // Maps to Django's 'EQUP'
  supplies, // Maps to Django's 'SUPL'
  professional_services, // Maps to Django's 'PROF'
  travel, // Maps to Django's 'TRVL'
  // Personal Expense Categories
  groceries, // Maps to Django's 'GROC'
  transportation, // Maps to Django's 'TRNS'
  healthcare, // Maps to Django's 'HLTH'
  entertainment, // Maps to Django's 'ENTR'
  education, // Maps to Django's 'EDUC'
  clothing, // Maps to Django's 'CLTH'
  dining, // Maps to Django's 'DINE'
  // Common Expense Categories
  rent, // Maps to Django's 'RENT'
  utilities, // Maps to Django's 'UTIL'
  other, // Maps to Django's 'OTHR'
}

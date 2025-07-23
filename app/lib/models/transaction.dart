// lib/models/transaction.dart
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
@JsonSerializable(explicitToJson: true)
class Transaction extends HiveObject {
  @HiveField(0)
  String uuid;

  @HiveField(1)
  String id;

  @HiveField(2)
  double amount;

  @HiveField(3)
  TransactionType type;

  @HiveField(4)
  String categoryId;

  @HiveField(5)
  TransactionCategory? category;

  @HiveField(6)
  DateTime date;
  
  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? description;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  String profileId;
  
  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  String? goalId; // For linking savings to goals
  
  @HiveField(13)
  String? smsSource;
  
  @HiveField(14)
  String? reference;
  
  @HiveField(15)
  String? recipient;
  
  @HiveField(16)
  bool isPending;
  
  @HiveField(17)
  bool isExpense;
  
  @HiveField(18)
  bool isRecurring;

  Transaction({
    String? uuid,
    String? id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.category,
    required this.date,
    this.notes,
    this.description,
    this.isSynced = false,
    required this.profileId,
    DateTime? updatedAt,
    this.goalId,
    this.smsSource,
    this.reference,
    this.recipient,
    this.isPending = false,
    this.isExpense = true,
    this.isRecurring = false,
  }) : uuid = uuid ?? const Uuid().v4(),
       id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime.now();
  // Constructor for creating a transaction from JSON
  // JSON Serialization
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  @override
  String toString() {
    return 'Transaction(uuid: $uuid, amount: $amount, type: $type, '
        'categoryId: $categoryId, date: $date, updatedAt: $updatedAt, profileId: $profileId)';
  }
}

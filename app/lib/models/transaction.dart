// lib/models/transaction.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'transaction.g.dart';

@JsonSerializable(explicitToJson: true)
  String uuid;
  String id;
  double amount;
  TransactionType type;
  String categoryId;
  TransactionCategory? category;
  DateTime date;
  String? notes;
  String? description;
  bool isSynced;
  String profileId;
  DateTime updatedAt;
  String? goalId; // For linking savings to goals
  String? smsSource;
  String? reference;
  String? recipient;
  bool isPending;
  bool isExpense;
  bool isRecurring;
  PaymentMethod? paymentMethod;

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
    this.paymentMethod,
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

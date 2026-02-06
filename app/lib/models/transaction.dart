// app/lib/models/transaction.dart - FIXED VERSION
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'transaction.g.dart';

@JsonSerializable(explicitToJson: true)
class Transaction {
  String? id; // Local unique identifier
  String? remoteId; // PostgreSQL backend ID (nullable until synced)
  double amount;
  @JsonKey(name: 'type')
  String type; // 'income', 'expense', 'savings', 'transfer'
  String category; // Category name as string
  DateTime date;
  DateTime createdAt;
  @JsonKey(name: 'budget_category')
  String? budgetCategory; // Budget category as string
  String? notes;
  String? description;
  bool isSynced;
  String profileId;
  DateTime updatedAt;
  String? goalId; // Goal ID or name as string
  String? smsSource;
  String? reference;
  String? recipient;
  bool isPending;
  bool? isExpense;
  bool isRecurring;
  String? paymentMethod;
  String? currency;
  String? status;
  String? merchantName;
  String? merchantCategory;
  String? tags;
  String? location;
  double? latitude;
  double? longitude;
  // ✅ NEW: Soft delete support
  bool isDeleted;
  DateTime? deletedAt;

  Transaction({
    String? id,
    this.remoteId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    DateTime? createdAt,
    this.budgetCategory,
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
    bool? isExpense,
    this.isRecurring = false,
    this.paymentMethod,
    this.currency,
    this.status,
    this.merchantName,
    this.merchantCategory,
    this.tags,
    this.location,
    this.latitude,
    this.longitude,
    // ✅ NEW: Soft delete
    this.isDeleted = false,
    this.deletedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        isExpense = isExpense ?? (type == 'expense'),
        updatedAt = updatedAt ?? DateTime.now() {
    // Initialize budgetCategory based on transaction type
    if (budgetCategory == null) {
      budgetCategory = switch (type) {
        'expense' => category.isNotEmpty ? category : 'other',
        'savings' => 'savings',
        _ => null,
      };
    }
  }

  /// Helper property for amount in minor units (cents)
  int get amountMinor => (amount * 100).round();

  /// Set amount from minor units
  set amountMinor(int minor) => amount = minor / 100.0;

  /// Copy with method
  Transaction copyWith({
    String? id,
    String? remoteId,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    String? budgetCategory,
    String? notes,
    String? description,
    bool? isSynced,
    String? profileId,
    DateTime? updatedAt,
    String? goalId,
    String? smsSource,
    String? reference,
    String? recipient,
    bool? isPending,
    bool? isExpense,
    bool? isRecurring,
    String? paymentMethod,
    String? currency,
    String? status,
    String? merchantName,
    String? merchantCategory,
    String? tags,
    String? location,
    double? latitude,
    double? longitude,
    // ✅ NEW: Soft delete
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      profileId: profileId ?? this.profileId,
      updatedAt: updatedAt ?? DateTime.now(),
      goalId: goalId ?? this.goalId,
      smsSource: smsSource ?? this.smsSource,
      reference: reference ?? this.reference,
      recipient: recipient ?? this.recipient,
      isPending: isPending ?? this.isPending,
      isExpense: isExpense ?? this.isExpense,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      merchantName: merchantName ?? this.merchantName,
      merchantCategory: merchantCategory ?? this.merchantCategory,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      // ✅ NEW: Soft delete
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  /// Empty transaction for comparison
  factory Transaction.empty() {
    return Transaction(
      amount: 0,
      type: 'income',
      category: '',
      date: DateTime.now(),
      profileId: '',
      id: '',
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, remoteId: $remoteId, amount: $amount, '
        'type: $type, category: $category, date: $date)';
  }
}
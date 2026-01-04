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
  @JsonKey(name: 'transaction_type')
  String transactionType; // 'income', 'expense', 'savings', 'transfer'
  String category; // Category name as string
  DateTime date;
  DateTime createdAt;
  @JsonKey(name: 'budget_category_id')
  String? budgetCategoryId; // Budget category as string
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

  Transaction({
    String? id,
    this.remoteId,
    required this.amount,
    required this.transactionType,
    required this.category,
    required this.date,
    DateTime? createdAt,
    this.budgetCategoryId,
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
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        isExpense = isExpense ?? (transactionType == 'expense'),
        updatedAt = updatedAt ?? DateTime.now() {
    // Initialize budgetCategoryId based on transaction type
    if (budgetCategoryId == null) {
      budgetCategoryId = switch (transactionType) {
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
    String? transactionType,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    String? budgetCategoryId,
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
  }) {
    return Transaction(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      budgetCategoryId: budgetCategoryId ?? this.budgetCategoryId,
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
      transactionType: 'income',
      category: '',
      date: DateTime.now(),
      profileId: '',
      id: '',
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, remoteId: $remoteId, amount: $amount, '
        'type: $transactionType, category: $category, date: $date)';
  }
}
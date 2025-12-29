import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'enums.dart';

part 'transaction.g.dart';

@JsonSerializable(explicitToJson: true)
class Transaction {
  String? id; // Local unique identifier
  String? remoteId; // PostgreSQL backend ID (nullable until synced)
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
  String? goalId;
  String? smsSource;
  String? reference;
  String? recipient;
  bool isPending;
  bool isExpense;
  bool isRecurring;
  PaymentMethod? paymentMethod;

  Transaction({
    String? id,  
    this.remoteId,      
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
    bool? isExpense,
    this.isRecurring = false,
    this.paymentMethod,
  }) : id = id ?? const Uuid().v4(),
      isExpense = isExpense ?? (type == TransactionType.expense),
      updatedAt = updatedAt ?? DateTime.now();

  // Helper method to ensure category is properly set
  Transaction withCategory(TransactionCategory category) {
    return Transaction(
      id: id,
      remoteId: remoteId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      category: category,
      date: date,
      notes: notes,
      description: description,
      isSynced: isSynced,
      profileId: profileId,
      updatedAt: updatedAt,
      goalId: goalId,
      smsSource: smsSource,
      reference: reference,
      recipient: recipient,
      isPending: isPending,
      isExpense: isExpense,
      isRecurring: isRecurring,
      paymentMethod: paymentMethod,
    );
  }

  // Improved constructor for SMS transactions
  factory Transaction.fromSmsCandidate({
    required double amount,
    required String description,
    required DateTime date,
    required TransactionType type,
    TransactionCategory? category,
    String? smsSource,
    String? profileId,
  }) {
    final categoryId = category?.name ?? 'other';
    
    return Transaction(
      amount: amount,
      type: type,
      categoryId: categoryId,
      category: category,
      date: date,
      description: description,
      smsSource: smsSource,
      profileId: profileId ?? '0',
      isExpense: type == TransactionType.expense,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
      
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  /// Returns a copy of this transaction with the given fields replaced.
  Transaction copyWith({
    String? id,
    String? remoteId, // Add remoteId
    double? amount,
    TransactionType? type,
    String? categoryId,
    TransactionCategory? category,
    DateTime? date,
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
    PaymentMethod? paymentMethod,
  }) {
    return Transaction(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      profileId: profileId ?? this.profileId,
      updatedAt: updatedAt ?? this.updatedAt,
      goalId: goalId ?? this.goalId,
      smsSource: smsSource ?? this.smsSource,
      reference: reference ?? this.reference,
      recipient: recipient ?? this.recipient,
      isPending: isPending ?? this.isPending,
      isExpense: isExpense ?? this.isExpense,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// Check if transaction has been synced to backend
  bool get hasRemoteId => remoteId != null && remoteId!.isNotEmpty;

  @override
  String toString() {
    return 'Transaction(id: $id, remoteId: $remoteId, amount: $amount, type: $type, '
        'category: $category, categoryId: $categoryId, date: $date, '
        'description: $description, isExpense: $isExpense)';
  }
}

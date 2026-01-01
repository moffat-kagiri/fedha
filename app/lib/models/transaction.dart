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
  DateTime createdAt; // ✅ When transaction was created
  String? budgetCategoryId;  
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
    DateTime? createdAt,
    
    // ✅ NEW: Add budgetCategoryId parameter
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
  }) : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
      isExpense = isExpense ?? (type == TransactionType.expense),
      updatedAt = updatedAt ?? DateTime.now() {
    // ✅ Initialize budgetCategoryId in constructor body
    if (budgetCategoryId == null) {
      budgetCategoryId = switch (type) {
        TransactionType.expense => 
          categoryId.isNotEmpty ? categoryId : 'other',
        TransactionType.savings => 'savings',
        _ => null,
      };
    }
  }

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
      createdAt: createdAt,
      budgetCategoryId: budgetCategoryId,
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
      // Let the main constructor handle budgetCategoryId default
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  
  /// Empty transaction for comparison (used in sync operations)
  factory Transaction.empty() {
    return Transaction(
      amount: 0,
      type: TransactionType.income,
      categoryId: '',
      date: DateTime.now(),
      profileId: '',
      id: '',
      budgetCategoryId: null,
    );
  }
      
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  /// Returns a copy of this transaction with the given fields replaced.
  Transaction copyWith({
    String? id,
    String? remoteId,
    double? amount,
    TransactionType? type,
    String? categoryId,
    TransactionCategory? category,
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
    PaymentMethod? paymentMethod,
  }) {
    // Handle type changes that affect isExpense
    final newType = type ?? this.type;
    final newIsExpense = isExpense ?? 
      (type != null ? (type == TransactionType.expense) : this.isExpense);
    
    return Transaction(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      amount: amount ?? this.amount,
      type: newType,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      budgetCategoryId: budgetCategoryId ?? this.budgetCategoryId,
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
      isExpense: newIsExpense,
      isRecurring: isRecurring ?? this.isRecurring,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// Check if transaction has been synced to backend
  bool get hasRemoteId => remoteId != null && remoteId!.isNotEmpty;

  /// Get display name for budget category
  String get budgetCategoryDisplayName {
    if (budgetCategoryId == null) return 'Unassigned';
    if (budgetCategoryId == 'other') return 'Other';
    if (budgetCategoryId == 'savings') return 'Savings';
    return budgetCategoryId!;
  }

  /// Check if transaction is assigned to a budget category
  bool get hasBudgetCategory => budgetCategoryId != null && budgetCategoryId!.isNotEmpty;

  @override
  String toString() {
    return 'Transaction(id: $id, remoteId: $remoteId, amount: $amount, type: $type, '
        'category: $category, categoryId: $categoryId, budgetCategoryId: $budgetCategoryId, '
        'date: $date, description: $description, isExpense: $isExpense)';
  }
}
import 'enums.dart';
import 'transaction.dart';
// Remove: import 'package:json_annotation/json_annotation.dart';
// Remove: import 'dart:core' as core;

// Remove: part 'transaction_candidate.g.dart';

// Helper functions for enum conversion - used by generated adapters
Type parseTransactionTypeString(String? typeStr) {
  if (typeStr == null) return Type.expense;
  
  switch (typeStr.toLowerCase()) {
    case 'income': return Type.income;
    case 'savings': return Type.savings;
    case 'expense':
    default: return Type.expense;
  }
}

TransactionStatus parseTransactionStatusString(String? statusStr) {
  if (statusStr == null) return TransactionStatus.pending;
  
  switch (statusStr.toLowerCase()) {
    case 'completed': return TransactionStatus.completed;
    case 'failed': return TransactionStatus.failed;
    case 'cancelled': return TransactionStatus.cancelled;
    case 'refunded': return TransactionStatus.refunded;
    case 'pending':
    default: return TransactionStatus.pending;
  }
}

// Remove: @JsonSerializable()
class TransactionCandidate {
  String id;
  String? rawText;
  double amount;
  String? description;
  String? category;
  DateTime date;
  Type type;
  TransactionStatus status;
  double confidence; // 0.0 to 1.0
  String? transactionId; // If approved and converted
  Map<String, dynamic>? metadata;
  DateTime createdAt;
  DateTime updatedAt;

  TransactionCandidate({
    required this.id,
    this.rawText,
    required this.amount,
    this.description,
    this.category,
    required this.date,
    required this.type,
    this.status = TransactionStatus.pending,
    this.confidence = 0.5,
    this.transactionId,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => status == TransactionStatus.pending;
  bool get isApproved => status == TransactionStatus.completed;
  bool get isRejected => status == TransactionStatus.cancelled;
  bool get isHighConfidence => confidence >= 0.8;
  bool get isLowConfidence => confidence < 0.5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raw_text': rawText,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'confidence': confidence,
      'transaction_id': transactionId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TransactionCandidate.fromJson(Map<String, dynamic> json) {
    return TransactionCandidate(
      id: json['id'] ?? '',
      rawText: json['raw_text'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      category: json['category'],
      date: json['date'] != null 
        ? DateTime.parse(json['date']) 
        : DateTime.now(),
      type: json['type'] is String 
        ? parseTransactionTypeString(json['type']) 
        : Type.expense,
      status: json['status'] is String 
        ? parseTransactionStatusString(json['status']) 
        : TransactionStatus.pending,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      transactionId: json['transaction_id'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : DateTime.now(),
    );
  }

  TransactionCandidate copyWith({
    String? id,
    String? rawText,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    Type? type,
    TransactionStatus? status,
    double? confidence,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionCandidate(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      transactionId: transactionId ?? this.transactionId,
      metadata: metadata ?? this.metadata,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TransactionCandidate(id: $id, amount: $amount, type: $type, status: $status, confidence: $confidence)';
  }
}


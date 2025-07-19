import 'package:hive/hive.dart';

part 'transaction_candidate.g.dart';

@HiveType(typeId: 8)
class TransactionCandidate extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? rawText;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? categoryId;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String type; // 'income', 'expense'

  @HiveField(7)
  String status; // 'pending', 'approved', 'rejected'

  @HiveField(8)
  double confidence; // 0.0 to 1.0

  @HiveField(9)
  String? transactionId; // If approved and converted

  @HiveField(10)
  Map<String, dynamic>? metadata;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  TransactionCandidate({
    required this.id,
    this.rawText,
    required this.amount,
    this.description,
    this.categoryId,
    required this.date,
    required this.type,
    this.status = 'pending',
    this.confidence = 0.5,
    this.transactionId,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isHighConfidence => confidence >= 0.8;
  bool get isLowConfidence => confidence < 0.5;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raw_text': rawText,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'type': type,
      'status': status,
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
      categoryId: json['category_id'],
      date: json['date'] != null 
        ? DateTime.parse(json['date']) 
        : DateTime.now(),
      type: json['type'] ?? 'expense',
      status: json['status'] ?? 'pending',
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
    String? categoryId,
    DateTime? date,
    String? type,
    String? status,
    double? confidence,
    String? transactionId,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionCandidate(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
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

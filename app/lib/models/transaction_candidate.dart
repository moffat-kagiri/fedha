import 'enums.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_candidate.g.dart';

// Helper functions for enum conversion - used by generated adapters
TransactionType parseTransactionTypeString(String? typeStr) {
  if (typeStr == null) return TransactionType.expense;
  
  switch (typeStr.toLowerCase()) {
    case 'income': return TransactionType.income;
    case 'savings': return TransactionType.savings;
    case 'expense':
    default: return TransactionType.expense;
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

@JsonSerializable()
class TransactionCandidate {
  String id;
  String? rawText;
  double amount;
  String? description;
  String? categoryId;
  DateTime date;
  TransactionType type;
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
    this.categoryId,
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
      'category_id': categoryId,
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
      categoryId: json['category_id'],
      date: json['date'] != null 
        ? DateTime.parse(json['date']) 
        : DateTime.now(),
      type: json['type'] is String 
        ? parseTransactionTypeString(json['type']) 
        : TransactionType.expense,
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
    String? categoryId,
    DateTime? date,
    TransactionType? type,
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
  
  // Helper methods for Hive type adapter
  static String transactionTypeToString(TransactionType type) {
    return type.toString().split('.').last;
  }
  
  static TransactionType stringToTransactionType(String typeStr) {
    return parseTransactionTypeString(typeStr);
  }
  
  static String transactionStatusToString(TransactionStatus status) {
    return status.toString().split('.').last;
  }
  
  static TransactionStatus stringToTransactionStatus(String statusStr) {
    return parseTransactionStatusString(statusStr);
  }
}

// Custom type adapter - will be used if build_runner doesn't generate one
  @override
  final int typeId = 8;

  @override
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return TransactionCandidate(
      id: fields[0] as String,
      rawText: fields[1] as String?,
      amount: fields[2] as double,
      description: fields[3] as String?,
      categoryId: fields[4] as String?,
      date: fields[5] as DateTime,
      type: fields[6] is String 
          ? TransactionCandidate.stringToTransactionType(fields[6] as String)
          : fields[6] as TransactionType,
      status: fields[7] is String 
          ? TransactionCandidate.stringToTransactionStatus(fields[7] as String)
          : fields[7] as TransactionStatus,
      confidence: fields[8] as double,
      transactionId: fields[9] as String?,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rawText)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(TransactionCandidate.transactionTypeToString(obj.type))
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.confidence)
      ..writeByte(9)
      ..write(obj.transactionId)
      ..writeByte(10)
      ..write(obj.metadata)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }
}

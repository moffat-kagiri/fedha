// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionCandidate _$TransactionCandidateFromJson(
  Map<String, dynamic> json,
) => TransactionCandidate(
  id: json['id'] as String,
  rawText: json['rawText'] as String?,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String?,
  categoryId: json['categoryId'] as String?,
  date: DateTime.parse(json['date'] as String),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  status:
      $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']) ??
      TransactionStatus.pending,
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
  transactionId: json['transactionId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TransactionCandidateToJson(
  TransactionCandidate instance,
) => <String, dynamic>{
  'id': instance.id,
  'rawText': instance.rawText,
  'amount': instance.amount,
  'description': instance.description,
  'categoryId': instance.categoryId,
  'date': instance.date.toIso8601String(),
  'type': _$TransactionTypeEnumMap[instance.type]!,
  'status': _$TransactionStatusEnumMap[instance.status]!,
  'confidence': instance.confidence,
  'transactionId': instance.transactionId,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.savings: 'savings',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.completed: 'completed',
  TransactionStatus.failed: 'failed',
  TransactionStatus.cancelled: 'cancelled',
  TransactionStatus.refunded: 'refunded',
};

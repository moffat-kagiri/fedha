// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  uuid: json['uuid'] as String?,
  id: json['id'] as String?,
  amount: (json['amount'] as num).toDouble(),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  categoryId: json['categoryId'] as String,
  category: $enumDecodeNullable(_$TransactionCategoryEnumMap, json['category']),
  date: DateTime.parse(json['date'] as String),
  notes: json['notes'] as String?,
  description: json['description'] as String?,
  isSynced: json['isSynced'] as bool? ?? false,
  profileId: json['profileId'] as String,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  goalId: json['goalId'] as String?,
  smsSource: json['smsSource'] as String?,
  reference: json['reference'] as String?,
  recipient: json['recipient'] as String?,
  isPending: json['isPending'] as bool? ?? false,
  isExpense: json['isExpense'] as bool? ?? true,
  isRecurring: json['isRecurring'] as bool? ?? false,
  paymentMethod: $enumDecodeNullable(
    _$PaymentMethodEnumMap,
    json['paymentMethod'],
  ),
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'id': instance.id,
      'amount': instance.amount,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'categoryId': instance.categoryId,
      'category': _$TransactionCategoryEnumMap[instance.category],
      'date': instance.date.toIso8601String(),
      'notes': instance.notes,
      'description': instance.description,
      'isSynced': instance.isSynced,
      'profileId': instance.profileId,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'goalId': instance.goalId,
      'smsSource': instance.smsSource,
      'reference': instance.reference,
      'recipient': instance.recipient,
      'isPending': instance.isPending,
      'isExpense': instance.isExpense,
      'isRecurring': instance.isRecurring,
      'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod],
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.savings: 'savings',
};

const _$TransactionCategoryEnumMap = {
  TransactionCategory.food: 'food',
  TransactionCategory.transport: 'transport',
  TransactionCategory.entertainment: 'entertainment',
  TransactionCategory.utilities: 'utilities',
  TransactionCategory.healthcare: 'healthcare',
  TransactionCategory.shopping: 'shopping',
  TransactionCategory.education: 'education',
  TransactionCategory.business: 'business',
  TransactionCategory.investment: 'investment',
  TransactionCategory.other: 'other',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
  PaymentMethod.bank: 'bank',
  PaymentMethod.mobile: 'mobile',
  PaymentMethod.online: 'online',
  PaymentMethod.cheque: 'cheque',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: json['id'] as String?,
  remoteId: json['remoteId'] as String?,
  amount: (json['amount'] as num).toDouble(),
  type: json['type'] as String,
  category: json['category'] as String,
  date: DateTime.parse(json['date'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  budgetCategory: json['budget_category'] as String?,
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
  isExpense: json['isExpense'] as bool?,
  isRecurring: json['isRecurring'] as bool? ?? false,
  paymentMethod: json['paymentMethod'] as String?,
  currency: json['currency'] as String?,
  status: json['status'] as String?,
  merchantName: json['merchantName'] as String?,
  merchantCategory: json['merchantCategory'] as String?,
  tags: json['tags'] as String?,
  location: json['location'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
)..amountMinor = (json['amountMinor'] as num).toInt();

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'remoteId': instance.remoteId,
      'amount': instance.amount,
      'type': instance.type,
      'category': instance.category,
      'date': instance.date.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'budget_category': instance.budgetCategory,
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
      'paymentMethod': instance.paymentMethod,
      'currency': instance.currency,
      'status': instance.status,
      'merchantName': instance.merchantName,
      'merchantCategory': instance.merchantCategory,
      'tags': instance.tags,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'amountMinor': instance.amountMinor,
    };

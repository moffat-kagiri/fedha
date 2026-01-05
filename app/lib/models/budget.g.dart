// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Budget _$BudgetFromJson(Map<String, dynamic> json) => Budget(
  id: json['id'] as String,
  remoteId: json['remoteId'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  budgetAmount: (json['budgetAmount'] as num).toDouble(),
  spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
  category: json['category'] as String,
  profileId: json['profileId'] as String,
  period: json['period'] as String? ?? 'monthly',
  isSynced: json['isSynced'] as bool? ?? false,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  isActive: json['isActive'] as bool? ?? true,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  currency: json['currency'] as String? ?? 'KES',
);

Map<String, dynamic> _$BudgetToJson(Budget instance) => <String, dynamic>{
  'id': instance.id,
  'remoteId': instance.remoteId,
  'name': instance.name,
  'description': instance.description,
  'budgetAmount': instance.budgetAmount,
  'spentAmount': instance.spentAmount,
  'category': instance.category,
  'profileId': instance.profileId,
  'period': instance.period,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isSynced': instance.isSynced,
  'currency': instance.currency,
};

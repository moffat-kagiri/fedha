// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Budget _$BudgetFromJson(Map<String, dynamic> json) => Budget(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  budgetAmount: (json['budgetAmount'] as num).toDouble(),
  spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0.0,
  categoryId: json['categoryId'] as String,
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
);

Map<String, dynamic> _$BudgetToJson(Budget instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'budgetAmount': instance.budgetAmount,
  'spentAmount': instance.spentAmount,
  'categoryId': instance.categoryId,
  'period': instance.period,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isSynced': instance.isSynced,
};

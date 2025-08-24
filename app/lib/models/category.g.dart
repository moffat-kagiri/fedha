// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  color: json['color'] as String? ?? '#2196F3',
  icon: json['icon'] as String? ?? 'category',
  type: json['type'] as String? ?? 'expense',
  isActive: json['isActive'] as bool? ?? true,
  isSynced: json['isSynced'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'color': instance.color,
  'icon': instance.icon,
  'type': instance.type,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isSynced': instance.isSynced,
};

Budget _$BudgetFromJson(Map<String, dynamic> json) => Budget()
  ..id = json['id'] as String
  ..name = json['name'] as String
  ..description = json['description'] as String?
  ..budgetAmount = (json['budgetAmount'] as num).toDouble();

Map<String, dynamic> _$BudgetToJson(Budget instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'budgetAmount': instance.budgetAmount,
};

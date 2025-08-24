// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Goal _$GoalFromJson(Map<String, dynamic> json) => Goal(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
  targetDate: DateTime.parse(json['targetDate'] as String),
  priority: json['priority'] as String? ?? 'medium',
  status: json['status'] as String? ?? 'active',
  isActive: json['isActive'] as bool? ?? true,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  goalType:
      $enumDecodeNullable(_$GoalTypeEnumMap, json['goalType']) ??
      GoalType.savings,
  currency: json['currency'] as String? ?? 'KES',
  profileId: json['profileId'] as String?,
  isSynced: json['isSynced'] as bool? ?? false,
);

Map<String, dynamic> _$GoalToJson(Goal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'targetDate': instance.targetDate.toIso8601String(),
  'priority': instance.priority,
  'status': instance.status,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'goalType': _$GoalTypeEnumMap[instance.goalType]!,
  'currency': instance.currency,
  'profileId': instance.profileId,
  'isSynced': instance.isSynced,
};

const _$GoalTypeEnumMap = {
  GoalType.savings: 'savings',
  GoalType.debtReduction: 'debtReduction',
  GoalType.insurance: 'insurance',
  GoalType.emergencyFund: 'emergencyFund',
  GoalType.investment: 'investment',
  GoalType.other: 'other',
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Goal _$GoalFromJson(Map<String, dynamic> json) => Goal(
  id: json['id'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  targetAmount: (json['targetAmount'] as num).toDouble(),
  currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
  targetDate: DateTime.parse(json['targetDate'] as String),
  completedDate: json['completedDate'] == null
      ? null
      : DateTime.parse(json['completedDate'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  priority: Goal._priorityFromJson(json['priority'] as String),
  status: Goal._statusFromJson(json['status'] as String),
  goalType: $enumDecode(_$GoalTypeEnumMap, json['goalType']),
  icon: json['icon'] as String?,
  profileId: json['profileId'] as String,
);

Map<String, dynamic> _$GoalToJson(Goal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'targetDate': instance.targetDate.toIso8601String(),
  'completedDate': instance.completedDate?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'priority': Goal._priorityToJson(instance.priority),
  'status': Goal._statusToJson(instance.status),
  'goalType': _$GoalTypeEnumMap[instance.goalType]!,
  'icon': instance.icon,
  'profileId': instance.profileId,
};

const _$GoalTypeEnumMap = {
  GoalType.savings: 'savings',
  GoalType.debtReduction: 'debtReduction',
  GoalType.insurance: 'insurance',
  GoalType.emergencyFund: 'emergencyFund',
  GoalType.investment: 'investment',
  GoalType.other: 'other',
};

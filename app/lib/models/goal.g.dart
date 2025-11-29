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
  profileId: json['profileId'] as String,
  goalType: $enumDecode(_$GoalTypeEnumMap, json['goalType']),
  status:
      $enumDecodeNullable(_$GoalStatusEnumMap, json['status']) ??
      GoalStatus.active,
  priority:
      $enumDecodeNullable(_$GoalPriorityEnumMap, json['priority']) ??
      GoalPriority.medium,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isSynced: json['isSynced'] as bool? ?? false,
  completedDate: json['completedDate'] == null
      ? null
      : DateTime.parse(json['completedDate'] as String),
);

Map<String, dynamic> _$GoalToJson(Goal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'targetAmount': instance.targetAmount,
  'currentAmount': instance.currentAmount,
  'targetDate': instance.targetDate.toIso8601String(),
  'profileId': instance.profileId,
  'goalType': _$GoalTypeEnumMap[instance.goalType]!,
  'status': _$GoalStatusEnumMap[instance.status]!,
  'priority': _$GoalPriorityEnumMap[instance.priority]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'isSynced': instance.isSynced,
  'completedDate': instance.completedDate?.toIso8601String(),
};

const _$GoalTypeEnumMap = {
  GoalType.savings: 'savings',
  GoalType.debtReduction: 'debtReduction',
  GoalType.insurance: 'insurance',
  GoalType.emergencyFund: 'emergencyFund',
  GoalType.investment: 'investment',
  GoalType.other: 'other',
};

const _$GoalStatusEnumMap = {
  GoalStatus.active: 'active',
  GoalStatus.completed: 'completed',
  GoalStatus.paused: 'paused',
  GoalStatus.cancelled: 'cancelled',
};

const _$GoalPriorityEnumMap = {
  GoalPriority.low: 'low',
  GoalPriority.medium: 'medium',
  GoalPriority.high: 'high',
  GoalPriority.critical: 'critical',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Loan _$LoanFromJson(Map<String, dynamic> json) => Loan(
  id: json['id'] as String?,
  remoteId: json['remoteId'] as String?,
  name: json['name'] as String,
  principalAmount: (json['principal_amount'] as num).toDouble(),
  currency: json['currency'] as String,
  interestRate: (json['interest_rate'] as num).toDouble(),
  interestModel: json['interest_model'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  profileId: json['profile_id'] as String,
  description: json['description'] as String?,
  isSynced: json['isSynced'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$LoanToJson(Loan instance) => <String, dynamic>{
  'id': instance.id,
  'remoteId': instance.remoteId,
  'name': instance.name,
  'principal_amount': instance.principalAmount,
  'currency': instance.currency,
  'interest_rate': instance.interestRate,
  'interest_model': instance.interestModel,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'profile_id': instance.profileId,
  'description': instance.description,
  'isSynced': instance.isSynced,
  'isDeleted': instance.isDeleted,
  'deletedAt': instance.deletedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

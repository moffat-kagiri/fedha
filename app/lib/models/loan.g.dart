// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Loan _$LoanFromJson(Map<String, dynamic> json) => Loan(
  id: json['id'] as String?,
  remoteId: json['remoteId'] as String?,
  name: json['name'] as String,
  principalMinor: (json['principal_minor'] as num).toDouble(),
  currency: json['currency'] as String,
  interestRate: (json['interest_rate'] as num).toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  profileId: json['profile_id'] as String,
  status: json['status'] == null
      ? LoanStatus.active
      : Loan._loanStatusFromJson(json['status'] as String),
  description: json['description'] as String?,
  isSynced: json['isSynced'] as bool? ?? false,
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
  'principal_minor': instance.principalMinor,
  'currency': instance.currency,
  'interest_rate': instance.interestRate,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'profile_id': instance.profileId,
  'status': Loan._loanStatusToJson(instance.status),
  'description': instance.description,
  'isSynced': instance.isSynced,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Loan _$LoanFromJson(Map<String, dynamic> json) => Loan(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  principalMinor: (json['principal_minor'] as num).toDouble(),
  currency: json['currency'] as String,
  interestRate: (json['interest_rate'] as num).toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  profileId: (json['profile_id'] as num).toInt(),
);

Map<String, dynamic> _$LoanToJson(Loan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'principal_minor': instance.principalMinor,
  'currency': instance.currency,
  'interest_rate': instance.interestRate,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'profile_id': instance.profileId,
};

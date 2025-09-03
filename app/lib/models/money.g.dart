// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Money _$MoneyFromJson(Map<String, dynamic> json) => Money(
  minorUnits: (json['minorUnits'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$MoneyToJson(Money instance) => <String, dynamic>{
  'minorUnits': instance.minorUnits,
  'currency': instance.currency,
};

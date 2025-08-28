// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String?,
  type: $enumDecode(_$ProfileTypeEnumMap, json['type']),
  password: json['password'] as String,
  baseCurrency: json['baseCurrency'] as String,
  timezone: json['timezone'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool,
  passwordHash: json['passwordHash'] as String?,
  lastLogin: DateTime.parse(json['lastLogin'] as String),
  lastSynced: json['lastSynced'] == null
      ? null
      : DateTime.parse(json['lastSynced'] as String),
  lastModified: json['lastModified'] == null
      ? null
      : DateTime.parse(json['lastModified'] as String),
  sessionToken: json['sessionToken'] as String?,
  preferences: json['preferences'] as Map<String, dynamic>?,
  displayName: json['displayName'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  photoUrl: json['photoUrl'] as String?,
  authToken: json['authToken'] as String?,
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'type': _$ProfileTypeEnumMap[instance.type]!,
  'password': instance.password,
  'baseCurrency': instance.baseCurrency,
  'timezone': instance.timezone,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'isActive': instance.isActive,
  'passwordHash': instance.passwordHash,
  'lastLogin': instance.lastLogin.toIso8601String(),
  'lastSynced': instance.lastSynced?.toIso8601String(),
  'lastModified': instance.lastModified?.toIso8601String(),
  'sessionToken': instance.sessionToken,
  'preferences': instance.preferences,
  'displayName': instance.displayName,
  'phoneNumber': instance.phoneNumber,
  'photoUrl': instance.photoUrl,
  'authToken': instance.authToken,
};

const _$ProfileTypeEnumMap = {
  ProfileType.personal: 'personal',
  ProfileType.business: 'business',
  ProfileType.family: 'family',
  ProfileType.student: 'student',
};

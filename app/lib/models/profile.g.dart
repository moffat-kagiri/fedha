// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 2;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String?,
      type: fields[3] as ProfileType,
      password: fields[4] as String,
      baseCurrency: fields[5] as String,
      timezone: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      isActive: fields[9] as bool,
      passwordHash: fields[10] as String?,
      lastLogin: fields[11] as DateTime,
      lastSynced: fields[12] as DateTime?,
      lastModified: fields[13] as DateTime?,
      sessionToken: fields[14] as String?,
      preferences: (fields[15] as Map?)?.cast<String, dynamic>(),
      displayName: fields[16] as String?,
      phoneNumber: fields[17] as String?,
      photoUrl: fields[18] as String?,
      authToken: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.baseCurrency)
      ..writeByte(6)
      ..write(obj.timezone)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.passwordHash)
      ..writeByte(11)
      ..write(obj.lastLogin)
      ..writeByte(12)
      ..write(obj.lastSynced)
      ..writeByte(13)
      ..write(obj.lastModified)
      ..writeByte(14)
      ..write(obj.sessionToken)
      ..writeByte(15)
      ..write(obj.preferences)
      ..writeByte(16)
      ..write(obj.displayName)
      ..writeByte(17)
      ..write(obj.phoneNumber)
      ..writeByte(18)
      ..write(obj.photoUrl)
      ..writeByte(19)
      ..write(obj.authToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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

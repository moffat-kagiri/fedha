// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 1;

  @override
  Profile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Profile(
      id: fields[0] as String,
      name: fields[1] as String?,
      type: fields[2] as ProfileType,
      pinHash: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      email: fields[6] as String?,
      baseCurrency: fields[7] as String?,
      timezone: fields[8] as String?,
      lastLogin: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.pinHash)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.baseCurrency)
      ..writeByte(8)
      ..write(obj.timezone)
      ..writeByte(9)
      ..write(obj.lastLogin);
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
      name: json['name'] as String?,
      type: $enumDecode(_$ProfileTypeEnumMap, json['type']),
      pinHash: json['pinHash'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      email: json['email'] as String?,
      baseCurrency: json['baseCurrency'] as String?,
      timezone: json['timezone'] as String?,
      lastLogin: json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ProfileTypeEnumMap[instance.type]!,
      'pinHash': instance.pinHash,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'email': instance.email,
      'baseCurrency': instance.baseCurrency,
      'timezone': instance.timezone,
      'lastLogin': instance.lastLogin?.toIso8601String(),
    };

const _$ProfileTypeEnumMap = {
  ProfileType.personal: 'personal',
  ProfileType.business: 'business',
};

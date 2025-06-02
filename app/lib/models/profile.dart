// app/lib/models/profile.dart
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

enum ProfileType {
  @HiveField(0)
  personal,
  @HiveField(1)
  business,
}

@HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class Profile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final ProfileType type;

  @HiveField(3)
  final String pinHash;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  @HiveField(6)
  final String? email;

  @HiveField(7)
  final String? baseCurrency;

  @HiveField(8)
  final String? timezone;

  @HiveField(9)
  final DateTime? lastLogin;

  Profile({
    required this.id,
    this.name,
    required this.type,
    required this.pinHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.email,
    this.baseCurrency,
    this.timezone,
    this.lastLogin,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  // Add PIN verification method
  bool verifyPin(String pin) {
    return _hashPin(pin) == pinHash;
  }

  // Private hash function
  String _hashPin(String pin) {
    return pin.split('').reversed.join();
  }

  @override
  String toString() {
    return 'Profile{id: $id, name: $name, type: $type, email: $email}';
  }
}

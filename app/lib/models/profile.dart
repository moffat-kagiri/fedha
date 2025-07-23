import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
@HiveType(typeId: 2)
class Profile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastLogin;

  @HiveField(5)
  final String pin;
  
  @HiveField(6)
  final String? phoneNumber;
  
  @HiveField(7)
  final String? photoUrl;
  
  @HiveField(8)
  final String? authToken;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.lastLogin,
    required this.pin,
    this.phoneNumber,
    this.photoUrl,
    this.authToken,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? name,
    String? email,
    DateTime? lastLogin,
    String? pin,
    String? phoneNumber,
    String? photoUrl,
    String? authToken,
  }) {
    return Profile(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      pin: pin ?? this.pin,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      authToken: authToken ?? this.authToken,
    );
  }
}

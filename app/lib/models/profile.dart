import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';

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
  final ProfileType type;

  @HiveField(4)
  final String pin;
  
  @HiveField(5)
  final String baseCurrency;
  
  @HiveField(6)
  final String timezone;
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime? updatedAt;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final String? passwordHash;
  
  @HiveField(11)
  final DateTime lastLogin;
  
  @HiveField(12)
  final DateTime? lastSynced;
  
  @HiveField(13)
  final DateTime? lastModified;
  
  @HiveField(14)
  final String? sessionToken;
  
  @HiveField(15)
  final Map<String, dynamic>? preferences;
  
  @HiveField(16)
  final String? displayName;
  
  // Additional fields from previous version
  final String? phoneNumber;
  final String? photoUrl;
  final String? authToken;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.pin,
    required this.baseCurrency,
    required this.timezone,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    this.passwordHash,
    required this.lastLogin,
    this.lastSynced,
    this.lastModified,
    this.sessionToken,
    this.preferences,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.authToken,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? name,
    String? email,
    ProfileType? type,
    String? pin,
    String? baseCurrency,
    String? timezone,
    DateTime? updatedAt,
    bool? isActive,
    String? passwordHash,
    DateTime? lastLogin,
    DateTime? lastSynced,
    DateTime? lastModified,
    String? sessionToken,
    Map<String, dynamic>? preferences,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? authToken,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      pin: pin ?? this.pin,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      passwordHash: passwordHash ?? this.passwordHash,
      lastLogin: lastLogin ?? this.lastLogin,
      lastSynced: lastSynced ?? this.lastSynced,
      lastModified: lastModified ?? this.lastModified,
      sessionToken: sessionToken ?? this.sessionToken,
      preferences: preferences ?? this.preferences,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      authToken: authToken ?? this.authToken,
    );
  }
  
  // Factory method to create a default profile
  factory Profile.defaultProfile({
    required String id,
    required String name,
    required String email,
    required String pin,
  }) {
    return Profile(
      id: id,
      name: name,
      email: email,
      type: ProfileType.personal,
      pin: pin,
      baseCurrency: 'KES',
      timezone: 'Africa/Nairobi',
      createdAt: DateTime.now(),
      isActive: true,
      lastLogin: DateTime.now(),
    );
  }
}

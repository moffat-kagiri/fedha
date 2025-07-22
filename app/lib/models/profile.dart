import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'enums.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
class Profile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? email;

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
  final DateTime updatedAt;

  @HiveField(9)
  final bool isActive;

  @HiveField(10)
  final String? passwordHash;

  @HiveField(11)
  final DateTime? lastLogin;

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

  Profile({
    required this.id,
    required this.name,
    this.email,
    required this.type,
    required this.pin,
    this.baseCurrency = 'KES',
    this.timezone = 'GMT+3',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
    this.passwordHash,
    this.lastLogin,
    this.lastSynced,
    this.lastModified,
    this.sessionToken,
    this.preferences,
    this.displayName,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Password hashing utility
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Password verification
  bool verifyPassword(String password) {
    if (passwordHash == null) return false;
    final hashedInput = hashPassword(password);
    return passwordHash == hashedInput;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_type': type.name,
      'pin': pin,
      'base_currency': baseCurrency,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'password_hash': passwordHash,
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      type: ProfileType.values.firstWhere(
        (e) => e.name == (json['profile_type'] ?? json['profileType'] ?? 'personal'),
        orElse: () => ProfileType.personal,
      ),
      pin: json['pin'] ?? '',
      baseCurrency: json['base_currency'] ?? json['baseCurrency'] ?? 'KES',
      timezone: json['timezone'] ?? 'GMT+3',
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      passwordHash: json['password_hash'],
      lastLogin: json['last_login'] != null
        ? DateTime.parse(json['last_login'])
        : null,
    );
  }

  Profile copyWith({
    String? id,
    String? name,
    String? email,
    ProfileType? type,
    String? pin,
    String? baseCurrency,
    String? timezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? passwordHash,
    DateTime? lastLogin,
    DateTime? lastSynced,
    DateTime? lastModified,
    String? sessionToken,
    Map<String, dynamic>? preferences,
    String? displayName,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      pin: pin ?? this.pin,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      passwordHash: passwordHash ?? this.passwordHash,
      lastLogin: lastLogin ?? this.lastLogin,
      lastSynced: lastSynced ?? this.lastSynced,
      lastModified: lastModified ?? this.lastModified,
      sessionToken: sessionToken ?? this.sessionToken,
      preferences: preferences ?? this.preferences,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, email: $email, type: $type)';
  }
}

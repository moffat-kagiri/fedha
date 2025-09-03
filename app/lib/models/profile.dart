import 'package:json_annotation/json_annotation.dart';
import 'enums.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final String id;
  final String name;
  final String? email;
  final ProfileType type;
  final String password;
  final String baseCurrency;
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? passwordHash;
  final DateTime lastLogin;
  final DateTime? lastSynced;
  final DateTime? lastModified;
  final String? sessionToken;
  final Map<String, dynamic>? preferences;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String? authToken;

  Profile({
    required this.id,
    required this.name,
    this.email,
    required this.type,
    required this.password,
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
  }) {
    // Ensure either email or phoneNumber is provided
    assert(email != null || phoneNumber != null, 
      'Either email or phoneNumber must be provided');
  }

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  Profile copyWith({
    String? name,
    String? email,
    ProfileType? type,
    String? password,
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
      password: password ?? this.password,
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
    String? email,
    String? phoneNumber,
    required String password,
  }) {
    assert(email != null || phoneNumber != null,
      'Either email or phoneNumber must be provided');
    
    return Profile(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      type: ProfileType.personal,
      password: password,
      baseCurrency: 'KES',
      timezone: 'Africa/Nairobi',
      createdAt: DateTime.now(),
      isActive: true,
      lastLogin: DateTime.now(),
    );
  }
}

// app/lib/models/profile.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'profile.g.dart';

@HiveType(typeId: 1)
class Profile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ProfileType type;

  @HiveField(2)
  final String pinHash;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime? _lastLogin;

  Profile({
    required this.type,
    required this.pinHash,
    String? id,
    required name,
    required email,
    required baseCurrency,
    required timezone,
  }) : id = id ?? const Uuid().v4(),
       createdAt = DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    type: ProfileType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ProfileType.personal,
    ),
    pinHash: json['pinHash'] ?? '',
    name: json['name'],
    email: json['email'],
    baseCurrency: json['baseCurrency'],
    timezone: json['timezone'],
  );

  DateTime? get lastLogin => _lastLogin;

  set lastLogin(DateTime? lastLogin) {
    _lastLogin = lastLogin;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'pinHash': pinHash,
    'createdAt': createdAt.toIso8601String(),
  };
}

enum ProfileType { business, personal }

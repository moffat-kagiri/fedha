// app/lib/models/profile.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'profile.g.dart';

@HiveType(typeId: 0)
class Profile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ProfileType type;

  @HiveField(2)
  final String pinHash;

  @HiveField(3)
  final DateTime createdAt;

  Profile({required this.type, required this.pinHash, String? id})
    : id = id ?? const Uuid().v4(),
      createdAt = DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    type: ProfileType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ProfileType.personal,
    ),
    pinHash: json['pinHash'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'pinHash': pinHash,
    'createdAt': createdAt.toIso8601String(),
  };
}

enum ProfileType { business, personal }

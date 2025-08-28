import 'package:json_annotation/json_annotation.dart';
part 'client.g.dart';

@JsonSerializable()
class Client {
  String id;
  String name;
  String? email;
  String? phone;
  String? address;
  String? notes;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;

  Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.isActive = true,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'is_active': isActive,
      'is_synced': isSynced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isSynced: json['is_synced'] ?? json['isSynced'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Client(id: $id, name: $name, email: $email)';
  }
}

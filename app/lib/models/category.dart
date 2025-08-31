import 'package:json_annotation/json_annotation.dart';
part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;  
  final String name;  
  final String iconKey;
  final String colorKey;
  final bool isExpense;
  final int sortOrder;
  final String profileId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Category({
    required this.id,
    required this.name,
    this.iconKey = 'default_icon',
    this.colorKey = 'default_color',
    this.isExpense = true,
    this.sortOrder = 0,
    required this.profileId,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_key': colorKey,
      'icon_key': iconKey,
      'is_expense': isExpense,
      'sort_order': sortOrder,
      'profile_id': profileId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      colorKey: json['color_key'] ?? '#2196F3',
      iconKey: json['icon_key'] ?? 'category',
      isExpense: json['is_expense'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      profileId: json['profile_id'] ?? '0',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, isExpense: $isExpense)';
  }
}

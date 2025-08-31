import 'package:json_annotation/json_annotation.dart';
part 'category.g.dart';

@JsonSerializable()
class Category {
  String id;  
  String name;  
  String iconKey;
  String colorKey;
  bool isExpense;
  int sortOrder;
  String profileId;
  
  Category({
    required this.id,
    required this.name,
    this.iconKey = 'default_icon',
    this.colorKey = 'default_color',
    this.isExpense = true,
    this.sortOrder = 0,
    required this.profileId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'type': type,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#2196F3',
      icon: json['icon'] ?? 'category',
      type: json['type'] ?? 'expense',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
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
    return 'Category(id: $id, name: $name, type: $type)';
  }
}

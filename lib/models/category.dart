import 'enums.dart';

class Category {
  final int? id;
  final String name;
  final String? description;
  final CategoryType type;
  final String icon;
  final String color;
  final int? parentId; // For subcategories
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    required this.name,
    this.description,
    required this.type,
    this.icon = '📂',
    this.color = '#2196F3',
    this.parentId,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'icon': icon,
      'color': color,
      'parentId': parentId,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: CategoryType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      icon: map['icon'] ?? '📂',
      color: map['color'] ?? '#2196F3',
      parentId: map['parentId'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Category copyWith({
    String? name,
    String? description,
    CategoryType? type,
    String? icon,
    String? color,
    int? parentId,
    bool? isActive,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, type: $type}';
  }
}

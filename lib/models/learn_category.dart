// lib/models/learn_category.dart

class LearnCategory {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int sortOrder;

  const LearnCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
    this.sortOrder = 0,
  });

  factory LearnCategory.fromMap(Map<String, dynamic> m) => LearnCategory(
        id: m['id'] as int,
        name: m['name'] as String,
        description: m['description'] as String?,
        iconName: m['icon_name'] as String?,
        colorHex: m['color_hex'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}

// lib/models/learn_category.dart
import '../core/json_utils.dart';

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
        id: requireField<int>(m, 'id', table: 'learn_categories'),
        name: requireField<String>(m, 'name', table: 'learn_categories'),
        description: m['description'] as String?,
        iconName: m['icon_name'] as String?,
        colorHex: m['color_hex'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );
}

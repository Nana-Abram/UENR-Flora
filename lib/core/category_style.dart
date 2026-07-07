// lib/core/category_style.dart
import 'package:flutter/material.dart';
import 'theme.dart';

/// Shared growth-type colour palette — used by the Home dashboard's
/// distribution donut/Featured Species pills and the Explorer's category
/// pills, so the same category always reads the same colour everywhere.
class CategoryStyle {
  final Color text;
  final Color bg;
  const CategoryStyle(this.text, this.bg);
}

const Map<String, CategoryStyle> kCategoryStyles = {
  'trees': CategoryStyle(kDeep, Color(0xFFE3EDE7)),
  'shrubs': CategoryStyle(kGreen, Color(0xFFE6F2EC)),
  'herbs': CategoryStyle(kAccent, kAccentL),
  'ornamental': CategoryStyle(Color(0xFF40916C), Color(0xFFE8F4EE)),
};

CategoryStyle categoryStyle(String? category) =>
    kCategoryStyles[category] ?? const CategoryStyle(kMu, kBg);

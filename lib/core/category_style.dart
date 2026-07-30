// lib/core/category_style.dart
import 'package:flutter/material.dart';
import 'theme.dart';

/// Shared growth-type colour palette — used by the Home dashboard's
/// distribution donut/Featured Species pills and the Explorer's category
/// pills, so the same category always reads the same colour everywhere.
///
/// This is deliberately separate from [colorPairForId] in constants.dart,
/// which colours each species' own card/placeholder background instead of
/// its category badge. They're not meant to be unified: this file answers
/// "what colour is the Trees/Herbs/etc. badge," constants.dart answers
/// "what colour is this specific species' card" — merging them would mean
/// either every species in a category sharing one placeholder colour, or
/// the category badge no longer matching across screens.
class CategoryStyle {
  final Color text;
  final Color bg;
  const CategoryStyle(this.text, this.bg);
}

// A function rather than a const map — every color referenced here
// (kDeep, kGreen, kAccent, kAccentL, kMu, kBg) resolves against the
// current AppBrightness, so this has to be rebuilt fresh on each call
// instead of built once at compile time.
Map<String, CategoryStyle> get kCategoryStyles => {
      'trees': CategoryStyle(kDeep, const Color(0xFFE3EDE7)),
      'shrubs': CategoryStyle(kGreen, const Color(0xFFE6F2EC)),
      'herbs': CategoryStyle(kAccent, kAccentL),
      'ornamental': const CategoryStyle(Color(0xFF40916C), Color(0xFFE8F4EE)),
    };

CategoryStyle categoryStyle(String? category) =>
    kCategoryStyles[category] ?? CategoryStyle(kMu, kBg);

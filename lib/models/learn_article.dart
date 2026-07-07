// lib/models/learn_article.dart
import 'package:flutter/material.dart';

class LearnArticle {
  final String id;
  final String heroAsset;
  final String category;
  final Color categoryColor;
  final String minutes;
  final String date;
  final String title;
  final List<String> paragraphs;
  final String? insightTitle;
  final String? insightBody;

  const LearnArticle({
    required this.id,
    required this.heroAsset,
    required this.category,
    required this.categoryColor,
    required this.minutes,
    required this.date,
    required this.title,
    required this.paragraphs,
    this.insightTitle,
    this.insightBody,
  });
}

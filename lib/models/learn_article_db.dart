// lib/models/learn_article_db.dart

class LearnArticleDb {
  final int id;
  final int? categoryId;
  final String title;
  final String summary;
  final String? body;
  final int readTimeMin;
  final bool isFeatured;
  final String? heroImageUrl;
  final int sortOrder;

  const LearnArticleDb({
    required this.id,
    this.categoryId,
    required this.title,
    required this.summary,
    this.body,
    this.readTimeMin = 3,
    this.isFeatured = false,
    this.heroImageUrl,
    this.sortOrder = 0,
  });

  factory LearnArticleDb.fromMap(Map<String, dynamic> m) => LearnArticleDb(
        id: m['id'] as int,
        categoryId: m['category_id'] as int?,
        title: m['title'] as String,
        summary: m['summary'] as String,
        body: m['body'] as String?,
        readTimeMin: (m['read_time_min'] as int?) ?? 3,
        isFeatured: (m['is_featured'] as bool?) ?? false,
        heroImageUrl: m['hero_image_url'] as String?,
        sortOrder: (m['sort_order'] as int?) ?? 0,
      );

  /// Splits the \n\n-separated body into display paragraphs.
  List<String> get paragraphs =>
      body?.split('\n\n').where((p) => p.trim().isNotEmpty).toList() ?? [];
}

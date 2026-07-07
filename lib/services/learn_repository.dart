// lib/services/learn_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learn_category.dart';
import '../models/learn_article_db.dart';

class LearnRepository {
  final SupabaseClient _client;
  LearnRepository(this._client);

  static const _cardFields =
      'id, category_id, title, summary, read_time_min, is_featured, hero_image_url, sort_order';

  Future<List<LearnCategory>> getCategories() async {
    final rows = await _client
        .from('learn_categories')
        .select()
        .order('sort_order');
    return rows.map((r) => LearnCategory.fromMap(r)).toList();
  }

  Future<List<LearnArticleDb>> getFeaturedArticles() async {
    final rows = await _client
        .from('learn_articles')
        .select(_cardFields)
        .eq('is_featured', true)
        .order('sort_order');
    return rows.map((r) => LearnArticleDb.fromMap(r)).toList();
  }

  Future<List<LearnArticleDb>> getAllArticles() async {
    final rows = await _client
        .from('learn_articles')
        .select(_cardFields)
        .order('sort_order');
    return rows.map((r) => LearnArticleDb.fromMap(r)).toList();
  }

  Future<LearnArticleDb> getArticleById(int id) async {
    final row = await _client
        .from('learn_articles')
        .select()
        .eq('id', id)
        .single();
    return LearnArticleDb.fromMap(row);
  }
}

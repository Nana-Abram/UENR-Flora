// lib/core/learn_provider.dart
import 'package:flutter/foundation.dart';
import '../models/learn_category.dart';
import '../models/learn_article_db.dart';
import '../services/learn_repository.dart';

class LearnProvider extends ChangeNotifier {
  final LearnRepository _repo;
  LearnProvider(this._repo) {
    _load();
  }

  List<LearnCategory> categories = [];
  List<LearnArticleDb> featuredArticles = [];
  List<LearnArticleDb> allArticles = [];
  int? selectedCategoryId;
  bool loading = true;
  String? error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  List<LearnArticleDb> get displayedArticles {
    Iterable<LearnArticleDb> result = allArticles;
    if (selectedCategoryId != null) {
      result = result.where((a) => a.categoryId == selectedCategoryId);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((a) =>
          a.title.toLowerCase().contains(q) || a.summary.toLowerCase().contains(q));
    }
    return result.toList();
  }

  void selectCategory(int? id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getCategories(),
        _repo.getFeaturedArticles(),
        _repo.getAllArticles(),
      ]);
      categories = results[0] as List<LearnCategory>;
      featuredArticles = results[1] as List<LearnArticleDb>;
      allArticles = results[2] as List<LearnArticleDb>;
    } catch (_) {
      error = 'Could not load learn content. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

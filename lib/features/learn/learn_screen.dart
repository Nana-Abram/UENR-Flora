// lib/features/learn/learn_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/learn_provider.dart';
import '../../models/learn_category.dart';
import '../../models/learn_article_db.dart';
import '../../widgets/breadcrumb.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(current: 'Learn'),
                    SizedBox(height: 16),
                    Text('Learn & Discover',
                        style: TextStyle(
                            fontFamily: kFontDisplay,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: kTx)),
                    SizedBox(height: 6),
                    Text(
                        'Environmental education modules and articles tailored to UENR students and researchers.',
                        style: TextStyle(fontSize: 14, color: kMu)),
                    SizedBox(height: 24),
                    _FeaturedBanner(),
                    SizedBox(height: 36),
                    _CategorySection(),
                    SizedBox(height: 36),
                    _ArticleSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_LearnFooter()],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FEATURED ARTICLE BANNER — auto-advances every 6 s
// ─────────────────────────────────────────────────────────────
class _FeaturedBanner extends StatefulWidget {
  const _FeaturedBanner();

  @override
  State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      final articles = context.read<LearnProvider>().featuredArticles;
      if (articles.length > 1 && mounted) {
        setState(() => _index = (_index + 1) % articles.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final learn = context.watch<LearnProvider>();

    // Loading skeleton
    if (learn.loading) {
      return Container(
        height: 170,
        decoration: BoxDecoration(
          color: kDeep.withValues(alpha: 0.15),
          borderRadius: kBR2xl,
        ),
      );
    }

    if (learn.featuredArticles.isEmpty) return const SizedBox.shrink();

    final articles = learn.featuredArticles;
    if (_index >= articles.length) _index = 0;
    final article = articles[_index];

    final categoryName = learn.categories
        .where((c) => c.id == article.categoryId)
        .map((c) => c.name)
        .firstOrNull ?? 'Learn';

    return GestureDetector(
      onTap: () => context.go('/learn/article/${article.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kDeep, Color(0xFF0D2318)],
          ),
          borderRadius: kBR2xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_outlined,
                    size: 14, color: Color(0xFFFAC775)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(categoryName.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFAC775),
                          letterSpacing: 0.4)),
                ),
                Text('${article.readTimeMin} min read',
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 14),
            Text(article.title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4)),
            const SizedBox(height: 10),
            Text(article.summary,
                style: const TextStyle(
                    fontSize: 13, color: Colors.white70, height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Read article',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFAC775))),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward,
                    size: 14, color: Color(0xFFFAC775)),
                const Spacer(),
                // Dot indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(articles.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: active ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFAC775)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXPLORE TOPICS — categories from Supabase
// ─────────────────────────────────────────────────────────────
class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    final learn = context.watch<LearnProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Explore Topics',
                style: TextStyle(
                    fontFamily: kFontDisplay,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: kTx)),
            if (learn.selectedCategoryId != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<LearnProvider>().selectCategory(null),
                child: const Text('Show all',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreen)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (learn.loading)
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: kLight,
              borderRadius: kBRLg,
            ),
          )
        else if (learn.categories.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= kBreakpointLg
                  ? 3
                  : constraints.maxWidth >= kBreakpointMd
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: cols == 1 ? 3.4 : 2.9,
                ),
                itemCount: learn.categories.length,
                itemBuilder: (_, i) =>
                    _CategoryCard(category: learn.categories[i]),
              );
            },
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final LearnCategory category;
  const _CategoryCard({required this.category});

  static IconData _iconFromName(String? name) => switch (name) {
        'forest'      => Icons.forest,
        'healing'     => Icons.healing,
        'park'        => Icons.park,
        'agriculture' => Icons.agriculture,
        'eco'         => Icons.eco_outlined,
        'history_edu' => Icons.history_edu,
        'science'     => Icons.science_outlined,
        'cloud'       => Icons.cloud_outlined,
        _             => Icons.local_florist_outlined,
      };

  static Color _colorFromHex(String? hex) {
    if (hex == null || hex.length != 7) return kDeep;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _colorFromHex(category.colorHex);
    final isSelected =
        context.watch<LearnProvider>().selectedCategoryId == category.id;

    return InkWell(
      borderRadius: kBRLg,
      onTap: () => context
          .read<LearnProvider>()
          .selectCategory(isSelected ? null : category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.06) : kWhite,
          border: Border.all(
              color: isSelected ? iconColor : kBorder,
              width: isSelected ? 1.5 : 0.5),
          borderRadius: kBRLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: kBRMd),
              child: Icon(_iconFromName(category.iconName),
                  size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(category.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kTx)),
                      ),
                      Icon(
                          isSelected
                              ? Icons.check_circle_outline
                              : Icons.chevron_right,
                          size: 17,
                          color: isSelected ? iconColor : kMu),
                    ],
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 5),
                    Text(category.description!,
                        style:
                            const TextStyle(fontSize: 12, color: kMu, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ARTICLES — filtered by selected category
// ─────────────────────────────────────────────────────────────
class _ArticleSection extends StatelessWidget {
  const _ArticleSection();

  @override
  Widget build(BuildContext context) {
    final learn = context.watch<LearnProvider>();
    final articles = learn.displayedArticles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Featured Articles',
            style: TextStyle(
                fontFamily: kFontDisplay,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kTx)),
        const SizedBox(height: 18),
        if (learn.loading)
          Container(height: 200, decoration: BoxDecoration(color: kLight, borderRadius: kBRXl))
        else if (learn.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(learn.error!,
                    style: const TextStyle(fontSize: 13, color: kMu)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<LearnProvider>().reload(),
                  child: const Text('Retry',
                      style: TextStyle(fontSize: 13, color: kGreen)),
                ),
              ],
            ),
          )
        else if (articles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No articles in this category yet.',
                style: TextStyle(fontSize: 13, color: kMu)),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= kBreakpointLg
                  ? 3
                  : constraints.maxWidth >= kBreakpointMd
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: cols == 1 ? 1.8 : 1.2,
                ),
                itemCount: articles.length,
                itemBuilder: (_, i) => _ArticleCard(article: articles[i]),
              );
            },
          ),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final LearnArticleDb article;
  const _ArticleCard({required this.article});

  Widget _placeholder() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xD92D6A4F), Color(0xFF0D2318)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_stories_outlined, size: 32, color: kMint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: kBRXl,
      onTap: () => context.go('/learn/article/${article.id}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder, width: 0.5),
          borderRadius: kBRXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: article.heroImageUrl != null
                  ? Image.network(
                      article.heroImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (article.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: kLight,
                            borderRadius: kBRPill,
                          ),
                          child: const Text('Featured',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: kDeep)),
                        ),
                      if (article.isFeatured) const SizedBox(width: 8),
                      Text('${article.readTimeMin} min',
                          style: const TextStyle(fontSize: 11, color: kMu)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(article.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTx,
                          height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(article.summary,
                      style: const TextStyle(fontSize: 11, color: kMu, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────
class _LearnFooter extends StatelessWidget {
  const _LearnFooter();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 20),
        child: const Text(
          'UENR Flora Environmental Learning Hub · Group 4 Final Year Project',
          style: TextStyle(fontSize: 11, color: kMu),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

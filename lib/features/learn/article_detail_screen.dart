// lib/features/learn/article_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/learn_provider.dart';
import '../../models/learn_article_db.dart';
import '../../services/learn_repository.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/read_aloud_button.dart';
import '../profile/providers/profile_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  LearnArticleDb? _article;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read<LearnRepository>();
      final article = await repo.getArticleById(widget.articleId);
      if (mounted) {
        setState(() { _article = article; _loading = false; });
        unawaited(context.read<ProfileProvider>().recordArticleRead(widget.articleId));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load article. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: kDeep, strokeWidth: 3),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(fontSize: 13, color: kMu)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _load();
              },
              child: Text('Retry', style: TextStyle(color: kGreen)),
            ),
          ],
        ),
      );
    }

    final article = _article!;
    final categories = context.read<LearnProvider>().categories;
    final category = categories.where((c) => c.id == article.categoryId).firstOrNull;
    final categoryName = category?.name ?? 'Article';
    final categoryColor = _colorFromHex(category?.colorHex);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            // A single 760-wide reading column (breadcrumb row and body
            // alike), centered as one block — previously only _ArticleBody
            // itself was constrained to 760 while this outer wrapper used
            // kMaxContentWidth (1400) with crossAxisAlignment.start, so on
            // any desktop viewport near/above 1400 the whole column (and
            // the narrower body inside it) hugged the left edge instead of
            // centering, with a large empty gap on the right. Mobile never
            // showed this since the viewport itself was already narrower
            // than 760.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Breadcrumb(current: 'Learn'),
                        ReadAloudButton(
                          textBuilder: () =>
                              '${article.title}. ${article.paragraphs.join(' ')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // const _BackToLearnLink(),
                    const SizedBox(height: 20),
                    _ArticleBody(article: article, categoryName: categoryName, categoryColor: categoryColor),
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
            children: [
              AppFooter(
                message: 'UENR Flora Environmental Learning Hub · Group 4 Final Year Project',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BACK LINK
// ─────────────────────────────────────────────────────────────
// class _BackToLearnLink extends StatelessWidget {
//   const _BackToLearnLink();

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () => context.go('/learn'),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.arrow_back, size: 16, color: kGreen),
//           SizedBox(width: 6),
//           Text('Back to Learn',
//               style: TextStyle(
//                   fontSize: 13, fontWeight: FontWeight.w600, color: kGreen)),
//         ],
//       ),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────
// ARTICLE BODY
// ─────────────────────────────────────────────────────────────
class _ArticleBody extends StatelessWidget {
  final LearnArticleDb article;
  final String categoryName;
  final Color categoryColor;
  const _ArticleBody({required this.article, required this.categoryName, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final paragraphs = article.paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero — network image or green gradient fallback
        ClipRRect(
          borderRadius: kBR2xl,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (article.heroImageUrl != null)
                  CachedNetworkImage(
                    imageUrl: article.heroImageUrl!,
                    fit: BoxFit.cover,
                    // 16:9 hero, full content-column width.
                    memCacheWidth: 900,
                    memCacheHeight: 500,
                    placeholder: (_, __) => Container(color: categoryColor),
                    errorWidget: (_, __, ___) => Container(color: categoryColor),
                  )
                else
                  Container(color: categoryColor),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 20, right: 20, bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kLight, borderRadius: kBRPill),
                        child: Text(categoryName,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kDeep)),
                      ),
                      const SizedBox(height: 10),
                      Text(article.title,
                          style: const TextStyle(
                              fontFamily: kFontDisplay,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.25)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: kMu),
            const SizedBox(width: 6),
            Text('${article.readTimeMin} min read',
                style: TextStyle(fontSize: 13, color: kMu)),
          ],
        ),
        const SizedBox(height: 20),

        // Body paragraphs
        ...paragraphs.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            e.value,
            style: TextStyle(
              fontSize: 15,
              color: e.key == 0 ? kTx : kMu,
              height: 1.6,
            ),
          ),
        )),

        const SizedBox(height: 36),
      ],
    );
  }
}

Color _colorFromHex(String? hex) {
  if (hex == null || hex.length < 7) return kDeep;
  return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
}


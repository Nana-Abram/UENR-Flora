// lib/features/learn/learn_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/section_label.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _LearnHero(),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Column(
                children: [
                  _CategoryGrid(),
                  _WeeklyFact(),
                  _ArticleList(),
                ],
              ),
            ),
          ),
          const _LearnFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────
class _LearnHero extends StatelessWidget {
  const _LearnHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kDeep,
      padding: const EdgeInsets.fromLTRB(kSp24, kSp44, kSp24, kSp44),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Environmental learning hub',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: kMint, letterSpacing: 0.5)),
            SizedBox(height: 10),
            Text('Understand the ecology around you',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w500,
                    color: Colors.white, height: 1.3)),
            SizedBox(height: 9),
            Text(
              'Articles, facts, and resources on biodiversity, climate change, '
              'and sustainability — tailored for the UENR community.',
              style: TextStyle(fontSize: 13, color: kMint, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CATEGORY GRID
// ─────────────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _categories = [
    _Cat(icon: Icons.eco_outlined,        iconColor: kDeep,             title: 'Biodiversity',   count: '8 articles'),
    _Cat(icon: Icons.public_outlined,     iconColor: Color(0xFF185FA5), title: 'Climate change', count: '6 articles'),
    _Cat(icon: Icons.recycling,           iconColor: kGreen,            title: 'Sustainability', count: '5 articles'),
    _Cat(icon: Icons.park_outlined,       iconColor: kAmber,            title: 'Forest trees',   count: '7 articles'),
    _Cat(icon: Icons.air_outlined,        iconColor: Color(0xFF993556), title: 'Wildlife',       count: '4 articles'),
    _Cat(icon: Icons.water_drop_outlined, iconColor: Color(0xFF534AB7), title: 'Water systems',  count: '4 articles'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, kSp36, kSp24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Topics'),
          const SizedBox(height: 6),
          const Text('Browse by category',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisExtent: 110,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, i) => _CategoryCard(cat: _categories[i]),
          ),
        ],
      ),
    );
  }
}

class _Cat {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String count;
  const _Cat({
    required this.icon, required this.iconColor,
    required this.title, required this.count,
  });
}

class _CategoryCard extends StatelessWidget {
  final _Cat cat;
  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border.all(color: kBorder, width: 0.5),
        borderRadius: kBRLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(cat.icon, size: 22, color: cat.iconColor),
          const SizedBox(height: 8),
          Text(cat.title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 3),
          Text(cat.count,
              style: const TextStyle(fontSize: 11, color: kMu)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WEEKLY FACT BANNER
// ─────────────────────────────────────────────────────────────
class _WeeklyFact extends StatelessWidget {
  const _WeeklyFact();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, kSp32, kSp24, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        decoration: BoxDecoration(
          color: kDeep, borderRadius: kBRXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Color(0xFFFAC775)),
                SizedBox(width: 8),
                Text('WEEKLY FACT',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: Color(0xFFFAC775), letterSpacing: 0.4)),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'UENR\'s campus hosts 485 individual plants across 58 species and '
              '25 families — the carbon-sink equivalent of removing five cars '
              'from the road each year.',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500,
                  color: Colors.white, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ARTICLE LIST
// ─────────────────────────────────────────────────────────────
class _ArticleList extends StatelessWidget {
  const _ArticleList();

  static const _articles = [
    _Article(
      thumbColor: kLight, thumbIconColor: kDeep,
      icon: Icons.eco_outlined,
      title: 'Why UENR\'s bat sanctuary matters for Ghanaian ecology',
      tag: 'Biodiversity · 4 min read',
    ),
    _Article(
      thumbColor: Color(0xFFE6F1FB), thumbIconColor: Color(0xFF185FA5),
      icon: Icons.public_outlined,
      title: 'How campus trees contribute to Ghana\'s climate goals',
      tag: 'Climate change · 3 min read',
    ),
    _Article(
      thumbColor: Color(0xFFFAEEDA), thumbIconColor: kAmber,
      icon: Icons.park_outlined,
      title: 'Traditional tree knowledge in Twi culture and its modern relevance',
      tag: 'Culture & ecology · 5 min read',
    ),
    _Article(
      thumbColor: kLight, thumbIconColor: kGreen,
      icon: Icons.recycling,
      title: 'Sustainable campus practices and green infrastructure',
      tag: 'Sustainability · 6 min read',
    ),
    _Article(
      thumbColor: Color(0xFFFBEAF0), thumbIconColor: Color(0xFF993556),
      icon: Icons.air_outlined,
      title: 'Bird species documented in the UENR campus bat sanctuary',
      tag: 'Wildlife · 4 min read',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, kSp32, kSp24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Editorial'),
          const SizedBox(height: 6),
          const Text('Recent articles',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 16),
          ..._articles.map((a) => _ArticleRow(article: a)),
        ],
      ),
    );
  }
}

class _Article {
  final Color thumbColor;
  final Color thumbIconColor;
  final IconData icon;
  final String title;
  final String tag;
  const _Article({
    required this.thumbColor, required this.thumbIconColor,
    required this.icon, required this.title, required this.tag,
  });
}

class _ArticleRow extends StatelessWidget {
  final _Article article;
  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: article.thumbColor, borderRadius: kBRMd),
            child: Icon(article.icon, size: 20, color: article.thumbIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500, color: kTx),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(article.tag,
                    style: const TextStyle(fontSize: 11, color: kMu)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 17, color: kMu),
        ],
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
    return Container(
      color: kDark,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 20),
      margin: const EdgeInsets.only(top: kSp36),
      child: const Text(
        'UENR Flora Environmental Learning Hub · Group 4 Final Year Project',
        style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

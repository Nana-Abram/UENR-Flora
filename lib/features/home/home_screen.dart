// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/section_label.dart';
import '../../widgets/plant_card.dart';
import '../../widgets/fact_card.dart';
import '../../widgets/daily_quiz.dart'; // created in step 08

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _HeroSection(),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Column(
                children: [
                  _PlatformOverviewSection(),
                  _StatisticsSection(),
                ],
              ),
            ),
          ),
          const DailyQuiz(),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Column(
                children: [
                  _RecentIdentificationsSection(),
                  _DailyFactSection(),
                ],
              ),
            ),
          ),
          const _PageFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: _HeroBackgroundCarousel(),
        ),
        Container(
          color: kDeep.withValues(alpha: 0.78),
          padding: const EdgeInsets.fromLTRB(kSp24, kSp44, kSp24, 48),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= kBreakpointMd;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _HeroText()),
                        const SizedBox(width: 24),
                        const _HeroCircle(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroText(),
                        const SizedBox(height: 28),
                        const Center(child: _HeroCircle()),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }
}

// Auto-advancing crossfade carousel used as the hero's full-bleed
// background. Sits behind the kDeep tint overlay.
class _HeroBackgroundCarousel extends StatefulWidget {
  const _HeroBackgroundCarousel();

  static const _images = [
    'assets/images/hero_carousel/hero_01.jpg',
    'assets/images/hero_carousel/hero_02.jpg',
    'assets/images/hero_carousel/hero_03.jpg',
    'assets/images/hero_carousel/hero_04.jpg',
    'assets/images/hero_carousel/hero_05.jpg',
    'assets/images/hero_carousel/hero_06.jpg',
    'assets/images/hero_carousel/hero_07.jpg',
    'assets/images/hero_carousel/hero_08.webp',
    'assets/images/hero_carousel/hero_09.jpg',
    'assets/images/hero_carousel/hero_10.jpg',
    'assets/images/hero_carousel/hero_11.jpg',
    'assets/images/hero_carousel/hero_12.jpg',
    'assets/images/hero_carousel/hero_13.jpg',
    'assets/images/hero_carousel/hero_14.jpg',
    'assets/images/hero_carousel/hero_15.jpg',
    'assets/images/hero_carousel/hero_16.jpg',
  ];

  @override
  State<_HeroBackgroundCarousel> createState() => _HeroBackgroundCarouselState();
}

class _HeroBackgroundCarouselState extends State<_HeroBackgroundCarousel> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _index = (_index + 1) % _HeroBackgroundCarousel._images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: Image.asset(
        _HeroBackgroundCarousel._images[_index],
        key: ValueKey(_index),
        fit: BoxFit.cover,
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: kBRPill,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: kMint),
              SizedBox(width: 6),
              Text('UENR Campus · Sunyani, Ghana',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMint)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Headline
        const Text(
          'Identify every plant on campus — instantly',
          style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w500,
            color: Colors.white, height: 1.25,
          ),
        ),
        const SizedBox(height: 11),
        // Subtext
        const Text(
          'AI-powered species identification, health assessment, and '
          'ecological education for the UENR community.',
          style: TextStyle(fontSize: 13, color: kMint, height: 1.7),
        ),
        const SizedBox(height: 22),
        // Buttons
        Wrap(
          spacing: 10, runSpacing: 8,
          children: [
            Builder(builder: (ctx) => ElevatedButton.icon(
              onPressed: () => ctx.go('/scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAmber, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
                elevation: 0,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: const Text('Scan a plant',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            )),
            Builder(builder: (ctx) => OutlinedButton.icon(
              onPressed: () => ctx.go('/explorer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: kBRSm),
              ),
              icon: const Icon(Icons.eco_outlined, size: 15),
              label: const Text('Browse species',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            )),
          ],
        ),
        const SizedBox(height: 28),
        // Stats strip
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HeroStat(value: '30',  label: 'species'),
            _StatDivider(),
            const _HeroStat(value: '215', label: 'scans'),
            _StatDivider(),
            const _HeroStat(value: '25',  label: 'families'),
          ],
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: kMint)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170, height: 170,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Container(
            width: 132, height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
            child: Center(
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                child: const Icon(Icons.eco, size: 42, color: kMint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PLATFORM OVERVIEW
// ─────────────────────────────────────────────────────────────
class _PlatformOverviewSection extends StatelessWidget {
  const _PlatformOverviewSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, kSp36, kSp24, kSp36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Platform overview'),
          const SizedBox(height: 6),
          const Text('Everything you need to explore campus flora',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= kBreakpointMd;
              final cards = [
                _FeatureCard(
                  accentColor: kDeep,
                  iconBg: kLight, iconColor: kDeep,
                  icon: Icons.psychology_outlined,
                  title: 'AI plant scanner',
                  description: 'Photograph a leaf and get instant species identification, '
                      'confidence score, and health assessment — processed in your browser.',
                  linkText: 'Try the scanner',
                  onTap: () => context.go('/scan'),
                ),
                _FeatureCard(
                  accentColor: kGreen,
                  iconBg: kLight, iconColor: kGreen,
                  icon: Icons.menu_book_outlined,
                  title: 'Plant encyclopedia',
                  description: 'Browse all 30 documented campus species — scientific names, '
                      'Twi names, ecological roles, care tips, and environmental benefits.',
                  linkText: 'Browse species',
                  onTap: () => context.go('/explorer'),
                ),
              ];
              return isWide
                  ? Row(children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                    ])
                  : Column(children: [
                      cards[0],
                      const SizedBox(height: 16),
                      cards[1],
                    ]);
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final Color accentColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String description;
  final String linkText;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.accentColor, required this.iconBg, required this.iconColor,
    required this.icon, required this.title, required this.description,
    required this.linkText, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A Border with non-uniform colors cannot be combined with a borderRadius
    // (Flutter throws at paint time), so the accent-coloured left edge is
    // drawn as a separate strip inside a ClipRRect instead of via Border.left.
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(14), bottomRight: Radius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: iconBg, borderRadius: kBRSm),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: kTx)),
                  const SizedBox(height: 5),
                  Text(description,
                      style: const TextStyle(fontSize: 12, color: kMu, height: 1.6)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(linkText,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500,
                                color: accentColor)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 13, color: accentColor),
                      ],
                    ),
                  ),
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
// STATISTICS
// ─────────────────────────────────────────────────────────────
class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  static const _stats = [
    {'icon': Icons.eco_outlined,        'color': kDeep,             'value': '30',  'label': 'Plant species'},
    {'icon': Icons.camera_alt_outlined, 'color': kAmber,            'value': '215', 'label': 'Total scans'},
    {'icon': Icons.favorite_outline,    'color': Color(0xFF9B1C1C), 'value': '84%', 'label': 'Healthy plants'},
    {'icon': Icons.park_outlined,       'color': kGreen,            'value': '485', 'label': 'Individuals surveyed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 0, kSp24, kSp36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Campus biodiversity'),
          const SizedBox(height: 6),
          const Text('Live campus statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= kBreakpointSm ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _stats.length,
                itemBuilder: (_, i) {
                  final s = _stats[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: kBRLg,
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s['icon'] as IconData,
                            size: 18, color: s['color'] as Color),
                        const SizedBox(height: 6),
                        Text(s['value'] as String,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w500, color: kTx)),
                        const SizedBox(height: 3),
                        Text(s['label'] as String,
                            style: const TextStyle(fontSize: 11, color: kMu),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RECENT IDENTIFICATIONS
// ─────────────────────────────────────────────────────────────
class _RecentIdentificationsSection extends StatelessWidget {
  const _RecentIdentificationsSection();

  static final _plants = kSamplePlants.take(3).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 0, kSp24, kSp36),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10), //come here to fix alignment with other sections that have a top label
                  SectionLabel('Recent activity'),
                  SizedBox(height: 4),
                  Text('Latest identifications',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
                ],
              ),
              Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => ctx.go('/explorer'),
                  child: const Text('View all',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: kAmber)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= kBreakpointMd ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemCount: _plants.length,
                itemBuilder: (_, i) => PlantCard.fromMap(_plants[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DAILY FACT
// ─────────────────────────────────────────────────────────────
class _DailyFactSection extends StatelessWidget {
  const _DailyFactSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(kSp24, 0, kSp24, kSp36),
      child: FactCard(
        'UENR\'s bat sanctuary hosts 485 individual plants across 58 species and '
        '25 families — the carbon-sink equivalent of removing 5 cars from the road each year.',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE FOOTER
// ─────────────────────────────────────────────────────────────
class _PageFooter extends StatelessWidget {
  const _PageFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kDark,
      padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 20),
      child: const Column(
        children: [
          Text(
            'UENR Flora · Group 4 Final Year Project · BSc Computer Science',
            style: TextStyle(fontSize: 12, color: Color(0x80FFFFFF)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'University of Energy and Natural Resources, Sunyani · '
            'Supervised by Mr. Bernard Andoh',
            style: TextStyle(fontSize: 11, color: Color(0x4DFFFFFF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

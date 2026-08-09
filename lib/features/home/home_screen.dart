// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/navigation.dart';
import '../../core/species_provider.dart';
import '../../core/dashboard_provider.dart';
import '../../core/category_style.dart';
import '../../core/string_utils.dart';
import '../../models/plant_species.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/plant_detail_modal.dart';
import '../../widgets/fact_card.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/hover_zoom_image.dart';
import '../../widgets/scan_activity_bar_chart.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kDeep,
      onRefresh: () => Future.wait([
        context.read<DashboardProvider>().reload(),
        context.read<SpeciesProvider>().reload(),
      ]),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: kSp16),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSp24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Breadcrumb(current: 'Dashboard'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSp24),
                      child: _HeroSection(),
                    ),
                  ),
                ),
                const SizedBox(height: kSp24),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSp24),
                      child: _StatsRow(),
                    ),
                  ),
                ),
                const SizedBox(height: kSp24),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSp24),
                      child: _FeaturedAndSidebar(),
                    ),
                  ),
                ),
                const SizedBox(height: kSp24),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSp24),
                      child: _ScanActivitySection(),
                    ),
                  ),
                ),
                const SizedBox(height: kSp32),
              ],
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_PageFooter()],
            ),
          ),
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

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final isWide = outerConstraints.maxWidth >= kBreakpointLg;
        final isNarrow = outerConstraints.maxWidth < kBreakpointSm;
        return ClipRRect(
          borderRadius: kBR2xl,
          child: SizedBox(
            // Mobile still gets slightly more room than the wide layout for
            // wrapped greeting/subtitle text, but 460 (taller than even the
            // desktop hero, despite smaller title text and no search field
            // row) was excessive — the hero alone nearly filled the phone
            // viewport before any real content appeared below it.
            height: isWide ? 350 : (isNarrow ? 380 : 400),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _HeroBackgroundCarousel(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kDeep.withValues(alpha: 0.55),
                      const Color(0xFF0D2318).withValues(alpha: 0.88),
                    ],
                  ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isNarrow ? kSp16 : kSp24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isWide
                                  ? '${_greeting()}, University of Energy and Natural Resources'
                                  : _greeting(),
                              style: const TextStyle(fontSize: 13, color: Colors.white70),
                            ),
                          ),
                          if (isWide)
                            SizedBox(
                              width: 260,
                              child: _HeroSearchField(
                                onSubmit: (q) => context.go(explorerSearchPath(q)),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Welcome to\nUENR Flora',
                        style: TextStyle(
                          fontFamily: kFontDisplay,
                          fontSize: isWide ? 50 : (isNarrow ? 30 : 34),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.12,
                          wordSpacing: 2
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: const Text(
                          'Discover, identify, and learn about the plants around you. \n'
                          "Ghana's first campus biodiversity platform.",
                          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 12, runSpacing: 10,
                        children: [
                          Builder(builder: (ctx) => ElevatedButton.icon(
                            onPressed: () => ctx.go('/scan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: kBRPill),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Scan a Plant',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          )),
                          Builder(builder: (ctx) => OutlinedButton.icon(
                            onPressed: () => ctx.go('/explorer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: kBRPill),
                            ),
                            icon: const Icon(Icons.explore_outlined, size: 16),
                            label: const Text('Explore Species',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroSearchField extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  const _HeroSearchField({required this.onSubmit});

  @override
  State<_HeroSearchField> createState() => _HeroSearchFieldState();
}

class _HeroSearchFieldState extends State<_HeroSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    widget.onSubmit(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onSubmitted: _submit,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plants...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.search, size: 17, color: Colors.white.withValues(alpha: 0.7)),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: kBRPill, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: kBRPill, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: kBRPill, borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4))),
      ),
    );
  }
}

// Auto-advancing crossfade carousel used as the hero's full-bleed background.
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

// ─────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final speciesState = context.watch<SpeciesProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final familyCount = speciesState.all
        .map((s) => s.familyName)
        .whereType<String>()
        .toSet()
        .length;

    final cards = [
      StatCardData(
        icon: Icons.eco_outlined, iconColor: kDeep, iconBg: kLight,
        topLabel: 'Species Documented',
        value: speciesState.totalCount > 0 ? '${speciesState.totalCount}' : '—',
        bottomLabel: familyCount > 0 ? '$familyCount families' : 'Campus survey',
      ),
      StatCardData(
        icon: Icons.camera_alt_outlined, iconColor: kAccent, iconBg: kAccentL,
        topLabel: 'Total Scans',
        value: '${dashboard.totalScans}',
        bottomLabel: dashboard.scansThisWeek > 0 ? '+${dashboard.scansThisWeek} this week' : 'No scans this week',
      ),
      StatCardData(
        icon: Icons.favorite_outline, iconColor: kHealthyTx, iconBg: kHealthyBg,
        topLabel: 'Healthy Plants',
        value: dashboard.healthyPercent != null ? '${dashboard.healthyPercent!.round()}%' : '—',
        bottomLabel: dashboard.healthyPercent != null ? 'Based on scan history' : 'No data yet',
      ),
      StatCardData(
        icon: Icons.today_outlined, iconColor: kGreen, iconBg: const Color(0xFFE0F0EA),
        topLabel: 'Scans Today',
        value: '${dashboard.scansToday}',
        bottomLabel: 'Updated live',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= kBreakpointMd ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            // A fixed height (rather than a width-derived aspect ratio)
            // keeps the label/icon row + value + sub text from overflowing
            // at in-between (tablet) widths, regardless of column count.
            mainAxisExtent: 124,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => StatCard(data: cards[i]),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────
// FEATURED SPECIES + SIDEBAR
// ─────────────────────────────────────────────────────────────
class _FeaturedAndSidebar extends StatelessWidget {
  const _FeaturedAndSidebar();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kBreakpointMd;
        if (isWide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _FeaturedSpeciesSection()),
              SizedBox(width: 20),
              Expanded(flex: 1, child: _Sidebar()),
            ],
          );
        }
        return const Column(
          children: [
            _FeaturedSpeciesSection(),
            SizedBox(height: 20),
            _Sidebar(),
          ],
        );
      },
    );
  }
}

class _FeaturedSpeciesSection extends StatelessWidget {
  const _FeaturedSpeciesSection();

  @override
  Widget build(BuildContext context) {
    final speciesState = context.watch<SpeciesProvider>();
    final featured = speciesState.all.where((s) => s.referenceImageUrl != null).take(4).toList();
    if (featured.isEmpty) featured.addAll(speciesState.all.take(4));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Featured Species',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kTx)),
            Builder(builder: (ctx) => TextButton(
              onPressed: () => ctx.go('/explorer'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kGreen)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 15, color: kGreen),
                ],
              ),
            )),
          ],
        ),
        const SizedBox(height: 14),
        if (speciesState.loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator(color: kDeep)),
          )
        else if (speciesState.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(speciesState.error!, style: TextStyle(fontSize: 13, color: kMu)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<SpeciesProvider>().reload(),
                  child: Text('Retry', style: TextStyle(fontSize: 13, color: kGreen)),
                ),
              ],
            ),
          )
        else if (featured.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('No species documented yet.', style: TextStyle(fontSize: 13, color: kMu)),
          )
        else
          LayoutBuilder(builder: (ctx, constraints) {
            // This section sits inside a 2:1 Row split with a sidebar on
            // wide screens (see the parent widget above), so its actual
            // available width is well under the full page width —
            // measuring via LayoutBuilder's constraints (this section's own
            // width) instead of MediaQuery (the whole viewport's width)
            // means the ratio reflects how much room these cards actually
            // have, not how wide the browser window is.
            final ratio = constraints.maxWidth < kBreakpointMd + 2 * kSp24
                ? 0.8
                : 1.2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: ratio,
              ),
              itemCount: featured.length,
              itemBuilder: (_, i) => _FeaturedCard(species: featured[i]),
            );
          }),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final PlantSpecies species;
  const _FeaturedCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final category = species.growthType;

    return HoverLift(
      borderRadius: kBRXl,
      onTap: () => showPlantDetailModal(
        context,
        species: species,
        type: category ?? '',
        healthy: true,
        cardColor: cardColor,
        iconColor: iconColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kBRXl,
          border: Border.all(color: const Color.fromARGB(37, 17, 23, 20), width: 0.9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HoverZoomImage(
                child: species.referenceImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: species.referenceImageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        // Featured card in a 2-column grid — comfortably
                        // under 500px wide even on large screens.
                        memCacheWidth: 500,
                        memCacheHeight: 500,
                        placeholder: (_, __) => Container(
                          color: cardColor,
                          child: Center(child: Icon(Icons.eco_outlined, size: 36, color: iconColor)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: cardColor,
                          child: Center(child: Icon(Icons.eco_outlined, size: 36, color: iconColor)),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        color: cardColor,
                        child: Center(child: Icon(Icons.eco_outlined, size: 36, color: iconColor)),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(species.commonName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (category != null && category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Builder(builder: (_) {
                          final style = categoryStyle(category);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
                            child: Text(
                              capitalize(category),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: style.text),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  Text(species.scientificName,
                      style: TextStyle(fontSize: 12, color: kMu, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
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
// SIDEBAR — distribution donut, quick actions, did you know
// ─────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SpeciesDistributionCard(),
        SizedBox(height: 20),
        _QuickActionsCard(),
        SizedBox(height: 20),
        _DidYouKnowCard(),
      ],
    );
  }
}

class _SpeciesDistributionCard extends StatelessWidget {
  const _SpeciesDistributionCard();

  static const _categories = [
    {'key': 'trees', 'label': 'Trees'},
    {'key': 'shrubs', 'label': 'Shrubs'},
    {'key': 'herbs', 'label': 'Herbs'},
    {'key': 'ornamental', 'label': 'Ornamental'},
  ];

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SpeciesProvider>().all;
    final counts = <String, int>{
      'trees': all.where((s) => s.growthType == 'trees').length,
      'shrubs': all.where((s) => s.growthType == 'shrubs').length,
      'herbs': all.where((s) => s.growthType == 'herbs').length,
      'ornamental': all.where((s) => s.growthType == 'ornamental').length,
    };
    final total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Species Distribution',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 18),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No species data yet.', style: TextStyle(fontSize: 12, color: kMu)),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                height: 150, width: 150,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: _categories.map((c) {
                      final count = counts[c['key']] ?? 0;
                      return PieChartSectionData(
                        value: count.toDouble(),
                        color: categoryStyle(c['key']).text,
                        radius: 26,
                        showTitle: false,
                      );
                    }).where((s) => s.value > 0).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16, runSpacing: 8,
              children: _categories.map((c) {
                final count = counts[c['key']] ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: categoryStyle(c['key'] as String).text, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${c['label']}: ', style: TextStyle(fontSize: 12, color: kMu)),
                    Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTx)),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 14),
          _QuickActionRow(
            icon: Icons.camera_alt_outlined, iconColor: kDeep, iconBg: kLight,
            title: 'Identify a Plant', subtitle: 'Use AI scanner',
            onTap: () => context.go('/scan'),
          ),
          const SizedBox(height: 14),
          _QuickActionRow(
            icon: Icons.menu_book_outlined, iconColor: kAccent, iconBg: kAccentL,
            title: 'Learn Biodiversity', subtitle: 'Explore campus flora topics',
            onTap: () => context.go('/learn'),
          ),
          const SizedBox(height: 14),
          _QuickActionRow(
            icon: Icons.favorite_border, iconColor: kUnhealthyTx, iconBg: kUnhealthyBg,
            title: 'My Saved Plants', subtitle: 'View your favorites',
            onTap: () => context.go('/profile?tab=saved'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionRow({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: kMu)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DidYouKnowCard extends StatelessWidget {
  const _DidYouKnowCard();

  static const _fallback =
      'UENR\'s campus hosts dozens of documented plant species, each one '
      'playing a role in local biodiversity.';

  @override
  Widget build(BuildContext context) {
    final fact = context.watch<SpeciesProvider>().dailyFact;
    return FactCard(fact ?? _fallback);
  }
}

// ─────────────────────────────────────────────────────────────
// SCAN ACTIVITY
// ─────────────────────────────────────────────────────────────
const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

enum _ScanView { day, week, month }

class _ScanActivitySection extends StatefulWidget {
  const _ScanActivitySection();

  @override
  State<_ScanActivitySection> createState() => _ScanActivitySectionState();
}

class _ScanActivitySectionState extends State<_ScanActivitySection> {
  var _view = _ScanView.day;

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final year = DateTime.now().year;

    final List<int> counts;
    final String subtitle;
    final double? delta;
    final String deltaSuffix;
    final Widget Function(int index) buildLabel;

    switch (_view) {
      case _ScanView.day:
        counts = dashboard.dailyCounts;
        subtitle = 'Daily plant identifications, last ${DashboardProvider.dailyWindowSize} days';
        delta = dashboard.dayOverDayDelta;
        deltaSuffix = 'vs yesterday';
        buildLabel = (i) {
          final d = dashboard.dailyDates[i];
          return Text(_weekdayAbbr[d.weekday - 1], style: TextStyle(fontSize: 11, color: kMu));
        };
        break;
      case _ScanView.week:
        counts = dashboard.weeklyCounts;
        subtitle = 'Weekly plant identifications, last ${DashboardProvider.weeklyWindowSize} weeks';
        delta = dashboard.weekOverWeekDelta;
        deltaSuffix = 'vs last week';
        buildLabel = (i) {
          final d = dashboard.weeklyStarts[i];
          return Text('${d.month}/${d.day}', style: TextStyle(fontSize: 11, color: kMu));
        };
        break;
      case _ScanView.month:
        counts = dashboard.monthlyCounts;
        subtitle = 'Monthly plant identifications, $year';
        delta = dashboard.monthOverMonthDelta;
        deltaSuffix = 'vs last month';
        buildLabel = (i) => Text(_monthAbbr[i], style: TextStyle(fontSize: 11, color: kMu));
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kBR2xl,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10, runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scan Activity',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTx)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: kMu)),
                ],
              ),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: kLight, borderRadius: kBRPill),
                  child: Text(
                    '${delta >= 0 ? '+' : ''}${delta.round()}% $deltaSuffix',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kGreen),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _ScanViewToggle(
            value: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          const SizedBox(height: 14),
          if (dashboard.totalScans == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No scan activity yet. Identify a plant to see trends.',
                    style: TextStyle(fontSize: 12, color: kMu)),
              ),
            )
          else
            ScanActivityBarChart(counts: counts, buildLabel: buildLabel, height: 220),
        ],
      ),
    );
  }
}

class _ScanViewToggle extends StatelessWidget {
  final _ScanView value;
  final ValueChanged<_ScanView> onChanged;
  const _ScanViewToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget segment(_ScanView v, String label) {
      final selected = v == value;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? kGreen : Colors.transparent,
            borderRadius: kBRPill,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : kMu,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: kLight, borderRadius: kBRPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(_ScanView.day, 'Day'),
          segment(_ScanView.week, 'Week'),
          segment(_ScanView.month, 'Month'),
        ],
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
    final narrow = MediaQuery.of(context).size.width < kBreakpointMd;
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: kDeep, shape: BoxShape.circle),
          child: const Icon(Icons.eco, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: RichText(
            text: TextSpan(
              text: 'UENR Flora',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: ' · Group 4 Final Year Project · BSc Computer Science',
                  style: TextStyle(fontSize: 12, color: kMu),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final university = Text(
      'University of Energy and Natural Resources, Sunyani · '
      'Supervised by Mr. Bernard Andoh',
      style: TextStyle(fontSize: 11, color: kMu),
    );
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 20),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [logo, const SizedBox(height: 8), university],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: logo),
                  const SizedBox(width: 16),
                  Flexible(child: university),
                ],
              ),
      ),
    );
  }
}

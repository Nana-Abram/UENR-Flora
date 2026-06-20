// lib/features/explorer/explorer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/plant_detail_modal.dart';
import 'explorer_provider.dart';

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExplorerProvider(),
      child: const _ExplorerBody(),
    );
  }
}

class _ExplorerBody extends StatelessWidget {
  const _ExplorerBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dark green header
        Container(
          width: double.infinity,
          color: kDeep,
          padding: const EdgeInsets.fromLTRB(kSp24, 28, kSp24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Campus flora',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: kMint, letterSpacing: 0.5)),
              SizedBox(height: 8),
              Text('Plant explorer',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500,
                      color: Colors.white)),
              SizedBox(height: 4),
              Text('Browse all 30 documented UENR campus species',
                  style: TextStyle(fontSize: 13, color: kMint)),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                    child: Column(
                      children: [
                        // Search + sort row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(kSp24, 16, kSp24, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: kWhite,
                                    border: Border.all(color: kBorder, width: 0.5),
                                    borderRadius: kBRLg,
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.search_outlined, size: 16, color: kMu),
                                      SizedBox(width: 9),
                                      Text('Search plants, families...',
                                          style: TextStyle(fontSize: 13, color: kMu)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 9),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  border: Border.all(color: kBorder, width: 0.5),
                                  borderRadius: kBRSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.sort_outlined, size: 14, color: kMu),
                                    SizedBox(width: 5),
                                    Text('Sort',
                                        style: TextStyle(fontSize: 12, color: kMu)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Filter chips
                        const _FilterChips(),

                        // Plant grid
                        const _PlantGrid(),
                      ],
                    ),
                  ),
                ),

                // Footer — bleeds edge to edge, not width-constrained
                Container(
                  color: kDark,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSp24, vertical: 18),
                  child: const Text(
                    'Based on Owusu-Prempeh et al. (2018) UENR botanical survey',
                    style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Filter chips row ─────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  static const _filters = [
    {'label': 'All (30)',    'value': 'all'},
    {'label': 'Trees',       'value': 'trees'},
    {'label': 'Shrubs',      'value': 'shrubs'},
    {'label': 'Herbs',       'value': 'herbs'},
    {'label': 'Medicinal',   'value': 'medicinal'},
    {'label': 'Ornamental',  'value': 'ornamental'},
  ];

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ExplorerProvider>().filter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(kSp24, 12, kSp24, 14),
      child: Row(
        children: _filters.map((f) {
          final isActive = active == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  context.read<ExplorerProvider>().setFilter(f['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? kDeep : kWhite,
                  border: Border.all(
                      color: isActive ? kDeep : kBorder, width: 0.5),
                  borderRadius: kBRPill,
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : kMu,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Plant grid ───────────────────────────────────────────────
class _PlantGrid extends StatelessWidget {
  const _PlantGrid();

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<ExplorerProvider>().filtered;

    if (plants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No plants found for this filter.',
              style: TextStyle(fontSize: 13, color: kMu)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 0, kSp24, kSp36),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 200,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: plants.length,
        itemBuilder: (context, i) {
          final p = plants[i];
          return _ExplorerCard(
            commonName:     p['common'] as String,
            scientificName: p['scientific'] as String,
            familyName:     p['family'] as String,
            type:           p['type'] as String,
            healthy:        p['healthy'] as bool,
            cardColor:      Color(p['cardColor'] as int),
            iconColor:      Color(p['iconColor'] as int),
          );
        },
      ),
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  final String commonName;
  final String scientificName;
  final String familyName;
  final String type;
  final bool healthy;
  final Color cardColor;
  final Color iconColor;

  const _ExplorerCard({
    required this.commonName, required this.scientificName,
    required this.familyName, required this.type, required this.healthy,
    required this.cardColor, required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPlantDetailModal(
        context,
        commonName: commonName,
        scientificName: scientificName,
        familyName: familyName,
        type: type,
        healthy: healthy,
        cardColor: cardColor,
        iconColor: iconColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder, width: 0.5),
          borderRadius: kBRXl,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured image area
            Container(
              height: 98, color: cardColor,
              child: Center(
                child: Icon(Icons.eco_outlined, size: 40, color: iconColor),
              ),
            ),
            // Text area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commonName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500, color: kTx),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(scientificName,
                        style: const TextStyle(
                            fontSize: 10, color: kMu,
                            fontStyle: FontStyle.italic),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PillBadge(healthy: healthy),
                        Flexible(
                          child: Text(familyName,
                              style: const TextStyle(fontSize: 9, color: kMu),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

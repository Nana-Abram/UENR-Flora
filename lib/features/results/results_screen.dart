// lib/features/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/species_provider.dart';
import '../../core/favorites_provider.dart';
import '../../core/species_text.dart';
import '../../core/utils/text_formatter.dart';
import '../../models/identification_result.dart';
import '../../models/plant_species.dart';
import '../../services/web_share_service.dart';
import '../../widgets/plant_detail_modal.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/confidence_bar.dart';
import '../../widgets/fact_card.dart';
import '../../widgets/eco_card.dart';
import '../../widgets/care_row.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/hover_zoom_image.dart';
import '../../widgets/planting_guide_tab.dart';
import '../../widgets/read_aloud_button.dart';

class ResultsScreen extends StatefulWidget {
  final IdentificationResult result;
  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _tab = 0;

  /// Tab label + content paired together so inserting "Planting Guide" for
  /// ornamental species can't desync a label from the wrong case in a
  /// separate positional switch — see [_buildTabContent] in
  /// plant_detail_modal.dart's history for the bug this shape avoids.
  List<(String, WidgetBuilder)> _buildTabs(PlantSpecies species, ClassificationOutput cls) {
    final advice = species.plantingAdvice;
    final showPlantingGuide = species.growthType == 'ornamental' && advice != null && advice.isNotEmpty;
    return [
      ('Overview', (_) => _TabOverview(species: species, cls: cls)),
      ('Ecology', (_) => _TabEcology(species: species)),
      ('Benefits', (_) => _TabBenefits(species: species)),
      ('Care', (_) => _TabCare(species: species)),
      if (showPlantingGuide) ('Planting Guide', (_) => PlantingGuideTab(advice: advice)),
      ('Fun facts', (_) => _TabFacts(species: species)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.result.species;

    if (species == null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            _NoResultView(confident: widget.result.isConfident),
          ],
        ),
      );
    }

    final cls = widget.result.classification;
    final tabs = _buildTabs(species, cls);
    if (_tab >= tabs.length) _tab = 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    healthy: cls.healthStatus != HealthStatus.unhealthy,
                    trailing: ReadAloudButton(
                      textBuilder: () => identificationReadText(species, cls),
                    ),
                  ),

                  if (widget.result.isLowConfidence)
                    _LowConfidenceBanner(speciesName: species.commonName),

                  // Header: image + info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 16, kSp24, 0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= kBreakpointMd;
                        final image = _PlantImage(species: species, healthy: cls.healthStatus != HealthStatus.unhealthy);
                        final info  = _SpeciesInfo(
                          species: species,
                          cls: cls,
                          attemptCount: widget.result.attemptCount,
                          isLowConfidence: widget.result.isLowConfidence,
                        );
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 260, child: image),
                                  const SizedBox(width: 24),
                                  Expanded(child: info),
                                ],
                              )
                            : Column(children: [image, const SizedBox(height: 16), info]);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: kSp24),
                      child: Row(
                        children: List.generate(tabs.length, (i) => _TabBtn(
                          label: tabs[i].$1,
                          active: _tab == i,
                          onTap: () => setState(() => _tab = i),
                        )),
                      ),
                    ),
                  ),

                  // Tab content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 20, kSp24, 0),
                    child: tabs[_tab].$2(context),
                  ),

                  // Similar species
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 24, kSp24, kSp36),
                    child: _SimilarSpecies(current: species),
                  ),
                ],
              ),
            ),
          ),

          // Footer — bleeds edge to edge, not width-constrained
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'UENR Flora Environmental Learning Hub. Group 4 Final Year Project',
                style: TextStyle(fontSize: 11, color:kMu),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Top bar: back link + health pill, mirrors the reference design's ──
// ── header row without pinning the page to a fixed background colour. ──
class _TopBar extends StatelessWidget {
  final bool? healthy; // null in the no-result state — pill is hidden
  final Widget? trailing;
  const _TopBar({this.healthy, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 18, kSp24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/scan'),
            style: TextButton.styleFrom(
              foregroundColor: kMu, padding: EdgeInsets.zero),
            icon: const Icon(Icons.arrow_back_outlined, size: 16),
            label: Text('Back to scanner',
                style: TextStyle(fontSize: 12, color: kMu)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
              if (healthy != null) PillBadge(healthy: healthy!),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Low-confidence warning — shown when every scan attempt was used and ──
// ── confidence still never reached threshold; the best guess is shown ──
// ── anyway rather than a dead end, but flagged as unconfirmed. ─────────
class _LowConfidenceBanner extends StatelessWidget {
  final String speciesName;
  const _LowConfidenceBanner({required this.speciesName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 16, kSp24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kRetryBg,
          border: Border.all(color: kRetry.withValues(alpha: 0.3), width: 0.5),
          borderRadius: kBRLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 17, color: kRetry),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Low confidence result — this might be $speciesName. '
                'Try scanning in better lighting or closer to the leaf.',
                style: TextStyle(fontSize: 12, color: kRetry, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No result state — either low confidence after every attempt, or a ──
// ── genuine "species missing from the database" data problem. ─────────
class _NoResultView extends StatelessWidget {
  final bool confident;
  const _NoResultView({required this.confident});

  @override
  Widget build(BuildContext context) {
    final title = confident
        ? "Couldn't load this species' details"
        : 'Plant could not be identified confidently';
    final body = confident
        ? "We recognised a match, but couldn't load its record just now. "
          'This is usually temporary — please try again.'
        : "We compared your photos against every species in our database but "
          "couldn't reach ${(kConfidenceThreshold * 100).round()}% confidence. "
          'Try clearer, well-lit photos of the leaf, flower, or bark.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(kSp24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kLight, borderRadius: kBRXl,
        border: Border.all(color: kMint, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.help_outline, size: 48, color: kDeep),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(fontSize: 12, color: kMu, height: 1.55),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/scan'),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ── Tab button ──────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: active ? kDeep : Colors.transparent, width: 2)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: active ? kDeep : kMu)),
      ),
    );
  }
}

// ── Icon + label/value pair used in the header's 2x2 facts grid ───────
class _IconInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _IconInfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: kLight, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: kDeep),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: kMu)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 2-column grid, sized to content rather than a fixed aspect ratio ──
// ── (which leaves huge gaps on wide screens for single-line rows). ────
class _InfoGrid extends StatelessWidget {
  final List<List<Widget>> rows;
  final double spacing;
  const _InfoGrid({required this.rows, required this.spacing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: row[0]),
              SizedBox(width: spacing),
              Expanded(child: row[1]),
            ],
          ),
          if (row != rows.last) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

// ── White card of icon/label/value rows, divided by hairlines — used ──
// ── by the Overview tab's Height/Leaf shape/Flowering/Growth habit facts.
class _DetailRowData {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRowData(this.icon, this.label, this.value);
}

class _DetailCard extends StatelessWidget {
  final List<_DetailRowData> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kWhite,
        border: Border.all(color: kBorder, width: 0.5),
        borderRadius: kBRXl,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 15, color: kMu),
                  const SizedBox(width: 10),
                  Text(rows[i].label, style: TextStyle(fontSize: 13, color: kMu)),
                  const Spacer(),
                  Flexible(
                    child: Text(rows[i].value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

// ── Plant image with action buttons ─────────────────────────
class _PlantImage extends StatelessWidget {
  final PlantSpecies species;
  final bool healthy;
  const _PlantImage({required this.species, required this.healthy});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final imageUrl = species.referenceImageUrl;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => showPlantDetailModal(
            context,
            species: species,
            type: species.growthType ?? '',
            healthy: healthy,
            cardColor: cardColor,
            iconColor: iconColor,
          ),
          child: ClipRRect(
            borderRadius: kBRXl,
            child: SizedBox(
              height: 260, width: double.infinity,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      // Main result image is 260 tall, full content-column
                      // width — generous cap well under typical source res.
                      memCacheWidth: 800,
                      memCacheHeight: 600,
                      placeholder: (_, __) => Container(
                        color: cardColor,
                        child: Center(
                            child: Icon(Icons.eco_outlined, size: 56, color: iconColor)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: cardColor,
                        child: Center(
                            child: Icon(Icons.eco_outlined, size: 56, color: iconColor)),
                      ),
                    )
                  : Container(
                      color: cardColor,
                      child: Center(
                          child: Icon(Icons.eco_outlined, size: 56, color: iconColor)),
                    ),
            ),
          ),
        ),
        Positioned(
          bottom: 10, right: 10,
          child: Row(
            children: [
              _ShareCircleBtn(species: species),
              const SizedBox(width: 6),
              _FavoriteCircleBtn(speciesId: species.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final String label;
  const _CircleBtn({
    required this.icon,
    this.iconColor,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Same Semantics+Tooltip pattern as ReadAloudButton's circle variant —
    // an icon-only button needs a label for screen readers and mouse
    // hover alike, not just a bare tap target.
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            child: Icon(icon, size: 14, color: iconColor ?? kTx),
          ),
        ),
      ),
    );
  }
}

/// Heart toggle backed by [FavoritesProvider] — filled/pink when this
/// species is favorited, outline otherwise.
class _FavoriteCircleBtn extends StatelessWidget {
  final String speciesId;
  const _FavoriteCircleBtn({required this.speciesId});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final active = favorites.isFavorite(speciesId);
    return _CircleBtn(
      icon: active ? Icons.favorite : Icons.favorite_border,
      iconColor: kUnhealthyTx,
      onTap: () => context.read<FavoritesProvider>().toggle(speciesId),
      label: active ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}

/// Shares a species via the native share sheet (falling back to copying a
/// link to the clipboard) and surfaces the outcome with a snackbar.
class _ShareCircleBtn extends StatelessWidget {
  final PlantSpecies species;
  const _ShareCircleBtn({required this.species});

  Future<void> _share(BuildContext context) async {
    final url = '${Uri.base.origin}/#/explorer?species=${species.id}';
    final result = await WebShareService.share(
      title: species.commonName,
      text: '${species.commonName} (${species.scientificName}) — UENR Flora',
      url: url,
    );
    if (!context.mounted) return;
    final message = switch (result) {
      ShareResult.copied => 'Link copied to clipboard',
      ShareResult.failed => "Couldn't share this plant right now",
      ShareResult.shared || ShareResult.cancelled => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!WebShareService.isSupported) return const SizedBox.shrink();
    return _CircleBtn(
      icon: Icons.share_outlined,
      onTap: () => _share(context),
      label: 'Share this plant',
    );
  }
}

// ── Species info block ──────────────────────────────────────
class _SpeciesInfo extends StatelessWidget {
  final PlantSpecies species;
  final ClassificationOutput cls;
  final int attemptCount;
  final bool isLowConfidence;
  const _SpeciesInfo({
    required this.species,
    required this.cls,
    required this.attemptCount,
    required this.isLowConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(species.commonName,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w600, color: kTx)),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Text('🌿', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(species.scientificName,
            style: TextStyle(
                fontSize: 14, color: kGreen, fontStyle: FontStyle.italic)),
        const SizedBox(height: 3),
        Text('Twi: ${species.localNameTwi ?? '—'}',
            style: TextStyle(fontSize: 13, color: kMu)),
        if (attemptCount > 1) ...[
          const SizedBox(height: 10),
          _AttemptChip(attemptCount: attemptCount, isLowConfidence: isLowConfidence),
        ],
        const SizedBox(height: 18),
        ConfidenceBar(confidence: cls.confidence),
        const SizedBox(height: 20),
        // 2x2 mini info grid
        _InfoGrid(spacing: 16, rows: [
          [
            _IconInfoTile(icon: Icons.eco_outlined, label: 'Family', value: species.familyName ?? '—'),
            _IconInfoTile(icon: Icons.park_outlined, label: 'Growth', value: species.growthHabit ?? '—'),
          ],
          [
            _IconInfoTile(icon: Icons.grass_outlined, label: 'Leaf type', value: species.leafType ?? '—'),
            _IconInfoTile(icon: Icons.public_outlined, label: 'Origin', value: species.origin ?? '—'),
          ],
        ]),
      ],
    );
  }
}

// ── "Confirmed in N scans" chip — green once past threshold, terracotta ──
// ── if the best guess never reached it. Only shown when more than one ──
// ── photo was combined; a single confident scan needs no explanation. ──
class _AttemptChip extends StatelessWidget {
  final int attemptCount;
  final bool isLowConfidence;
  const _AttemptChip({required this.attemptCount, required this.isLowConfidence});

  @override
  Widget build(BuildContext context) {
    final color = isLowConfidence ? kRetry : kHealthyTx;
    final bg = isLowConfidence ? kRetryBg : kHealthyBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: kBRPill),
      child: Text(
        'Confirmed in $attemptCount scan${attemptCount == 1 ? '' : 's'}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

// ── TAB 0 — OVERVIEW ────────────────────────────────────────
class _TabOverview extends StatelessWidget {
  final PlantSpecies species;
  final ClassificationOutput cls;
  const _TabOverview({required this.species, required this.cls});

  @override
  Widget build(BuildContext context) {
    final detailCard = _DetailCard(rows: [
      _DetailRowData(Icons.straighten_outlined, 'Height', species.heightRange ?? '—'),
      _DetailRowData(Icons.eco_outlined, 'Leaf shape', species.leafType ?? '—'),
      _DetailRowData(Icons.local_florist_outlined, 'Flowering', species.floweringSeason ?? '—'),
      _DetailRowData(Icons.park_outlined, 'Growth habit', species.growthHabit ?? '—'),
    ]);
    final didYouKnow = species.didYouKnowFacts.isNotEmpty
        ? FactCard(species.didYouKnowFacts.first)
        : null;

    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kBreakpointMd;
          if (didYouKnow == null) return detailCard;
          if (!isWide) {
            return Column(children: [detailCard, const SizedBox(height: 14), didYouKnow]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: detailCard),
              const SizedBox(width: 16),
              Expanded(child: didYouKnow),
            ],
          );
        }),
        if (cls.healthStatus == HealthStatus.unhealthy) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: kUnhealthyBg,
              border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
              borderRadius: kBRMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: kUnhealthyTx),
                  const SizedBox(width: 7),
                  Text('Health notice',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: kUnhealthyTx)),
                ]),
                const SizedBox(height: 5),
                Text(
                  'Our AI flagged visual signs consistent with plant stress '
                  '(discolouration, spotting, or wilting) with '
                  '${(cls.healthConfidence * 100).round()}% confidence. For a '
                  "definitive diagnosis, consult UENR's Dept. of Biological Science.",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF791F1F), height: 1.55),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── TAB 1 — ECOLOGY ─────────────────────────────────────────
class _TabEcology extends StatelessWidget {
  final PlantSpecies species;
  const _TabEcology({required this.species});

  @override
  Widget build(BuildContext context) {
    final benefitsBullets = toBullets(species.environmentalBenefits ??
        'Absorbs CO₂ annually, contributing to campus carbon neutrality goals.');
    final importanceBullets = toBullets(species.ecologicalImportance ??
        'Provides habitat and food sources for campus wildlife.');
    return Column(children: [
      EcoCard(
        iconBg: kLight, iconColor: kDeep, icon: Icons.cloud_outlined,
        title: 'Carbon sequestration',
        bullets: benefitsBullets,
      ),
      EcoCard(
        iconBg: kLight, iconColor: kGreen, icon: Icons.air_outlined,
        title: 'Wildlife support',
        bullets: importanceBullets,
      ),
      const SizedBox(height: 8),
    ]);
  }
}

// ── TAB 2 — BENEFITS ────────────────────────────────────────
class _TabBenefits extends StatelessWidget {
  final PlantSpecies species;
  const _TabBenefits({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      EcoCard(
        title: 'Medicinal uses',
        bullets: toBullets(species.medicinalUses ?? 'No documented medicinal uses.')),
      EcoCard(
        title: 'Economic importance',
        bullets:
            toBullets(species.economicImportance ?? 'No documented economic importance.')),
      const SizedBox(height: 8),
    ]);
  }
}

// ── TAB 3 — CARE ────────────────────────────────────────────
class _TabCare extends StatelessWidget {
  final PlantSpecies species;
  const _TabCare({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CareRow(
        iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF185FA5),
        icon: Icons.water_drop_outlined, title: 'Water',
        body: species.waterRequirements ?? 'Moderate watering requirements.'),
      CareRow(
        iconBg: kAccentL, iconColor: kAccent,
        icon: Icons.wb_sunny_outlined, title: 'Sunlight',
        body: species.sunlightRequirements ?? 'Full sun preferred.'),
      CareRow(
        iconBg: kLight, iconColor: kDeep,
        icon: Icons.layers_outlined, title: 'Soil',
        body: species.soilPreference ?? 'Well-draining, loamy soil preferred.'),
      const SizedBox(height: 8),
    ]);
  }
}

// ── TAB 4 — FUN FACTS ───────────────────────────────────────
class _TabFacts extends StatelessWidget {
  final PlantSpecies species;
  const _TabFacts({required this.species});

  @override
  Widget build(BuildContext context) {
    final facts = species.didYouKnowFacts;
    if (facts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text('No facts available yet.',
            style: TextStyle(fontSize: 13, color: kMu)),
      );
    }
    return Column(
      children: [
        ...facts.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FactCard(f),
        )),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ── SIMILAR SPECIES ─────────────────────────────────────────
// Real species from the same family (falling back to the same growth type),
// pulled from the already-loaded SpeciesProvider — no extra network call.
class _SimilarSpecies extends StatelessWidget {
  final PlantSpecies current;
  const _SimilarSpecies({required this.current});

  List<PlantSpecies> _pick(List<PlantSpecies> all) {
    final sameFamily = current.familyName == null
        ? <PlantSpecies>[]
        : all.where((s) => s.id != current.id && s.familyName == current.familyName).toList();
    if (sameFamily.length >= 4) return sameFamily.take(4).toList();

    final sameGrowth = current.growthType == null
        ? <PlantSpecies>[]
        : all.where((s) =>
            s.id != current.id &&
            !sameFamily.contains(s) &&
            s.growthType == current.growthType).toList();

    return [...sameFamily, ...sameGrowth].take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<SpeciesProvider>().all;
    final similar = _pick(all);
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.eco_outlined, size: 16, color: kDeep),
            const SizedBox(width: 7),
            Text('Similar species',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 225,
            crossAxisSpacing: 14, mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: similar.length,
          itemBuilder: (_, i) =>
              _SimilarSpeciesTile(key: ValueKey(similar[i].id), species: similar[i]),
        ),
      ],
    );
  }
}

class _SimilarSpeciesTile extends StatelessWidget {
  final PlantSpecies species;
  const _SimilarSpeciesTile({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);

    return HoverLift(
      borderRadius: kBRMd,
      onTap: () => showPlantDetailModal(
        context,
        species: species,
        type: species.growthType ?? '',
        healthy: true,
        cardColor: cardColor,
        iconColor: iconColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: kBorder, width: 0.5),
          borderRadius: kBRMd,
          color: kWhite,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: HoverZoomImage(
                    child: species.referenceImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: species.referenceImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            // Similar-species tile caps at 225 logical px
                            // wide (maxCrossAxisExtent), aspect ratio ~1.
                            memCacheWidth: 450,
                            memCacheHeight: 450,
                            placeholder: (_, __) => Container(
                              color: cardColor,
                              child: Center(
                                  child: Icon(Icons.eco_outlined, size: 26, color: iconColor)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: cardColor,
                              child: Center(
                                  child: Icon(Icons.eco_outlined, size: 26, color: iconColor)),
                            ),
                          )
                        : Container(
                            color: cardColor,
                            width: double.infinity,
                            child: Center(
                                child: Icon(Icons.eco_outlined, size: 26, color: iconColor)),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(species.commonName,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500, color: kTx),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 1),
                      Text(species.familyName ?? 'Unclassified',
                          style: TextStyle(fontSize: 10, color: kMu),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8, bottom: 8,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: kLight, shape: BoxShape.circle),
                child: Icon(Icons.chevron_right, size: 14, color: kDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

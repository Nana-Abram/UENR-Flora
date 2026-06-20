// lib/features/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/identification_result.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/confidence_bar.dart';
import '../../widgets/fact_card.dart';
import '../../widgets/info_row.dart';
import '../../widgets/eco_card.dart';
import '../../widgets/care_row.dart';

class ResultsScreen extends StatefulWidget {
  final IdentificationResult result;
  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _tab = 0;
  final _tabs = ['Overview', 'Ecology', 'Benefits', 'Care', 'Fun facts'];

  @override
  Widget build(BuildContext context) {
    if (widget.result.species == null && !widget.result.isConfident) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _BackButton(),
            _LowConfidenceView(),
          ],
        ),
      );
    }

    final species = widget.result.species ?? PlantSpeciesSimple.mangoSample;
    final cls     = widget.result.classification;

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
                  const _BackButton(),

                  // Header: image + info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 18, kSp24, 0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= kBreakpointMd;
                        final image = _PlantImage(species: species);
                        final info  = _SpeciesInfo(species: species, cls: cls);
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 210, child: image),
                                  const SizedBox(width: 20),
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
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: kSp24),
                      child: Row(
                        children: List.generate(_tabs.length, (i) => _TabBtn(
                          label: _tabs[i],
                          active: _tab == i,
                          onTap: () => setState(() => _tab = i),
                        )),
                      ),
                    ),
                  ),

                  // Tab content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 20, kSp24, 0),
                    child: _buildTabContent(species, cls),
                  ),

                  // Similar species
                  Padding(
                    padding: const EdgeInsets.fromLTRB(kSp24, 24, kSp24, kSp36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        const Text('Similar species',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500, color: kTx)),
                        const SizedBox(height: 12),
                        const _SimilarSpecies(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer — bleeds edge to edge, not width-constrained
          Container(
            width: double.infinity,
            color: kDark,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'Identification data sourced from Owusu-Prempeh et al. (2018) UENR botanical survey',
                style: TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(PlantSpeciesSimple species, ClassificationOutput cls) {
    switch (_tab) {
      case 0: return _TabOverview(species: species, cls: cls);
      case 1: return _TabEcology(species: species);
      case 2: return _TabBenefits(species: species);
      case 3: return _TabCare(species: species);
      case 4: return _TabFacts(species: species);
      default: return const SizedBox.shrink();
    }
  }
}

// ── Back button ──────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSp24, 18, kSp24, 0),
      child: TextButton.icon(
        onPressed: () => context.go('/scan'),
        style: TextButton.styleFrom(
          foregroundColor: kMu, padding: EdgeInsets.zero),
        icon: const Icon(Icons.arrow_back_outlined, size: 16),
        label: const Text('Back to scanner',
            style: TextStyle(fontSize: 12, color: kMu)),
      ),
    );
  }
}

// ── Low confidence state ────────────────────────────────────
class _LowConfidenceView extends StatelessWidget {
  const _LowConfidenceView();

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.help_outline, size: 48, color: kDeep),
          const SizedBox(height: 12),
          const Text('Plant could not be identified confidently',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTx),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'The model\'s confidence was below 70%. Try a clearer photo '
            'with better lighting and a plain background.',
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

// ── Plant image with action buttons ─────────────────────────
class _PlantImage extends StatelessWidget {
  final PlantSpeciesSimple species;
  const _PlantImage({required this.species});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFAC775), borderRadius: kBRXl),
          child: const Icon(Icons.yard_outlined, size: 68, color: Color(0xFF633806)),
        ),
        Positioned(
          bottom: 10, right: 10,
          child: Row(
            children: [
              _CircleBtn(icon: Icons.share_outlined, onTap: () {}),
              const SizedBox(width: 6),
              _CircleBtn(
                  icon: Icons.favorite_border,
                  iconColor: const Color(0xFF9B1C1C),
                  onTap: () {}),
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
  const _CircleBtn({required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.92),
        ),
        child: Icon(icon, size: 14, color: iconColor ?? kTx),
      ),
    );
  }
}

// ── Species info block ──────────────────────────────────────
class _SpeciesInfo extends StatelessWidget {
  final PlantSpeciesSimple species;
  final ClassificationOutput cls;
  const _SpeciesInfo({required this.species, required this.cls});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species.commonName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w500, color: kTx)),
                  const SizedBox(height: 3),
                  Text(species.scientificName,
                      style: const TextStyle(
                          fontSize: 13, color: kMu,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 2),
                  Text('Twi: ${species.localNameTwi ?? '—'}',
                      style: const TextStyle(fontSize: 12, color: kMu)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PillBadge(
                healthy: cls.healthStatus == HealthStatus.healthy),
          ],
        ),
        const SizedBox(height: 13),
        ConfidenceBar(confidence: cls.confidence),
        const SizedBox(height: 14),
        // 2x2 mini info grid
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 7, mainAxisSpacing: 7,
          childAspectRatio: 3.0,
          children: [
            InfoRow('Family',    species.familyName ?? '—'),
            InfoRow('Growth',    species.growthHabit ?? '—'),
            InfoRow('Leaf type', species.leafType ?? '—'),
            InfoRow('Origin',    species.origin ?? '—'),
          ],
        ),
      ],
    );
  }
}

// ── TAB 0 — OVERVIEW ────────────────────────────────────────
class _TabOverview extends StatelessWidget {
  final PlantSpeciesSimple species;
  final ClassificationOutput cls;
  const _TabOverview({required this.species, required this.cls});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
          childAspectRatio: 3.0,
          children: [
            InfoRow('Leaf shape',  species.leafType ?? '—'),
            InfoRow('Flowering',   species.floweringSeason ?? '—'),
            InfoRow('Fruit type',  'Drupe'),
            InfoRow('Lifespan',    '200–300 years'),
          ],
        ),
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
              children: const [
                Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 15, color: Color(0xFF9B1C1C)),
                  SizedBox(width: 7),
                  Text('Health notice',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: Color(0xFF9B1C1C))),
                ]),
                SizedBox(height: 5),
                Text(
                  'Leaf shows discolouration consistent with water stress or early '
                  'anthracnose infection. Consult UENR\'s Dept of Biological Science.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF791F1F), height: 1.55),
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
  final PlantSpeciesSimple species;
  const _TabEcology({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      EcoCard(
        iconBg: kLight, iconColor: kDeep, icon: Icons.cloud_outlined,
        title: 'Carbon sequestration',
        body: species.environmentalBenefits ??
            'Absorbs CO₂ annually, contributing to campus carbon neutrality goals.',
      ),
      EcoCard(
        iconBg: kLight, iconColor: kGreen, icon: Icons.air_outlined,
        title: 'Wildlife support',
        body: species.ecologicalImportance ??
            'Provides habitat and food sources for campus wildlife.',
      ),
      EcoCard(
        iconBg: kAmberL, iconColor: kAmber, icon: Icons.terrain_outlined,
        title: 'Erosion control',
        body: 'Extensive root system stabilises soil along campus slopes '
            'and near the bat sanctuary.',
      ),
      const SizedBox(height: 8),
    ]);
  }
}

// ── TAB 2 — BENEFITS ────────────────────────────────────────
class _TabBenefits extends StatelessWidget {
  final PlantSpeciesSimple species;
  const _TabBenefits({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      EcoCard(
        title: 'Medicinal uses',
        body: species.medicinalUses ?? 'Traditional medicinal uses documented.'),
      EcoCard(
        title: 'Economic importance',
        body: species.economicImportance ?? 'Significant economic value.'),
      EcoCard(
        title: 'Shade and microclimate',
        body: 'Dense canopy reduces surface temperature by up to 4°C '
            'along campus walkways.'),
      const SizedBox(height: 8),
    ]);
  }
}

// ── TAB 3 — CARE ────────────────────────────────────────────
class _TabCare extends StatelessWidget {
  final PlantSpeciesSimple species;
  const _TabCare({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CareRow(
        iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF185FA5),
        icon: Icons.water_drop_outlined, title: 'Water',
        body: species.waterRequirements ?? 'Moderate watering requirements.'),
      CareRow(
        iconBg: kAmberL, iconColor: kAmber,
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
  final PlantSpeciesSimple species;
  const _TabFacts({required this.species});

  @override
  Widget build(BuildContext context) {
    final facts = species.didYouKnowFacts;
    if (facts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
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
class _SimilarSpecies extends StatelessWidget {
  const _SimilarSpecies();

  static const _data = [
    {'name': 'Cashew Tree',  'family': 'Anacardiaceae', 'color': 0xFFFAEEDA, 'icon': Icons.park_outlined,   'ic': 0xFFBA7517},
    {'name': 'Breadfruit',   'family': 'Moraceae',      'color': 0xFFE1F5EE, 'icon': Icons.forest_outlined,  'ic': 0xFF0F6E56},
    {'name': 'Papaya',       'family': 'Caricaceae',    'color': 0xFFFAECE7, 'icon': Icons.eco_outlined,     'ic': 0xFF993C1D},
    {'name': 'Guava',        'family': 'Myrtaceae',     'color': 0xFFFAEEDA, 'icon': Icons.yard_outlined,    'ic': 0xFF854F0B},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _data.length,
      itemBuilder: (_, i) {
        final d = _data[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: kBorder, width: 0.5),
              borderRadius: kBRMd,
              color: kWhite,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(d['color'] as int),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Icon(d['icon'] as IconData,
                          size: 24, color: Color(d['ic'] as int)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(d['name'] as String,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500, color: kTx),
                          textAlign: TextAlign.center),
                      Text(d['family'] as String,
                          style: const TextStyle(fontSize: 9, color: kMu),
                          textAlign: TextAlign.center),
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

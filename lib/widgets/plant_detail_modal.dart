// lib/widgets/plant_detail_modal.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/identification_result.dart';
import 'eco_card.dart';
import 'care_row.dart';
import 'info_row.dart';

/// Opens the plant detail popup over a blurred backdrop of the current screen.
Future<void> showPlantDetailModal(
  BuildContext context, {
  required String commonName,
  required String scientificName,
  required String familyName,
  required String type,
  required bool healthy,
  required Color cardColor,
  required Color iconColor,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 960,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Material(
              color: Colors.transparent,
              child: _PlantDetailModal(
                commonName: commonName,
                scientificName: scientificName,
                familyName: familyName,
                type: type,
                healthy: healthy,
                cardColor: cardColor,
                iconColor: iconColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlantDetailModal extends StatefulWidget {
  final String commonName;
  final String scientificName;
  final String familyName;
  final String type;
  final bool healthy;
  final Color cardColor;
  final Color iconColor;

  const _PlantDetailModal({
    required this.commonName,
    required this.scientificName,
    required this.familyName,
    required this.type,
    required this.healthy,
    required this.cardColor,
    required this.iconColor,
  });

  @override
  State<_PlantDetailModal> createState() => _PlantDetailModalState();
}

class _PlantDetailModalState extends State<_PlantDetailModal> {
  int _tab = 0;
  static const _tabs = ['Overview', 'Ecology', 'Benefits', 'Care Tips', 'Gallery'];

  // Rich per-species data (growth habit, medicinal uses, etc.) isn't wired
  // for the Explorer sample set yet — reuse the one hardcoded detail record,
  // but keep the header fields true to the card that was actually tapped.
  late final PlantSpeciesSimple _detail = _buildDetail();

  PlantSpeciesSimple _buildDetail() {
    final sample = PlantSpeciesSimple.mangoSample;
    return PlantSpeciesSimple(
      id: 'sample-${widget.commonName}',
      commonName: widget.commonName,
      scientificName: widget.scientificName,
      familyName: widget.familyName,
      localNameTwi: sample.localNameTwi,
      growthHabit: sample.growthHabit,
      leafType: sample.leafType,
      floweringSeason: sample.floweringSeason,
      origin: sample.origin,
      ecologicalImportance: sample.ecologicalImportance,
      environmentalBenefits: sample.environmentalBenefits,
      medicinalUses: sample.medicinalUses,
      economicImportance: sample.economicImportance,
      waterRequirements: sample.waterRequirements,
      sunlightRequirements: sample.sunlightRequirements,
      soilPreference: sample.soilPreference,
      modelClassIndex: sample.modelClassIndex,
      didYouKnowFacts: sample.didYouKnowFacts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: kBRXl,
      child: Container(
        color: kWhite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildInfoBar(),
              _buildTabBar(),
              Padding(
                padding: const EdgeInsets.all(kSp24),
                child: _buildTabContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: colour block + gradient + overlaid name/badge/actions ──
  Widget _buildHeader() {
    final typeLabel = widget.type.isEmpty
        ? ''
        : widget.type[0].toUpperCase() + widget.type.substring(1);

    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: widget.cardColor),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(Icons.eco_outlined,
                size: 80, color: widget.iconColor.withValues(alpha: 0.85)),
          ),
          Positioned(
            top: 16, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kDeep.withValues(alpha: 0.55),
                borderRadius: kBRPill,
              ),
              child: Text(typeLabel,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            left: 20, right: 90, bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.commonName,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600,
                        color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(widget.scientificName,
                    style: TextStyle(
                        fontSize: 14, fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: Row(
              children: [
                _HeaderIconBtn(icon: Icons.favorite_border, onTap: () {}),
                const SizedBox(width: 8),
                _HeaderIconBtn(icon: Icons.share_outlined, onTap: () {}),
                const SizedBox(width: 8),
                _HeaderIconBtn(icon: Icons.volume_up_outlined, onTap: () {}),
              ],
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: _HeaderIconBtn(
                icon: Icons.close, onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }

  // ── Thin info bar: family / local name / confidence / health ───────
  Widget _buildInfoBar() {
    Widget divider() => Container(
          width: 1, height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: kBorder,
        );

    return Container(
      width: double.infinity,
      color: kLight,
      padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoBarItem(label: 'Family', value: widget.familyName),
          divider(),
          _InfoBarItem(
              label: 'Local name',
              value: _detail.localNameTwi ?? '—'),
          divider(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('AI Confidence: ',
                  style: TextStyle(fontSize: 12, color: kMu)),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 80,
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: kBorder),
                      FractionallySizedBox(
                        widthFactor: 0.94,
                        child: Container(color: kDeep),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('94%',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: kDeep)),
            ],
          ),
          divider(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.healthy
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                size: 15,
                color: widget.healthy ? kHealthyTx : kUnhealthyTx,
              ),
              const SizedBox(width: 5),
              Text(widget.healthy ? 'Healthy' : 'Needs care',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: widget.healthy ? kHealthyTx : kUnhealthyTx)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kSp24),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final active = _tab == i;
            return GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                      color: active ? kDeep : Colors.transparent, width: 2)),
                ),
                child: Text(_tabs[i],
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: active ? kDeep : kMu)),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A fast-growing tree prized across West Africa for its medicinal '
              'bark, leaves, and seeds. Provides dense shade and is '
              'drought-resistant, making it ideal for arid and semi-arid '
              'zones of Ghana.',
              style: TextStyle(fontSize: 13, color: kMu, height: 1.6),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
              childAspectRatio: 3.0,
              children: [
                InfoRow('Height', _detail.growthHabit ?? '—'),
                InfoRow('Leaf Shape', _detail.leafType ?? '—'),
                InfoRow('Flowering', _detail.floweringSeason ?? '—'),
                InfoRow('Soil', _detail.soilPreference ?? '—'),
              ],
            ),
          ],
        );
      case 1:
        return Column(children: [
          EcoCard(
            iconBg: kLight, iconColor: kGreen, icon: Icons.air_outlined,
            title: 'Carbon absorption',
            body: _detail.environmentalBenefits ??
                'Absorbs CO₂ annually, contributing to campus carbon neutrality goals.',
          ),
          EcoCard(
            iconBg: kLight, iconColor: kDeep, icon: Icons.park_outlined,
            title: 'Wildlife support',
            body: _detail.ecologicalImportance ??
                'Supports birds and bees; seeds eaten by many bird species.',
          ),
        ]);
      case 2:
        return Column(children: [
          EcoCard(
            title: 'Medicinal uses',
            body: _detail.medicinalUses ?? 'Traditional medicinal uses documented.'),
          EcoCard(
            title: 'Economic importance',
            body: _detail.economicImportance ?? 'Significant economic value.'),
        ]);
      case 3:
        return Column(children: [
          CareRow(
            iconBg: const Color(0xFFE6F1FB), iconColor: const Color(0xFF185FA5),
            icon: Icons.water_drop_outlined, title: 'Water',
            body: _detail.waterRequirements ?? 'Moderate watering requirements.'),
          CareRow(
            iconBg: kAmberL, iconColor: kAmber,
            icon: Icons.wb_sunny_outlined, title: 'Sunlight',
            body: _detail.sunlightRequirements ?? 'Full sun preferred.'),
          CareRow(
            iconBg: kLight, iconColor: kDeep,
            icon: Icons.layers_outlined, title: 'Soil',
            body: _detail.soilPreference ?? 'Well-draining, loamy soil preferred.'),
        ]);
      case 4:
        return _GalleryTab(cardColor: widget.cardColor, iconColor: widget.iconColor);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InfoBarItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBarItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, color: kMu)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: kTx)),
      ],
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ── Gallery tab — placeholder tiles using the species' own colour
//    identity since no per-species photo library exists yet.
class _GalleryTab extends StatelessWidget {
  final Color cardColor;
  final Color iconColor;
  const _GalleryTab({required this.cardColor, required this.iconColor});

  static const _icons = [
    Icons.eco_outlined, Icons.park_outlined, Icons.local_florist_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _icons.length,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: kBRLg,
        ),
        child: Center(child: Icon(_icons[i], size: 36, color: iconColor)),
      ),
    );
  }
}

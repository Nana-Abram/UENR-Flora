// lib/widgets/compare_species_modal.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/plant_species.dart';

/// Opens a side-by-side comparison of exactly two species over a blurred
/// backdrop — same presentation pattern as [showPlantDetailModal], but two
/// columns instead of one.
Future<void> showCompareSpeciesModal(
  BuildContext context, {
  required PlantSpecies a,
  required PlantSpecies b,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(ctx).size.width < kBreakpointSm ? 12 : 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Material(
              color: Colors.transparent,
              child: _CompareSpeciesModal(a: a, b: b),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CompareSpeciesModal extends StatelessWidget {
  final PlantSpecies a;
  final PlantSpecies b;
  const _CompareSpeciesModal({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kWhite, borderRadius: kBR2xl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Text('Compare Species',
                    style: TextStyle(
                        fontFamily: kFontDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kTx)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: kMu),
                  tooltip: 'Close comparison',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SpeciesHeader(species: a)),
                      const SizedBox(width: 16),
                      Expanded(child: _SpeciesHeader(species: b)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _CompareShortRow('Family', a.familyName, b.familyName),
                  _CompareShortRow('Growth habit', a.growthHabit, b.growthHabit),
                  _CompareShortRow('Height', a.heightRange, b.heightRange),
                  _CompareShortRow('Origin', a.origin, b.origin),
                  _CompareShortRow('Water', a.waterRequirements, b.waterRequirements),
                  _CompareShortRow('Sunlight', a.sunlightRequirements, b.sunlightRequirements),
                  _CompareShortRow('Soil', a.soilPreference, b.soilPreference),
                  const SizedBox(height: 12),
                  _CompareLongSection(
                    'Ecological importance',
                    a.ecologicalImportance,
                    b.ecologicalImportance,
                  ),
                  _CompareLongSection(
                    'Environmental benefits',
                    a.environmentalBenefits,
                    b.environmentalBenefits,
                  ),
                  _CompareLongSection('Medicinal uses', a.medicinalUses, b.medicinalUses),
                  _CompareLongSection(
                    'Economic importance',
                    a.economicImportance,
                    b.economicImportance,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesHeader extends StatelessWidget {
  final PlantSpecies species;
  const _SpeciesHeader({required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: kBRLg,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: species.referenceImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: species.referenceImageUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 500,
                    placeholder: (_, __) => Container(color: kMuted),
                    errorWidget: (_, __, ___) => Container(
                      color: kMuted,
                      child: Icon(Icons.eco_outlined, color: kMu),
                    ),
                  )
                : Container(
                    color: kMuted,
                    child: Center(child: Icon(Icons.eco_outlined, color: kMu)),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(species.commonName,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTx),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        Text(species.scientificName,
            style: TextStyle(fontSize: 12, color: kMu, fontStyle: FontStyle.italic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

/// One label with two short values side by side — for fields that are
/// normally a phrase or two (Family, Height, Water requirements, etc).
class _CompareShortRow extends StatelessWidget {
  final String label;
  final String? a;
  final String? b;
  const _CompareShortRow(this.label, this.a, this.b);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: kBg, borderRadius: kBRSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: kMu, letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(a ?? '—',
                    style: TextStyle(fontSize: 13, color: kTx)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(b ?? '—',
                    style: TextStyle(fontSize: 13, color: kTx)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A label header followed by two paragraph-length values side by side —
/// for fields that can run to a sentence or more (ecological importance,
/// medicinal uses, etc). Skipped entirely when neither species has a value,
/// so the comparison doesn't fill up with empty "—" sections.
class _CompareLongSection extends StatelessWidget {
  final String label;
  final String? a;
  final String? b;
  const _CompareLongSection(this.label, this.a, this.b);

  @override
  Widget build(BuildContext context) {
    if (a == null && b == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(a ?? 'No documented information.',
                    style: TextStyle(fontSize: 12, color: kMu, height: 1.5)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(b ?? 'No documented information.',
                    style: TextStyle(fontSize: 12, color: kMu, height: 1.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// lib/widgets/plant_detail_modal.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/dashboard_provider.dart';
import '../core/favorites_provider.dart';
import '../core/species_text.dart';
import '../core/string_utils.dart';
import '../models/plant_species.dart';
import '../services/web_share_service.dart';
import 'eco_card.dart';
import 'info_row.dart';
import 'read_aloud_button.dart';

/// Opens the plant detail popup over a blurred backdrop of the current screen.
Future<void> showPlantDetailModal(
  BuildContext context, {
  required PlantSpecies species,
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
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(ctx).size.width < kBreakpointSm ? 12 : 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 960,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Material(
              color: Colors.transparent,
              child: _PlantDetailModal(
                species: species,
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
  final PlantSpecies species;
  final String type;
  final bool healthy;
  final Color cardColor;
  final Color iconColor;

  const _PlantDetailModal({
    required this.species,
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

  PlantSpecies get _detail => widget.species;

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
    final typeLabel = capitalize(widget.type);

    final imageUrl = widget.species.referenceImageUrl;

    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              // Modal caps at 960 logical px wide (showPlantDetailModal) and
              // this header is 230 tall — decode near that instead of
              // whatever resolution the source photo happens to be.
              memCacheWidth: 1000,
              memCacheHeight: 460,
              placeholder: (_, __) => Container(color: widget.cardColor),
              errorWidget: (_, __, ___) => Container(
                color: widget.cardColor,
                child: Center(
                  child: Icon(Icons.eco_outlined,
                      size: 80, color: widget.iconColor.withValues(alpha: 0.85)),
                ),
              ),
            )
          else
            Container(
              color: widget.cardColor,
              child: Center(
                child: Icon(Icons.eco_outlined,
                    size: 80, color: widget.iconColor.withValues(alpha: 0.85)),
              ),
            ),
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
                Text(widget.species.commonName,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600,
                        color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(widget.species.scientificName,
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
                ReadAloudButton(
                  circle: true,
                  textBuilder: () => speciesFullReadText(widget.species),
                ),
                const SizedBox(width: 8),
                _FavoriteIconBtn(speciesId: widget.species.id),
                const SizedBox(width: 8),
                _ShareIconBtn(species: widget.species),
              ],
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: _HeaderIconBtn(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
                label: 'Close'),
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

    // select (not watch) — this widget only cares about this one species'
    // confidence, not every field DashboardProvider might change.
    final confidence = context
        .select<DashboardProvider, double?>((p) => p.confidenceFor(widget.species.id));

    return Container(
      width: double.infinity,
      color: kLight,
      padding: const EdgeInsets.symmetric(horizontal: kSp24, vertical: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _InfoBarItem(label: 'Family', value: widget.species.familyName ?? 'Unclassified'),
          divider(),
          _InfoBarItem(
              label: 'Local name',
              value: _detail.localNameTwi ?? '—'),
          divider(),
          if (confidence != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AI Confidence: ',
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
                          widthFactor: confidence.clamp(0, 1),
                          child: Container(color: kDeep),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(confidence * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: kDeep)),
              ],
            )
          else
            Text('Not yet scanned',
                style: TextStyle(fontSize: 12, color: kMu)),
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
      decoration: BoxDecoration(
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
        return LayoutBuilder(builder: (_, bc) {
          final narrow = bc.maxWidth < kBreakpointMd;
          final overviewCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(speciesOverviewSummary(_detail),
                  style: TextStyle(fontSize: 13, color: kMu, height: 1.6)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                childAspectRatio: 3.0,
                children: [
                  InfoRow('Height', _detail.heightRange ?? '—'),
                  InfoRow('Leaf Shape', _detail.leafType ?? '—'),
                  InfoRow('Flowering', _detail.floweringSeason ?? '—'),
                  InfoRow('Soil', _detail.soilPreference ?? '—'),
                ],
              ),
            ],
          );
          final didYouKnow = _detail.didYouKnowFacts.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: kBRLg,
                    border: Border.all(color: Colors.amber, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 15, color: Colors.amber),
                          SizedBox(width: 7),
                          Text('Did you know?',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF973C00))),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(_detail.didYouKnowFacts.first,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF973C00), height: 1.5)),
                    ],
                  ),
                )
              : null;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                overviewCol,
                if (didYouKnow != null) ...[const SizedBox(height: 16), didYouKnow],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: overviewCol),
              if (didYouKnow != null) ...[
                const SizedBox(width: 16),
                Expanded(flex: 2, child: didYouKnow),
              ],
            ],
          );
        });
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
        return LayoutBuilder(builder: (_, bc) {
          final narrow = bc.maxWidth < kBreakpointMd;
          final growing = _CareGroupCard(
            title: 'Growing Requirements',
            children: [
              _CareGroupRow(
                  icon: Icons.water_drop_outlined, iconColor: const Color(0xFF185FA5),
                  label: 'Water',
                  value: _detail.waterRequirements ?? 'Moderate watering requirements.'),
              _CareGroupRow(
                  icon: Icons.wb_sunny_outlined, iconColor: kAccent,
                  label: 'Sunlight',
                  value: _detail.sunlightRequirements ?? 'Full sun preferred.'),
              _CareGroupRow(
                  icon: Icons.layers_outlined, iconColor: kDeep,
                  label: 'Soil',
                  value: _detail.soilPreference ?? 'Well-draining, loamy soil preferred.'),
            ],
          );
          final phenology = _CareGroupCard(
            title: 'Phenology',
            children: [
              _PhenologyLine(label: 'Leaf shape', value: _detail.leafType ?? '—'),
              _PhenologyLine(label: 'Flowering', value: _detail.floweringSeason ?? '—'),
              _PhenologyLine(label: 'Max height', value: _detail.heightRange ?? '—'),
            ],
          );
          if (narrow) {
            return Column(
              children: [growing, const SizedBox(height: 16), phenology],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: growing),
              const SizedBox(width: 16),
              Expanded(child: phenology),
            ],
          );
        });
      case 4:
        return _GalleryTab(
          imageUrls: _detail.galleryImageUrls,
          cardColor: widget.cardColor,
          iconColor: widget.iconColor,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _CareGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _CareGroupCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kLight, borderRadius: kBRLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: kTx)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _CareGroupRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _CareGroupRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: kMu)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: kTx)),
          ),
        ],
      ),
    );
  }
}

class _PhenologyLine extends StatelessWidget {
  final String label;
  final String value;
  const _PhenologyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: kMu),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
                text: value,
                style: TextStyle(fontWeight: FontWeight.w500, color: kTx)),
          ],
        ),
      ),
    );
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
        Text('$label: ', style: TextStyle(fontSize: 12, color: kMu)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: kTx)),
      ],
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final String label;
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    required this.label,
    this.iconColor,
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
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            child: Icon(icon, size: 16, color: iconColor ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Heart toggle backed by [FavoritesProvider] — filled/pink when this
/// species is favorited, outline/white otherwise.
class _FavoriteIconBtn extends StatelessWidget {
  final String speciesId;
  const _FavoriteIconBtn({required this.speciesId});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final active = favorites.isFavorite(speciesId);
    return _HeaderIconBtn(
      icon: active ? Icons.favorite : Icons.favorite_border,
      iconColor: active ? kUnhealthyTx : Colors.white,
      onTap: () => context.read<FavoritesProvider>().toggle(speciesId),
      label: active ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}

/// Shares a species via the native share sheet (falling back to copying a
/// link to the clipboard) and surfaces the outcome with a snackbar.
class _ShareIconBtn extends StatelessWidget {
  final PlantSpecies species;
  const _ShareIconBtn({required this.species});

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
    return _HeaderIconBtn(
      icon: Icons.share_outlined,
      onTap: () => _share(context),
      label: 'Share this plant',
    );
  }
}

// ── Gallery tab — real per-species photos, falls back to a placeholder
//    icon tile when a species has no photos yet.
class _GalleryTab extends StatelessWidget {
  final List<String> imageUrls;
  final Color cardColor;
  final Color iconColor;
  const _GalleryTab({
    required this.imageUrls,
    required this.cardColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: cardColor, borderRadius: kBRLg),
        child: Center(
          child: Icon(Icons.eco_outlined, size: 36,
              color: iconColor.withValues(alpha: 0.85)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _openFullScreen(context, i),
        child: ClipRRect(
          borderRadius: kBRLg,
          child: CachedNetworkImage(
            imageUrl: imageUrls[i],
            fit: BoxFit.cover,
            // 3-across grid in a <=960px-wide modal — cells are roughly
            // 300px square, never full source resolution.
            memCacheWidth: 400,
            memCacheHeight: 400,
            placeholder: (_, __) => Container(color: cardColor),
            errorWidget: (_, __, ___) => Container(
              color: cardColor,
              child: Center(
                  child: Icon(Icons.eco_outlined, size: 28, color: iconColor)),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _FullScreenGallery(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const _FullScreenGallery({required this.imageUrls, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            itemBuilder: (_, i) => Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: _HeaderIconBtn(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
                label: 'Close'),
          ),
        ],
      ),
    );
  }
}

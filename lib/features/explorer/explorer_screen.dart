// lib/features/explorer/explorer_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/species_provider.dart';
import '../../core/dashboard_provider.dart';
import '../../core/category_style.dart';
import '../../core/species_text.dart';
import '../../models/plant_species.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/plant_detail_modal.dart';
import '../../widgets/hover_lift.dart';
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(kSp24, kSp16, kSp24, kSp32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Breadcrumb(current: 'Plant Explorer'),
                    SizedBox(height: 16),
                    _ExplorerHeader(),
                    SizedBox(height: 20),
                    _FilterChips(),
                    SizedBox(height: 20),
                    _PlantGrid(),
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
            children: [_PageFooter()],
          ),
        ),
      ],
    );
  }
}

// ── Header: title + live count + search + grid/list toggle ───────────
class _ExplorerHeader extends StatelessWidget {
  const _ExplorerHeader();

  @override
  Widget build(BuildContext context) {
    final speciesState = context.watch<SpeciesProvider>();
    final explorer = context.watch<ExplorerProvider>();
    final total = speciesState.totalCount;
    final filteredCount = explorer.apply(speciesState.all).length;
    final isFiltered = explorer.filter != 'all' || explorer.query.trim().isNotEmpty;
    final subtitle = total == 0
        ? 'Documented UENR campus species'
        : isFiltered
            ? '$filteredCount of $total species documented at UENR, Sunyani Campus'
            : '$total species documented at UENR, Sunyani Campus';

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plant Explorer',
            style: TextStyle(
                fontFamily: kFontDisplay, fontSize: 32, fontWeight: FontWeight.w600, color: kTx)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: kMu)),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kBreakpointLg;
        void onChanged(String v) => context.read<ExplorerProvider>().setQuery(v);
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 230, height: 40, child: _SearchField(onChanged: onChanged)),
                  const SizedBox(width: 10),
                  const _ViewToggle(),
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: SizedBox(height: 40, child: _SearchField(onChanged: onChanged))),
                const SizedBox(width: 10),
                const _ViewToggle(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: kTx),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plant...',
        hintStyle: const TextStyle(fontSize: 13, color: kMu),
        prefixIcon: const Icon(Icons.search, size: 17, color: kMu),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: kBRPill, borderSide: const BorderSide(color: kBorder, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: kBRPill, borderSide: const BorderSide(color: kBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: kBRPill, borderSide: const BorderSide(color: kGreen)),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context) {
    final explorer = context.watch<ExplorerProvider>();

    Widget seg(String label, IconData icon, ExplorerViewMode mode) {
      final active = explorer.viewMode == mode;
      return GestureDetector(
        onTap: () => context.read<ExplorerProvider>().setViewMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? kWhite : Colors.transparent,
            borderRadius: kBRPill,
            border: active ? Border.all(color: kBorder, width: 0.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: active ? kTx : kMu),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: active ? kTx : kMu)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: kMuted, borderRadius: kBRPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg('Grid', Icons.grid_view_rounded, ExplorerViewMode.grid),
          seg('List', Icons.view_list_rounded, ExplorerViewMode.list),
        ],
      ),
    );
  }
}

// ── Filter chips row ─────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  static const _filters = [
    {'label': 'All',         'value': 'all'},
    {'label': 'Trees',       'value': 'trees'},
    {'label': 'Shrubs',      'value': 'shrubs'},
    {'label': 'Herbs',       'value': 'herbs'},
    {'label': 'Medicinal',   'value': 'medicinal'},
    {'label': 'Ornamental',  'value': 'ornamental'},
  ];

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ExplorerProvider>().filter;
    final totalCount = context.watch<SpeciesProvider>().totalCount;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isActive = active == f['value'];
          final label = f['value'] == 'all' && totalCount > 0
              ? 'All ($totalCount)'
              : f['label']!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  context.read<ExplorerProvider>().setFilter(f['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? kDeep : kWhite,
                  border: Border.all(
                      color: isActive ? kDeep : kBorder, width: 0.5),
                  borderRadius: kBRPill,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
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

// ── Grid / List content ───────────────────────────────────────
class _PlantGrid extends StatelessWidget {
  const _PlantGrid();

  @override
  Widget build(BuildContext context) {
    final speciesState = context.watch<SpeciesProvider>();

    if (speciesState.loading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator(color: kDeep)),
      );
    }

    if (speciesState.error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Text(speciesState.error!,
                  style: const TextStyle(fontSize: 13, color: kMu),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.read<SpeciesProvider>().reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final explorer = context.watch<ExplorerProvider>();
    final plants = explorer.apply(speciesState.all);

    if (plants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No plants found for this filter.',
              style: TextStyle(fontSize: 13, color: kMu)),
        ),
      );
    }

    if (explorer.viewMode == ExplorerViewMode.list) {
      return Column(
        children: [
          for (final species in plants)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ExplorerListRow(species: species),
            ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 268,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plants.length,
      itemBuilder: (context, i) => _ExplorerCard(species: plants[i]),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _ExplorerCard extends StatelessWidget {
  final PlantSpecies species;

  const _ExplorerCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final type = species.growthType ?? '';
    final familyName = species.familyName ?? 'Unclassified';
    final style = categoryStyle(species.growthType);
    final confidence = context.watch<DashboardProvider>().confidenceFor(species.id);

    return HoverLift(
      borderRadius: kBRXl,
      onTap: () => showPlantDetailModal(
        context,
        species: species,
        type: type,
        healthy: true,
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
            // Reference photo, falling back to a coloured placeholder
            SizedBox(
              height: 120,
              width: double.infinity,
              child: species.referenceImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: species.referenceImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: cardColor,
                        child: Center(
                          child: Icon(Icons.eco_outlined, size: 36, color: iconColor),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: cardColor,
                        child: Center(
                          child: Icon(Icons.eco_outlined, size: 36, color: iconColor),
                        ),
                      ),
                    )
                  : Container(
                      color: cardColor,
                      child: Center(
                        child: Icon(Icons.eco_outlined, size: 36, color: iconColor),
                      ),
                    ),
            ),
            // Text area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(species.commonName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: kTx),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(species.scientificName,
                            style: const TextStyle(
                                fontSize: 11, color: kMu,
                                fontStyle: FontStyle.italic),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Family: $familyName',
                            style: const TextStyle(fontSize: 10, color: kMu),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
                            child: Text(_capitalize(type),
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w500, color: style.text)),
                          )
                        else
                          const SizedBox.shrink(),
                        if (confidence != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text('${(confidence * 100).round()}%',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: kTx)),
                            ],
                          )
                        else
                          const Text('—', style: TextStyle(fontSize: 11, color: kMu)),
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

class _ExplorerListRow extends StatelessWidget {
  final PlantSpecies species;
  const _ExplorerListRow({required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final type = species.growthType ?? '';
    final familyName = species.familyName ?? 'Unclassified';
    final style = categoryStyle(species.growthType);
    final confidence = context.watch<DashboardProvider>().confidenceFor(species.id);

    return GestureDetector(
      onTap: () => showPlantDetailModal(
        context,
        species: species,
        type: type,
        healthy: true,
        cardColor: cardColor,
        iconColor: iconColor,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          border: Border.all(color: kBorder, width: 0.5),
          borderRadius: kBRXl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: kBRMd,
              child: SizedBox(
                width: 64, height: 64,
                child: species.referenceImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: species.referenceImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: cardColor,
                          child: Center(child: Icon(Icons.eco_outlined, size: 22, color: iconColor)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: cardColor,
                          child: Center(child: Icon(Icons.eco_outlined, size: 22, color: iconColor)),
                        ),
                      )
                    : Container(
                        color: cardColor,
                        child: Center(child: Icon(Icons.eco_outlined, size: 22, color: iconColor)),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(species.commonName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
                          child: Text(_capitalize(type),
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500, color: style.text)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${species.scientificName} · Family: $familyName',
                      style: const TextStyle(fontSize: 12, color: kMu, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(speciesOverviewSummary(species),
                      style: const TextStyle(fontSize: 12, color: kMu),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Confidence', style: TextStyle(fontSize: 11, color: kMu)),
                const SizedBox(height: 2),
                Text(
                  confidence != null ? '${(confidence * 100).round()}%' : '—',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDeep),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, size: 18, color: kMu),
          ],
        ),
      ),
    );
  }
}

// ── Page footer ────────────────────────────────────────────────
class _PageFooter extends StatelessWidget {
  const _PageFooter();

  @override
  Widget build(BuildContext context) {
    return  Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'UENR Flora Environmental Learning Hub. Group 4 Final Year Project',
                style: TextStyle(fontSize: 11, color:kMu),
                textAlign: TextAlign.center,
              ),
            ),
          );
  }
}

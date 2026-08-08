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
import '../../core/string_utils.dart';
import '../../models/plant_species.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/plant_detail_modal.dart';
import '../../widgets/compare_species_modal.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/hover_zoom_image.dart';
import 'explorer_provider.dart';

class ExplorerScreen extends StatelessWidget {
  /// Seeds the search query from `/explorer?q=...` — set when a search is
  /// submitted from the navbar or home hero search fields, so those
  /// actually land on a filtered Explorer page instead of an empty one.
  final String? initialQuery;

  /// Set from `/explorer?species=<id>` — the deep link produced by the
  /// share button on plant cards/the detail modal. Opens that species'
  /// detail modal once the species list has loaded.
  final String? initialSpeciesId;

  const ExplorerScreen({super.key, this.initialQuery, this.initialSpeciesId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExplorerProvider()..setQuery(initialQuery ?? ''),
      child: _ExplorerBody(initialQuery: initialQuery, initialSpeciesId: initialSpeciesId),
    );
  }
}

class _ExplorerBody extends StatefulWidget {
  final String? initialQuery;
  final String? initialSpeciesId;
  const _ExplorerBody({this.initialQuery, this.initialSpeciesId});

  @override
  State<_ExplorerBody> createState() => _ExplorerBodyState();
}

class _ExplorerBodyState extends State<_ExplorerBody> {
  bool _deepLinkHandled = false;

  @override
  void didUpdateWidget(covariant _ExplorerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ChangeNotifierProvider's `create` only runs once per Element, so if
    // go_router reuses this same page (e.g. a second "/explorer?q=..."
    // search submitted from the navbar while already on this route), the
    // new query would otherwise never reach the already-created
    // ExplorerProvider — silently dropping the second search.
    if (widget.initialQuery != oldWidget.initialQuery) {
      context.read<ExplorerProvider>().setQuery(widget.initialQuery ?? '');
    }
  }

  void _maybeOpenDeepLink(SpeciesProvider provider) {
    final id = widget.initialSpeciesId;
    if (id == null || _deepLinkHandled || provider.loading) return;
    _deepLinkHandled = true;

    PlantSpecies? target;
    for (final s in provider.all) {
      if (s.id == id) {
        target = s;
        break;
      }
    }
    if (target == null) return;
    final species = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colors = colorPairForId(species.id);
      showPlantDetailModal(
        context,
        species: species,
        type: species.growthType ?? '',
        healthy: true,
        cardColor: Color(colors[0]),
        iconColor: Color(colors[1]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeOpenDeepLink(context.watch<SpeciesProvider>());

    // Centers the (kMaxContentWidth-capped) page content the same way the
    // old single ConstrainedBox+Align did — but split across two
    // SliverPadding sections instead of one Align/ConstrainedBox, since
    // those are box widgets and can't wrap a sliver. The grid section
    // below needs to be a *real* sliver (SliverGrid/SliverList), not a
    // GridView.builder(shrinkWrap: true) nested in a Column, so that
    // itemBuilder only runs for on-screen cards as the species catalog
    // (76 and growing) gets longer — see _PlantGridSliver.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding =
        screenWidth > kMaxContentWidth ? (screenWidth - kMaxContentWidth) / 2 + kSp24 : kSp24;

    return RefreshIndicator(
      color: kDeep,
      onRefresh: () => context.read<SpeciesProvider>().reload(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, kSp16, horizontalPadding, 0),
            sliver: const SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumb(current: 'Plant Explorer'),
                  SizedBox(height: 16),
                  _ExplorerHeader(),
                  SizedBox(height: 20),
                  _FilterChips(),
                  SizedBox(height: 20),
                  _CompareBar(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, kSp32),
            sliver: const _PlantGridSliver(),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppFooter(
                  message: 'UENR Flora Environmental Learning Hub. Group 4 Final Year Project',
                  elevated: false,
                ),
              ],
            ),
          ),
        ],
      ),
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
        Text('Plant Explorer',
            style: TextStyle(
                fontFamily: kFontDisplay, fontSize: 32, fontWeight: FontWeight.w600, color: kTx)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 14, color: kMu)),
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
                  SizedBox(
                    width: 230,
                    height: 40,
                    child: _SearchField(initialText: explorer.query, onChanged: onChanged),
                  ),
                  const SizedBox(width: 10),
                  const _ViewToggle(),
                  const SizedBox(width: 10),
                  const _CompareToggleButton(),
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
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: _SearchField(initialText: explorer.query, onChanged: onChanged),
                  ),
                ),
                const SizedBox(width: 10),
                const _ViewToggle(),
                const SizedBox(width: 10),
                const _CompareToggleButton(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  const _SearchField({this.initialText = '', required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.initialText)
    ..addListener(() => setState(() {}));

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

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
      style: TextStyle(fontSize: 13, color: kTx),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search plant...',
        hintStyle: TextStyle(fontSize: 13, color: kMu),
        prefixIcon: Icon(Icons.search, size: 17, color: kMu),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 16, color: kMu),
                tooltip: 'Clear search',
                splashRadius: 16,
                onPressed: _clear,
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: kBRPill, borderSide: BorderSide(color: kBorder, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: kBRPill, borderSide: BorderSide(color: kBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: kBRPill, borderSide: BorderSide(color: kGreen)),
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

/// Shown only in compare mode — tracks the current 0/1/2 selection and lets
/// the device either open the comparison (once exactly 2 are picked) or
/// back out of compare mode entirely.
class _CompareBar extends StatelessWidget {
  const _CompareBar();

  @override
  Widget build(BuildContext context) {
    final explorer = context.watch<ExplorerProvider>();
    if (!explorer.compareMode) return const SizedBox.shrink();

    final selection = explorer.compareSelection;
    final canCompare = selection.length == 2;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kAccentL,
        borderRadius: kBRLg,
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, size: 16, color: kDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              canCompare
                  ? '2 species selected — ready to compare.'
                  : 'Select ${2 - selection.length} more species to compare (${selection.length}/2 selected).',
              style: TextStyle(fontSize: 13, color: kTx),
            ),
          ),
          TextButton(
            onPressed: () => context.read<ExplorerProvider>().toggleCompareMode(),
            child: Text('Cancel', style: TextStyle(color: kMu)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: canCompare
                ? () {
                    final all = context.read<SpeciesProvider>().all;
                    final ids = selection.toList();
                    final a = all.where((s) => s.id == ids[0]).firstOrNull;
                    final b = all.where((s) => s.id == ids[1]).firstOrNull;
                    if (a != null && b != null) {
                      showCompareSpeciesModal(context, a: a, b: b);
                    }
                  }
                : null,
            child: const Text('Compare'),
          ),
        ],
      ),
    );
  }
}

class _CompareToggleButton extends StatelessWidget {
  const _CompareToggleButton();

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ExplorerProvider>().compareMode;
    return Semantics(
      button: true,
      selected: active,
      label: active ? 'Exit compare mode' : 'Compare species',
      child: Tooltip(
        message: active ? 'Exit compare mode' : 'Compare species',
        excludeFromSemantics: true,
        child: Material(
          color: active ? kDeep : kMuted,
          borderRadius: kBRPill,
          child: InkWell(
            borderRadius: kBRPill,
            onTap: () => context.read<ExplorerProvider>().toggleCompareMode(),
            child: SizedBox(
              width: 40, height: 40,
              child: Icon(Icons.compare_arrows, size: 18, color: active ? kMint : kMu),
            ),
          ),
        ),
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
// Returns a real sliver (SliverGrid/SliverList) rather than a
// GridView.builder(shrinkWrap: true) nested in a Column, so cards are only
// built as they scroll into view instead of all at once — see the comment
// in _ExplorerBody.build().
class _PlantGridSliver extends StatelessWidget {
  const _PlantGridSliver();

  @override
  Widget build(BuildContext context) {
    final speciesState = context.watch<SpeciesProvider>();

    if (speciesState.loading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator(color: kDeep)),
        ),
      );
    }

    if (speciesState.error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Text(speciesState.error!,
                    style: TextStyle(fontSize: 13, color: kMu),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<SpeciesProvider>().reload(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final explorer = context.watch<ExplorerProvider>();
    final plants = explorer.apply(speciesState.all);

    if (plants.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text('No plants found for this filter.',
                style: TextStyle(fontSize: 13, color: kMu)),
          ),
        ),
      );
    }

    if (explorer.viewMode == ExplorerViewMode.list) {
      return SliverList.builder(
        itemCount: plants.length,
        itemBuilder: (context, i) => Padding(
          key: ValueKey(plants[i].id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExplorerListRow(species: plants[i]),
        ),
      );
    }

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 268,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plants.length,
      itemBuilder: (context, i) =>
          _ExplorerCard(key: ValueKey(plants[i].id), species: plants[i]),
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  final PlantSpecies species;

  const _ExplorerCard({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = colorPairForId(species.id);
    final cardColor = Color(colors[0]);
    final iconColor = Color(colors[1]);
    final type = species.growthType ?? '';
    final familyName = species.familyName ?? 'Unclassified';
    final style = categoryStyle(species.growthType);
    // select (not watch) — each card only cares about its own species'
    // confidence, not every DashboardProvider field (a full dashboard
    // reload used to rebuild every card, not just the ones whose
    // confidence actually changed).
    final confidence =
        context.select<DashboardProvider, double?>((p) => p.confidenceFor(species.id));
    final compareMode = context.select<ExplorerProvider, bool>((p) => p.compareMode);
    final isSelectedForCompare =
        context.select<ExplorerProvider, bool>((p) => p.compareSelection.contains(species.id));

    return Stack(
      children: [
        HoverLift(
          borderRadius: kBRXl,
          onTap: () => compareMode
              ? context.read<ExplorerProvider>().toggleCompareSelection(species.id)
              : showPlantDetailModal(
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
              border: Border.all(
                color: isSelectedForCompare ? kGreen : kBorder,
                width: isSelectedForCompare ? 2 : 0.5,
              ),
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
              child: HoverZoomImage(
                child: species.referenceImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: species.referenceImageUrl!,
                        fit: BoxFit.cover,
                        // Grid cells cap at 230 logical px wide, 120 tall.
                        memCacheWidth: 460,
                        memCacheHeight: 240,
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
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: kTx),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(species.scientificName,
                            style: TextStyle(
                                fontSize: 11, color: kMu,
                                fontStyle: FontStyle.italic),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Family: $familyName',
                            style: TextStyle(fontSize: 10, color: kMu),
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
                            child: Text(capitalize(type),
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
                                decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text('${(confidence * 100).round()}%',
                                  style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.w600, color: kTx)),
                            ],
                          )
                        else
                          Text('—', style: TextStyle(fontSize: 11, color: kMu)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
        ),
        if (compareMode)
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelectedForCompare ? kGreen : Colors.white.withValues(alpha: 0.85),
                border: Border.all(
                    color: isSelectedForCompare ? kGreen : kBorder, width: 1.5),
              ),
              child: isSelectedForCompare
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
      ],
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
    // select (not watch) — each card only cares about its own species'
    // confidence, not every DashboardProvider field (a full dashboard
    // reload used to rebuild every card, not just the ones whose
    // confidence actually changed).
    final confidence =
        context.select<DashboardProvider, double?>((p) => p.confidenceFor(species.id));
    final compareMode = context.select<ExplorerProvider, bool>((p) => p.compareMode);
    final isSelectedForCompare =
        context.select<ExplorerProvider, bool>((p) => p.compareSelection.contains(species.id));

    return GestureDetector(
      onTap: () => compareMode
          ? context.read<ExplorerProvider>().toggleCompareSelection(species.id)
          : showPlantDetailModal(
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
          border: Border.all(
            color: isSelectedForCompare ? kGreen : kBorder,
            width: isSelectedForCompare ? 2 : 0.5,
          ),
          borderRadius: kBRXl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (compareMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelectedForCompare ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: isSelectedForCompare ? kGreen : kMu,
                ),
              ),
            ClipRRect(
              borderRadius: kBRMd,
              child: SizedBox(
                width: 64, height: 64,
                child: species.referenceImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: species.referenceImageUrl!,
                        fit: BoxFit.cover,
                        // List-row thumbnail is a fixed 64x64.
                        memCacheWidth: 128,
                        memCacheHeight: 128,
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTx),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: style.bg, borderRadius: kBRPill),
                          child: Text(capitalize(type),
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w500, color: style.text)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${species.scientificName} · Family: $familyName',
                      style: TextStyle(fontSize: 12, color: kMu, fontStyle: FontStyle.italic),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(speciesOverviewSummary(species),
                      style: TextStyle(fontSize: 12, color: kMu),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Confidence', style: TextStyle(fontSize: 11, color: kMu)),
                const SizedBox(height: 2),
                Text(
                  confidence != null ? '${(confidence * 100).round()}%' : '—',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDeep),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 18, color: kMu),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/storage/saved_searches_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/entities/type_count.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/type_counts_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/property_card.dart';

/// Paginated, filterable results screen — the website's 96-page catalog as
/// a native infinite list with a filters sheet, removable filter chips,
/// result count and saved searches.
class PropertiesListScreen extends StatefulWidget {
  final String? listingType;
  final int? cityId;
  final int? propertyTypeId;
  final int? developerId;
  final String? title;

  /// Full pre-built query (e.g. from AI Search). Takes precedence over the
  /// individual path params so caller and list show identical results.
  final PropertyQuery? initialQuery;

  const PropertiesListScreen({
    super.key,
    this.listingType,
    this.cityId,
    this.propertyTypeId,
    this.developerId,
    this.title,
    this.initialQuery,
  });

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  late final PropertiesCubit _cubit;
  late final TypeCountsCubit _typeCounts;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
    _cubit = sl<PropertiesCubit>()
      ..load(
        query:
            widget.initialQuery ??
            PropertyQuery(
              listingType: widget.listingType,
              cityId: widget.cityId,
              propertyTypeIds: [
                if (widget.propertyTypeId != null) widget.propertyTypeId!,
              ],
              developerId: widget.developerId,
            ),
      );
    _typeCounts = sl<TypeCountsCubit>()..load();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels > position.maxScrollExtent - 600) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _cubit.close();
    _typeCounts.close();
    super.dispose();
  }

  /// Pull-to-refresh: re-fetch the listings and force the type-count strip to
  /// re-run its fan-out so the counts can't sit stale behind the session cache.
  Future<void> _refresh() =>
      Future.wait([_cubit.refresh(), _typeCounts.load(forceRefresh: true)]);

  Future<void> _openFilters() async {
    final lookup = sl<LookupService>();
    final result = await showPropertyFiltersSheet(
      context,
      current: _cubit.query,
      lookup: lookup,
      savedSearches: sl<SavedSearchesStore>(),
    );
    if (result != null) {
      await _cubit.applyFilters(result);
      final state = _cubit.state;
      sl<AnalyticsService>().searchApplied(
        filterCount: result.activeFilterCount,
        resultsTotal: state is PropertiesLoaded ? state.pageInfo?.total : null,
      );
    }
  }

  Future<void> _saveCurrentSearch() async {
    final l10n = AppLocalizations.of(context);
    final lookup = sl<LookupService>();
    List<PropertyTypeOption> types = const [];
    List<CityOption> cities = const [];
    try {
      types = await lookup.propertyTypes();
      cities = await lookup.cities();
    } catch (_) {}
    if (!mounted) return;
    final q = _cubit.query;
    final label = describeQuery(q, types: types, cities: cities, l10n: l10n);
    await sl<SavedSearchesStore>().add(
      SavedSearch(
        label: label,
        listingType: q.listingType,
        propertyTypeIds: q.propertyTypeIds,
        cityId: q.cityId,
        minBedrooms: q.minBedrooms,
        minBathrooms: q.minBathrooms,
        minPrice: q.minPrice,
        maxPrice: q.maxPrice,
        furnishingStatus: q.furnishingStatus,
      ),
    );
    sl<AnalyticsService>().savedSearchCreated();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.searchSaved)));
    }
  }

  String _titleOf(AppLocalizations l10n) =>
      widget.title ??
      switch (widget.initialQuery?.listingType ?? widget.listingType) {
        'for-rent' => l10n.propertiesForRent,
        'for-sale' => l10n.propertiesForSale,
        _ => l10n.properties,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleOf(l10n)),
          actions: [
            IconButton(
              tooltip: l10n.saveSearch,
              onPressed: _saveCurrentSearch,
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
          ],
        ),
        body: BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, state) {
            return Column(
              children: [
                _LocationSearchField(
                  onResolved: (cityId, areaId) {
                    final current = state;
                    if (current is! PropertiesLoaded) return;
                    context.read<PropertiesCubit>().applyFilters(
                      current.query.copyWith(
                        cityId: () => cityId,
                        areaId: () => areaId,
                      ),
                    );
                  },
                ),
                _TypeCountStrip(
                  cubit: _typeCounts,
                  onSelect: (typeId) {
                    final current = state;
                    if (current is! PropertiesLoaded) return;
                    final already = current.query.propertyTypeIds.contains(
                      typeId,
                    );
                    context.read<PropertiesCubit>().applyFilters(
                      current.query.copyWith(
                        propertyTypeIds: already ? const [] : [typeId],
                      ),
                    );
                  },
                  selected: state is PropertiesLoaded
                      ? state.query.propertyTypeIds
                      : const [],
                ),
                _ResultsBar(state: state, onFilters: _openFilters),
                if (state case PropertiesLoaded(
                  :final query,
                ) when query.activeFilterCount > 0)
                  _ActiveFilterChips(query: query),
                Expanded(
                  child: switch (state) {
                    PropertiesInitial() ||
                    PropertiesLoading() => const _Loading(),
                    PropertiesError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () => context.read<PropertiesCubit>().refresh(),
                    ),
                    PropertiesLoaded() && final loaded =>
                      loaded.isEmpty
                          ? const _EmptyView()
                          : _PropertiesList(
                              loaded: loaded,
                              controller: _scroll,
                              onRefresh: _refresh,
                            ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The site's type-count strip ("Apartment · 2321"), backed by live totals.
/// Tapping a chip applies the real `filter[property_types][]` filter.
class _TypeCountStrip extends StatelessWidget {
  final TypeCountsCubit cubit;
  final ValueChanged<int> onSelect;
  final List<int> selected;

  const _TypeCountStrip({
    required this.cubit,
    required this.onSelect,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return BlocBuilder<TypeCountsCubit, List<TypeCount>>(
      bloc: cubit,
      builder: (context, counts) {
        if (counts.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            itemCount: counts.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = counts[i];
              final isOn = selected.contains(item.typeId);
              return Material(
                color: isOn
                    ? accent.withValues(alpha: 0.16)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelect(item.typeId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isOn ? accent : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.count(item.total),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isOn ? accent : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Free-text location search over the list (owner review: "missing search
/// engine ... properties screens"). Typed text is resolved against the LIVE
/// /lookup cities and areas, then applied as the real Spatie filter — never
/// as a fake client-side text match.
class _LocationSearchField extends StatefulWidget {
  final void Function(int? cityId, int? areaId) onResolved;

  const _LocationSearchField({required this.onResolved});

  @override
  State<_LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<_LocationSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String raw) async {
    final text = raw.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);
    if (text.isEmpty) {
      widget.onResolved(null, null);
      return;
    }

    setState(() => _working = true);
    final lookup = sl<LookupService>();
    int? cityId;
    int? areaId;
    try {
      for (final city in await lookup.cities()) {
        if (city.name.toLowerCase() == text) {
          cityId = int.tryParse(city.id);
          break;
        }
      }
      if (cityId == null) {
        for (final area in await lookup.areas()) {
          if (area.name.toLowerCase().contains(text)) {
            areaId = area.id;
            cityId = area.cityId;
            break;
          }
        }
      }
    } catch (_) {
      // Lookup is best-effort; the field simply reports no match.
    }
    if (!mounted) return;
    setState(() => _working = false);

    if (cityId == null && areaId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.noResults)));
      return;
    }
    widget.onResolved(cityId, areaId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 2),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: _submit,
        decoration: InputDecoration(
          hintText: l10n.searchPropertiesHint,
          prefixIcon: _working
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onResolved(null, null);
                    setState(() {});
                  },
                ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

/// Result count + filter button with active-count badge.
class _ResultsBar extends StatelessWidget {
  final PropertiesState state;
  final VoidCallback onFilters;

  const _ResultsBar({required this.state, required this.onFilters});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final loaded = state is PropertiesLoaded ? state as PropertiesLoaded : null;
    final total = loaded?.pageInfo?.total;
    final filterCount = loaded?.query.activeFilterCount ?? 0;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == null ? '' : l10n.resultsCount(Formatters.count(total)),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          // Manual badge (not Material Badge, which floods the framework
          // '!semantics.parentDataDirty' assertion and blanks the screen).
          Stack(
            clipBehavior: Clip.none,
            children: [
              OutlinedButton.icon(
                onPressed: onFilters,
                // Override the global theme's Size.fromHeight(54) (width=∞) so
                // the button hugs its content inside the Row/Stack.
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(l10n.filters),
              ),
              if (filterCount > 0)
                PositionedDirectional(
                  top: -4,
                  end: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentFor(Theme.of(context).brightness),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: TextStyle(
                        color: AppColors.onAccentFor(
                          Theme.of(context).brightness,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Removable chips for the applied filters (site's active-filter feedback).
class _ActiveFilterChips extends StatelessWidget {
  final PropertyQuery query;

  const _ActiveFilterChips({required this.query});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PropertiesCubit>();

    final chips = <(String, VoidCallback)>[
      if (query.propertyTypeIds.isNotEmpty)
        (
          '${l10n.propertyTypeLabel} (${query.propertyTypeIds.length})',
          () => cubit.applyFilters(query.copyWith(propertyTypeIds: const [])),
        ),
      if (query.cityId != null)
        (
          l10n.city,
          () => cubit.applyFilters(query.copyWith(cityId: () => null)),
        ),
      if (query.minBedrooms != null)
        (
          '${query.minBedrooms}+ ${l10n.beds}',
          () => cubit.applyFilters(query.copyWith(minBedrooms: () => null)),
        ),
      if (query.minBathrooms != null)
        (
          '${query.minBathrooms}+ ${l10n.baths}',
          () => cubit.applyFilters(query.copyWith(minBathrooms: () => null)),
        ),
      if (query.minPrice != null || query.maxPrice != null)
        (
          l10n.priceRangeSar,
          () => cubit.applyFilters(
            query.copyWith(minPrice: () => null, maxPrice: () => null),
          ),
        ),
      if (query.furnishingStatus != null)
        (
          l10n.furnishing,
          () =>
              cubit.applyFilters(query.copyWith(furnishingStatus: () => null)),
        ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) => InputChip(
          label: Text(chips[i].$1),
          onDeleted: chips[i].$2,
          deleteIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PropertiesList extends StatelessWidget {
  final PropertiesLoaded loaded;
  final ScrollController controller;
  final Future<void> Function() onRefresh;

  const _PropertiesList({
    required this.loaded,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: loaded.properties.length + (loaded.hasMore ? 1 : 0),
        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i >= loaded.properties.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.6,
                  ),
                ),
              ),
            );
          }
          final property = loaded.properties[i];
          return PropertyCard(
            showActions: true,
            property: property,
            onTap: () =>
                context.push(RoutePaths.propertyDetailPath(property.slug)),
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noResults,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

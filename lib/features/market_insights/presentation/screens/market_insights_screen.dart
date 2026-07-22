import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../core/widgets/dwelleo_choice_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/market_insight.dart';
import '../cubit/market_insight_cubit.dart';
import '../widgets/market_insight_charts.dart';

/// Market Insights — dwelleo.sa/en/market-insights, rebuilt for mobile.
///
/// Three tabs over the LIVE `/market-insights/rental/*` endpoints. Chart
/// titles and descriptions are rendered from the API payload (they arrive
/// localized via `Accept-Language`), so they always match the website's copy
/// and never drift out of sync with an ARB file.
class MarketInsightsScreen extends StatefulWidget {
  const MarketInsightsScreen({super.key});

  @override
  State<MarketInsightsScreen> createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  late final MarketInsightCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MarketInsightCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openFilters(MarketInsightState state) async {
    final result = await showModalBottomSheet<MarketInsightFilters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _FiltersSheet(lookups: state.lookups, current: state.filters),
    );
    if (result != null) await _cubit.applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: BlocBuilder<MarketInsightCubit, MarketInsightState>(
        bloc: _cubit,
        builder: (context, state) {
          final series = state.current;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _cubit.retry,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                // ── Eyebrow + title, matching the site's hero copy ────────
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.marketDataDriven,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                    children: [
                      TextSpan(text: '${l10n.marketInsightsLead} '),
                      TextSpan(
                        text: l10n.marketInsightsAccent,
                        style: TextStyle(color: accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.marketInsightsSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Filters ──────────────────────────────────────────────
                // NOTE: the app theme gives buttons `Size.fromHeight(54)`,
                // i.e. an INFINITE minimum width. A themed button placed as a
                // bare Row child therefore forces an unbounded width and
                // throws "BoxConstraints forces an infinite width". Both
                // controls are wrapped so their width is bounded.
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _openFilters(state),
                        icon: const Icon(Icons.tune_rounded, size: 17),
                        label: Text(
                          state.filters.isEmpty
                              ? l10n.filters
                              : '${l10n.filters} (${state.filters.activeCount})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!state.filters.isEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () =>
                              _cubit.applyFilters(const MarketInsightFilters()),
                          child: Text(
                            l10n.reset,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Chart tabs ───────────────────────────────────────────
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final chart in MarketInsightChart.values)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: DwelleoChoiceChip(
                            label: _tabLabel(l10n, chart),
                            selected: state.chart == chart,
                            onTap: () => _cubit.selectChart(chart),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Body ─────────────────────────────────────────────────
                if (state.failure != null && series == null)
                  _ErrorView(
                    message: state.failure!.localized(l10n),
                    onRetry: _cubit.retry,
                    l10n: l10n,
                  )
                else if (series == null)
                  const _ChartSkeleton()
                else
                  _ChartBody(series: series, loading: state.loading),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _tabLabel(AppLocalizations l10n, MarketInsightChart chart) =>
      switch (chart) {
        MarketInsightChart.topCitiesCommercialGrowth => l10n.marketTabTopCities,
        MarketInsightChart.highestCommercialGrowthCities =>
          l10n.marketTabHighestGrowth,
        MarketInsightChart.commercialUnitsGrowth => l10n.marketTabRegions,
      };
}

class _ChartBody extends StatelessWidget {
  final MarketInsightSeries series;
  final bool loading;

  const _ChartBody({required this.series, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (series.points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            l10n.noResults,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: loading ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + description come from the API, already localized.
            if (series.name.isNotEmpty)
              Text(
                series.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            if (series.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                series.description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            MarketInsightTotals(series: series),
            const SizedBox(height: 18),
            switch (series.chart) {
              MarketInsightChart.topCitiesCommercialGrowth => DumbbellChart(
                series: series,
              ),
              MarketInsightChart.highestCommercialGrowthCities =>
                RankedGrowthChart(series: series),
              MarketInsightChart.commercialUnitsGrowth => RegionGrowthChart(
                series: series,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 38,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Region / city / unit-type / purpose pickers, populated from `/lookups`.
class _FiltersSheet extends StatefulWidget {
  final MarketInsightLookups lookups;
  final MarketInsightFilters current;

  const _FiltersSheet({required this.lookups, required this.current});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late MarketInsightFilters _draft = widget.current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lookups = widget.lookups;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.filters,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _Picker(
                label: l10n.marketRegion,
                value: _draft.region,
                options: lookups.regions,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(region: () => v)),
              ),
              _Picker(
                label: l10n.city,
                value: _draft.city,
                options: lookups.cities,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(city: () => v)),
              ),
              _Picker(
                label: l10n.marketUnitType,
                value: _draft.unitType,
                options: [for (final o in lookups.unitTypes) o.value],
                labels: {for (final o in lookups.unitTypes) o.value: o.label},
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(unitType: () => v)),
              ),
              _Picker(
                label: l10n.marketUnitPurpose,
                value: _draft.unitPurpose,
                options: [for (final o in lookups.unitPurposes) o.value],
                labels: {
                  for (final o in lookups.unitPurposes) o.value: o.label,
                },
                onChanged: (v) => setState(
                  () => _draft = _draft.copyWith(unitPurpose: () => v),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _draft = const MarketInsightFilters()),
                      child: Text(l10n.reset),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _draft),
                      child: Text(l10n.apply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final Map<String, String>? labels;
  final ValueChanged<String?> onChanged;

  const _Picker({
    required this.label,
    required this.value,
    required this.options,
    this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(AppLocalizations.of(context).all),
          ),
          for (final option in options)
            DropdownMenuItem<String?>(
              value: option,
              child: Text(
                labels?[option] ?? option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

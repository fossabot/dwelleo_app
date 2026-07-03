import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/city_market_stat.dart';
import '../cubit/home_state.dart';
import '../cubit/market_stats_cubit.dart';
import 'labeled_toggle.dart';
import 'section_error_box.dart';

/// "City intelligence." — the ranked table from dwelleo.sa (replaces the
/// earlier bar chart): LISTING Buy|Rent and PROPERTY TYPE Apartment|Villa
/// segmented capsules, ranked rows with the market leader in lime,
/// SAR/m² for buy and SAR/mo for rent.
class MarketTableSection extends StatelessWidget {
  const MarketTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return BlocBuilder<MarketStatsCubit, MarketStatsState>(
      builder: (context, state) {
        final cubit = context.read<MarketStatsCubit>();
        final count = switch (state.stats) {
          SectionLoaded<List<CityMarketStat>>(:final data) => data.length,
          _ => null,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 26, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow(text: l10n.marketDataTag),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: '${l10n.cityIntelligenceLead} ',
                      children: [
                        TextSpan(
                          text: l10n.cityIntelligenceAccent,
                          style: TextStyle(color: accent),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count == null
                        ? l10n.cityIntelligenceSubtitle
                        : l10n.cityIntelligenceSubtitleCount('$count'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 6),
              child: LabeledToggle(
                label: l10n.listingLabel.toUpperCase(),
                first: l10n.buy,
                second: l10n.rent,
                firstSelected: state.query.transaction == MarketTransaction.buy,
                onFirst: () => cubit.setTransaction(MarketTransaction.buy),
                onSecond: () => cubit.setTransaction(MarketTransaction.rent),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
              child: LabeledToggle(
                label: l10n.propertyTypeLabel.toUpperCase(),
                first: l10n.apartment,
                second: l10n.villa,
                firstSelected:
                    state.query.unitTypeId == MarketUnitTypes.apartment,
                onFirst: () => cubit.setUnitType(MarketUnitTypes.apartment),
                onSecond: () => cubit.setUnitType(MarketUnitTypes.villa),
              ),
            ),
            switch (state.stats) {
              SectionLoading<List<CityMarketStat>>() => Container(
                height: 320,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              SectionError<List<CityMarketStat>>(:final failure) =>
                SectionErrorBox(
                  message: failure.localized(l10n),
                  onRetry: () => cubit.load(),
                ),
              SectionLoaded<List<CityMarketStat>>(:final data) => _TableCard(
                stats: data,
                query: state.query,
              ),
            },
          ],
        );
      },
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Breathes like the AI Search button — same brand pulse.
        PulseGlow(
          glowColor: AppColors.primary,
          strength: 0.45,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.accentFor(Theme.of(context).brightness),
          ),
        ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  final List<CityMarketStat> stats;
  final MarketQuery query;

  const _TableCard({required this.stats, required this.query});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rent = query.transaction == MarketTransaction.rent;
    final unitLabel = rent ? l10n.sarPerMonth : l10n.sarPerSqm;
    final typeLabel = query.unitTypeId == MarketUnitTypes.villa
        ? l10n.villa
        : l10n.apartment;
    final listingLabel = rent ? l10n.toRent : l10n.toBuy;

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.avgPriceTitle(typeLabel.toLowerCase(), listingLabel),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.accentLight, label: unitLabel),
              _LegendDot(color: AppColors.primary, label: l10n.marketLeader),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < stats.length; i++) ...[
            _Row(
              rank: i + 1,
              leader: i == 0,
              stat: stats[i],
              unitLabel: unitLabel,
            ),
            if (i != stats.length - 1)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sortedByPriceDesc,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                l10n.sourceDwelleoIndex,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final int rank;
  final bool leader;
  final CityMarketStat stat;
  final String unitLabel;

  const _Row({
    required this.rank,
    required this.leader,
    required this.stat,
    required this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final rankColor = leader
        ? AppColors.accentFor(brightness)
        : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: rankColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              stat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              text: Formatters.statValue(stat.value),
              children: [
                TextSpan(
                  text: ' $unitLabel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

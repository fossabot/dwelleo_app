import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/estimate_models.dart';

/// The site's result page, mobile-sized: headline band, low/high rail,
/// confidence dots, rent + yield tiles, "Why this estimate?" and the
/// Taqeem disclaimer. Numbers animate up from zero (900ms easeOutCubic,
/// the app's house motion).
class EstimateResultView extends StatelessWidget {
  final EstimateInput input;
  final EstimateResult result;
  final VoidCallback onRestart;

  const EstimateResultView({
    super.key,
    required this.input,
    required this.result,
    required this.onRestart,
  });

  static const _duration = Duration(milliseconds: 900);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final renting = input.purpose == EstimatePurpose.rent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    l10n.estimateReady,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: Text(l10n.estimateRestart),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          renting ? l10n.estimateRentTitle : l10n.estimateResultTitle,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(label: '${input.districtName}'),
            _Tag(label: '${input.cityName}'),
            _Tag(label: Formatters.area(input.areaSqm)),
          ],
        ),
        const SizedBox(height: 16),

        // ── Headline band ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                renting ? l10n.estimateAnnualRent : l10n.estimatedPrice,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: _duration,
                curve: _curve,
                builder: (context, t, _) => FittedBox(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Formatters.priceValue((result.mid * t).round()),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.sar,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (result.pricePerSqm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${Formatters.priceValue(result.pricePerSqm?.round())} '
                  '${l10n.sarPerSqm}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RangeEnd(
                      label: l10n.estimateLowRange,
                      value: result.low,
                    ),
                  ),
                  Expanded(
                    child: _RangeEnd(
                      label: l10n.estimateHighRange,
                      value: result.high,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // The mid point sits inside the band, like the site's rail.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: _duration,
                curve: _curve,
                child: const SizedBox.shrink(),
                builder: (context, t, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: scheme.surfaceContainerHighest,
                      ),
                      FractionallySizedBox(
                        widthFactor: (0.62 * t).clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          margin: const EdgeInsetsDirectional.only(start: 24),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ConfidenceDots(score: result.confidence),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Rent + yield tiles (only when the market publishes them) ─────
        if (result.annualRent != null)
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.estimateAnnualRent,
                  value:
                      '${Formatters.priceValue(result.annualRent?.round())} '
                      '${l10n.sar}',
                ),
              ),
              if (result.netYield != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: l10n.estimateNetYield,
                    value: '${(result.netYield! * 100).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 16),

        // ── Why this estimate? ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.estimateWhy,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              for (final factor in result.factors)
                _FactorRow(factor: factor, l10n: l10n),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Disclaimer (verbatim intent from the site) ───────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.estimateDisclaimer,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // NOTE: the Sales Agent is a bottom-tab BRANCH route. Using
            // push() here duplicates the shell's page key and trips
            // Navigator's `!keyReservation.contains(key)` assertion (red
            // screen). go() switches the tab, which is the intent anyway.
            onPressed: () => context.go(RoutePaths.aiSalesAgent),
            icon: const Icon(Icons.support_agent_rounded, size: 19),
            label: Text(l10n.estimateTalkToAgent),
          ),
        ),
      ],
    );
  }
}

class _RangeEnd extends StatelessWidget {
  final String label;
  final num value;
  final bool alignEnd;

  const _RangeEnd({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 3),
        Text(
          // Whole riyals — a price band with decimals reads like a bug.
          Formatters.priceValue(value.round()),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ConfidenceDots extends StatelessWidget {
  final int score;

  const _ConfidenceDots({required this.score});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.estimateConfidence,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < score
                        ? accent
                        : scheme.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          score >= 5 ? l10n.estimateHighAccuracy : l10n.estimateAddDetails,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: score >= 5 ? accent : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final EstimateFactor factor;
  final AppLocalizations l10n;

  const _FactorRow({required this.factor, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = factor.positive;
    final color = positive
        ? AppColors.accentFor(Theme.of(context).brightness)
        : Theme.of(context).colorScheme.error;
    final label = switch (factor.key) {
      EstimateFactorKey.districtPrice => l10n.estimateFactorDistrict,
      EstimateFactorKey.areaAndRooms => l10n.estimateFactorArea,
      EstimateFactorKey.buildingAge => l10n.estimateFactorAge,
      EstimateFactorKey.amenities => l10n.estimateFactorAmenities,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
            ),
          ),
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            positive ? l10n.estimatePositive : l10n.estimateNegative,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/market_insight.dart';

/// The three chart forms dwelleo.sa/en/market-insights renders, rebuilt as
/// native Flutter with no chart dependency — CustomPaint-free, so they stay
/// cheap, themable and RTL-correct.
///
/// House motion: 900ms easeOutCubic, matching the rest of the app.
const Duration _kAnim = Duration(milliseconds: 900);
const Curve _kCurve = Curves.easeOutCubic;

/// Base-year → latest-year totals with the overall growth pill. The site
/// prints this above every chart (e.g. 164.69 → 228.77, OVERALL GROWTH +39%).
class MarketInsightTotals extends StatelessWidget {
  final MarketInsightSeries series;

  const MarketInsightTotals({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final growth = series.overallGrowth;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalTile(
                dotColor: AppColors.accent,
                label: series.baseYear == null
                    ? l10n.marketBaseYear
                    : '${series.baseYear}',
                value: Formatters.statValue(series.baseTotal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TotalTile(
                dotColor: accent,
                label: series.latestYear == null
                    ? l10n.marketLatestYear
                    : '${series.latestYear}',
                value: Formatters.statValue(series.latestTotal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.marketOverallGrowth,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: growth),
                duration: _kAnim,
                curve: _kCurve,
                builder: (context, value, _) => Text(
                  _percent(value),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;

  const _TotalTile({
    required this.dotColor,
    required this.label,
    required this.value,
  });

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

/// CHART 1 — dumbbell: a base dot and a latest dot joined by a gradient
/// segment, one row per city. Longer segment = faster growth, which is the
/// whole point of the site's "Top 15 Cities" view.
class DumbbellChart extends StatelessWidget {
  final MarketInsightSeries series;

  const DumbbellChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    // Scale across BOTH years so the two dots share one axis.
    final maxValue = series.points.fold<double>(0, (m, p) {
      final hi = p.base > p.latest ? p.base : p.latest;
      return hi.toDouble() > m ? hi.toDouble() : m;
    });

    return Column(
      children: [
        for (final point in series.points)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 86,
                  child: Text(
                    point.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: _kAnim,
                    curve: _kCurve,
                    builder: (context, t, _) => _DumbbellTrack(
                      start: maxValue == 0 ? 0 : point.base / maxValue,
                      end: maxValue == 0 ? 0 : point.latest / maxValue,
                      progress: t,
                      accent: accent,
                      track: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 46,
                  child: Text(
                    Formatters.statValue(point.latest),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _GrowthPill(growth: point.growth),
              ],
            ),
          ),
        const SizedBox(height: 8),
        _Legend(
          items: [
            (
              AppColors.accent,
              series.baseYear == null ? '—' : '${series.baseYear}',
            ),
            (accent, series.latestYear == null ? '—' : '${series.latestYear}'),
          ],
        ),
      ],
    );
  }
}

class _DumbbellTrack extends StatelessWidget {
  final double start;
  final double end;
  final double progress;
  final Color accent;
  final Color track;

  const _DumbbellTrack({
    required this.start,
    required this.end,
    required this.progress,
    required this.accent,
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final lo = (start < end ? start : end).clamp(0.0, 1.0);
        final hi = (start < end ? end : start).clamp(0.0, 1.0);
        final animatedHi = lo + (hi - lo) * progress;

        return SizedBox(
          height: 14,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              PositionedDirectional(
                start: lo * width,
                child: Container(
                  height: 4,
                  width: ((animatedHi - lo) * width).clamp(0.0, width),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, accent],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              PositionedDirectional(
                start: (start * width - 5).clamp(0.0, width - 10),
                child: _Dot(color: AppColors.accent),
              ),
              PositionedDirectional(
                start: (lo * width + (animatedHi - lo) * width - 5).clamp(
                  0.0,
                  width - 10,
                ),
                child: _Dot(color: accent),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
      ],
    ),
  );
}

/// CHART 2 — ranked gradient bars with a growth % and a ×multiplier chip.
/// Bar colour follows the site's growth tiers.
class RankedGrowthChart extends StatelessWidget {
  final MarketInsightSeries series;

  const RankedGrowthChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxGrowth = series.maxGrowth;
    final ranked = [...series.points]
      ..sort((a, b) => b.growth.compareTo(a.growth));

    return Column(
      children: [
        for (var i = 0; i < ranked.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 84,
                  child: Text(
                    ranked[i].label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GrowthBar(
                    growth: ranked[i].growth,
                    maxGrowth: maxGrowth,
                  ),
                ),
                const SizedBox(width: 8),
                _MultiplierChip(multiplier: ranked[i].multiplier),
              ],
            ),
          ),
        const SizedBox(height: 10),
        const _TierLegend(),
      ],
    );
  }
}

class _GrowthBar extends StatelessWidget {
  final double growth;
  final double maxGrowth;

  const _GrowthBar({required this.growth, required this.maxGrowth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tier = _tierFor(growth);
    final factor = maxGrowth <= 0 ? 0.0 : (growth / maxGrowth).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: factor),
      duration: _kAnim,
      curve: _kCurve,
      builder: (context, value, _) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.02, 1.0),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tier.withValues(alpha: 0.55), tier],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          PositionedDirectional(
            start: 10,
            child: Text(
              _percent(growth),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiplierChip extends StatelessWidget {
  final double multiplier;

  const _MultiplierChip({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '×${multiplier.toStringAsFixed(1)}',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// CHART 3 — one card per region: value, relative bar, base → latest and the
/// growth badge.
class RegionGrowthChart extends StatelessWidget {
  final MarketInsightSeries series;

  const RegionGrowthChart({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final ranked = [...series.points]
      ..sort((a, b) => b.latest.compareTo(a.latest));
    final maxLatest = series.maxLatest.toDouble();

    return Column(
      children: [
        for (var i = 0; i < ranked.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RegionCard(point: ranked[i], maxValue: maxLatest),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < ranked.length
                      ? _RegionCard(point: ranked[i + 1], maxValue: maxLatest)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const _TierLegend(),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  final MarketInsightPoint point;
  final double maxValue;

  const _RegionCard({required this.point, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tier = _tierFor(point.growth);
    final factor = maxValue <= 0
        ? 0.0
        : (point.latest / maxValue).clamp(0.0, 1.0);

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
            point.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  child: Text(
                    Formatters.statValue(point.latest),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: tier,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.marketUnits,
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: factor),
            duration: _kAnim,
            curve: _kCurve,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(tier),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.statValue(point.base)} → '
                  '${Formatters.statValue(point.latest)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              _GrowthPill(growth: point.growth),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthPill extends StatelessWidget {
  final double growth;

  const _GrowthPill({required this.growth});

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(growth);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: tier.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _percent(growth),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: tier,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(Color, String)> items;

  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }
}

/// The site's growth-tier legend, same thresholds as its colour ramp.
class _TierLegend extends StatelessWidget {
  const _TierLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Legend(
      items: [
        (_tier50, l10n.marketTierHigh),
        (_tier25, l10n.marketTierMid),
        (_tier10, l10n.marketTierLow),
        (_tierFlat, l10n.marketTierFlat),
      ],
    );
  }
}

// Tier ramp lifted from the website's own legend (50%+ / 25%+ / 10%+ / <10%).
const Color _tier50 = Color(0xFFD1F145);
const Color _tier25 = Color(0xFF4ECDC4);
const Color _tier10 = Color(0xFFF5C542);
const Color _tierFlat = Color(0xFFE8703A);

Color _tierFor(double growth) {
  if (growth >= 0.50) return _tier50;
  if (growth >= 0.25) return _tier25;
  if (growth >= 0.10) return _tier10;
  return _tierFlat;
}

String _percent(double value) {
  final pct = (value * 100).round();
  return '${pct >= 0 ? '+' : ''}$pct%';
}

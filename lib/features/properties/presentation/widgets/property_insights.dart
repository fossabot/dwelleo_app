import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'property_card.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/usecases/search_properties.dart';

const _kAnim = Duration(milliseconds: 900);
const _kCurve = Curves.easeOutCubic;

/// dwelleo.sa's AI insight system on the property page — Price Prediction,
/// Investment Score (with the API's OWN bilingual reasoning) and Lifestyle
/// Score — rendered as modern animated Flutter, 100% from the VERIFIED
/// public payload. Whole section disappears when the API omits the data.
class PropertyInsightsSection extends StatelessWidget {
  final Property property;

  const PropertyInsightsSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final prediction = property.pricePrediction;
    final investment = property.investmentScores;
    final lifestyle = property.lifestyleScore;
    if (prediction == null && investment == null && lifestyle == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The API only runs its full model on SOME listings: rentals in
        // particular come back as {min: null, mid: null, max: null,
        // predicted: 34863.99} with no scores and no reasons (verified live
        // 2026-07-21). A bare figure with no range and no explanation is
        // worse than no card — on a 25,000/mo listing "predicted 34,863.99"
        // reads as a bug or, worse, as advice. Show the card only when it
        // can actually explain itself.
        if (prediction != null && prediction.isPresentable) ...[
          _PricePredictionCard(property: property, prediction: prediction),
          const SizedBox(height: 14),
        ],
        if (investment != null) ...[
          _InvestmentCard(scores: investment),
          const SizedBox(height: 14),
        ],
        if (lifestyle != null) ...[
          _LifestyleCard(score: lifestyle),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ shared

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget child;
  final bool highlighted;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? accent.withValues(alpha: 0.55)
              : scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Animated horizontal metric bar (label · fill · value).
class _MetricBar extends StatelessWidget {
  final String label;
  final double value; // 0–100
  final Color color;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
            duration: _kAnim,
            curve: _kCurve,
            builder: (context, t, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t,
                minHeight: 6,
                backgroundColor: scheme.outlineVariant.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated score ring (the site's 0–100 gauge).
class _ScoreRing extends StatelessWidget {
  final double score; // 0–100
  final double size;
  final Color color;
  final String caption;

  const _ScoreRing({
    required this.score,
    required this.size,
    required this.color,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // t runs 0→1; the arc sweeps to score/100 while the NUMBER counts up to
    // the real score. (Previous version multiplied score×arc-fraction and
    // rested at the wrong number — e.g. 61 rendered as 37. Owner-caught bug.)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _kAnim,
      curve: _kCurve,
      builder: (context, t, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: _RingPainter(
                progress: (score / 100).clamp(0.0, 1.0) * t,
                color: color,
                track: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (score * t).round().toString(),
                  style: TextStyle(
                    fontSize: size * 0.26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: size * 0.085,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2 + 1);
    final paintTrack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final paintArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(inset, 0, math.pi * 2, false, paintTrack);
    canvas.drawArc(
      inset,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      paintArc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Client-side presentation tier for a 0–100 score (labels only — the
/// numbers themselves come straight from the API).
(String, Color) _tierFor(double score, AppLocalizations l10n) {
  if (score >= 80) return (l10n.tierExcellent, const Color(0xFF3DBE5B));
  if (score >= 65) return (l10n.tierGood, const Color(0xFF9BC53D));
  if (score >= 50) return (l10n.tierFair, const Color(0xFFE0A93E));
  return (l10n.tierWeak, const Color(0xFFD9634C));
}

bool _isArabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

// -------------------------------------------------------- price prediction

class _PricePredictionCard extends StatelessWidget {
  final Property property;
  final PricePrediction prediction;

  const _PricePredictionCard({
    required this.property,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final min = prediction.min?.toDouble();
    final max = prediction.max?.toDouble();
    final predicted = prediction.predicted?.toDouble();
    final price = property.price?.toDouble();

    // The site's assessment sentence comes from the API's own bilingual
    // value_vs_market reason — never invented client-side.
    final assessment = property.investmentScores
        ?.reason('value_vs_market')
        ?.forArabic(_isArabic(context));

    return _InsightCard(
      icon: Icons.trending_up_rounded,
      title: l10n.insightsAiPricePrediction,
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (predicted != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.price(predicted),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    l10n.insightsPredictedPrice,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          // No range from the backend? Give the predicted price context by
          // comparing it to the asking price — pure arithmetic, no invented
          // benchmark label. This is what un-hides the card on listings like
          // the Al-Mahdiyah villa (predicted 1.9M, no range, no scores).
          if ((min == null || max == null) &&
              predicted != null &&
              price != null &&
              predicted > 0) ...[
            const SizedBox(height: 10),
            _AskingComparison(asking: price, predicted: predicted),
          ],
          if (min != null && max != null && max > min) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: _kAnim,
              curve: _kCurve,
              builder: (context, t, _) => _RangeBar(
                min: min,
                max: max,
                predicted: predicted,
                price: price,
                reveal: t,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.compactK(min),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.insightsRange,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  Formatters.compactK(max),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (assessment != null && assessment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              assessment,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gradient range track with predicted (accent ▲) and asking-price (dot)
/// markers, revealed left→right (RTL-mirrored automatically by Directionality
/// since it's built with FractionallySizedBox alignment).
class _RangeBar extends StatelessWidget {
  final double min;
  final double max;
  final double? predicted;
  final double? price;
  final double reveal;

  const _RangeBar({
    required this.min,
    required this.max,
    required this.predicted,
    required this.price,
    required this.reveal,
  });

  double _pos(double v) => ((v - min) / (max - min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return SizedBox(
      height: 26,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: reveal,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3DBE5B),
                            Color(0xFF9BC53D),
                            Color(0xFFE0A93E),
                            Color(0xFFD9634C),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (predicted != null)
                PositionedDirectional(
                  start: (w - 12) * _pos(predicted!) * reveal,
                  child: Icon(
                    Icons.arrow_drop_up_rounded,
                    size: 22,
                    color: accent,
                  ),
                ),
              if (price != null)
                PositionedDirectional(
                  start: (w - 10) * _pos(price!) * reveal,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------- investment score

class _InvestmentCard extends StatelessWidget {
  final InvestmentScores scores;

  const _InvestmentCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final arabic = _isArabic(context);
    final (tierLabel, tierColor) = _tierFor(scores.total, l10n);

    final factors = <(String, double)>[
      (l10n.factorValue, scores.valueVsMarket),
      (l10n.factorIncome, scores.incomeReturn),
      (l10n.factorLocation, scores.locationQuality),
      (l10n.factorSaturation, scores.marketSaturation),
    ];

    return _InsightCard(
      icon: Icons.speed_rounded,
      title: l10n.insightsInvestmentScore,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          tierLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tierColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreRing(
                score: scores.total,
                size: 86,
                color: tierColor,
                caption: '/100',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (final (label, value) in factors)
                      _MetricBar(
                        label: label,
                        value: value,
                        color: _tierFor(value, l10n).$2,
                      ),
                  ],
                ),
              ),
            ],
          ),
          // The API's OWN bilingual explanations — shown verbatim.
          for (final reason in scores.reasons)
            if (reason.forArabic(arabic).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 12,
                        color: AppColors.accentFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason.forArabic(arabic),
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
          if (scores.benchmarkLevel != null) ...[
            const SizedBox(height: 8),
            Text(
              scores.benchmarkLevel!,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.4,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------------------------------------- lifestyle score

class _LifestyleCard extends StatelessWidget {
  final LifestyleScore score;

  const _LifestyleCard({required this.score});

  static const _order = [
    'walkability',
    'busy',
    'wellness',
    'noise',
    'bikeability',
    'transport',
  ];

  static const _colors = <String, Color>{
    'walkability': Color(0xFF2FBF9B),
    'busy': Color(0xFF9BC53D),
    'wellness': Color(0xFF9B7FD4),
    'noise': Color(0xFFE0A93E),
    'bikeability': Color(0xFF4FB6E0),
    'transport': Color(0xFFE06CA8),
  };

  String _label(String key, AppLocalizations l10n) => switch (key) {
    'walkability' => l10n.lifeWalkability,
    'busy' => l10n.lifeActivity,
    'wellness' => l10n.lifeWellness,
    'noise' => l10n.lifeNoise,
    'bikeability' => l10n.lifeBike,
    'transport' => l10n.lifeTransport,
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (_, tierColor) = _tierFor(score.total, l10n);

    final keys = [
      ..._order.where(score.metrics.containsKey),
      ...score.metrics.keys.where((k) => !_order.contains(k)),
    ];

    return _InsightCard(
      icon: Icons.eco_rounded,
      title: l10n.insightsLifestyleScore,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScoreRing(
            score: score.total,
            size: 86,
            color: tierColor,
            caption: '/100',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final key in keys)
                  _MetricBar(
                    label: _label(key, l10n),
                    value: score.metrics[key]!,
                    color: _colors[key] ?? tierColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------ similar properties

/// "Similar Properties" — live results from the VERIFIED search params
/// (same city + type, current listing excluded).
class SimilarPropertiesSection extends StatefulWidget {
  final Property property;

  const SimilarPropertiesSection({super.key, required this.property});

  @override
  State<SimilarPropertiesSection> createState() =>
      _SimilarPropertiesSectionState();
}

class _SimilarPropertiesSectionState extends State<SimilarPropertiesSection> {
  List<Property>? _similar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = widget.property;
    final cityId = p.city?.id;
    final result = await sl<SearchProperties>()(
      PropertyQuery(
        listingType: p.listingType?.key,
        cityId: (cityId != null && cityId > 0) ? cityId : null,
        propertyTypeIds: [if (p.propertyType != null) p.propertyType!.id],
      ),
    );
    if (!mounted) return;
    result.when(
      success: (page) => setState(() {
        _similar = page.properties
            .where((x) => x.id != p.id)
            .take(6)
            .toList(growable: false);
      }),
      error: (_) => setState(() => _similar = const []),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final similar = _similar;
    if (similar != null && similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.insightsSimilar,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: similar == null
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: similar.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: 240,
                    // Same image-first overlay card as Home, so Similar
                    // Properties reads as one family with the rest of the app.
                    child: PropertyCard(
                      property: similar[index],
                      height: 200,
                      onTap: () => context.pushReplacement(
                        RoutePaths.propertyDetailPath(similar[index].slug),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Factual "asking vs predicted" line for listings that have a predicted
/// price but no min–max range. States the arithmetic difference only; the
/// 5-tier "MARKET PRICE" badge needs `investment_scores.benchmark_level`,
/// which the public API does NOT return for these listings, so it is not
/// fabricated here.
class _AskingComparison extends StatelessWidget {
  final double asking;
  final double predicted;

  const _AskingComparison({required this.asking, required this.predicted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final diff = (asking - predicted) / predicted;
    final pct = (diff.abs() * 100).round();

    // Direction only — below (green), roughly level (accent), above (amber).
    final (label, color) = pct < 2
        ? (
            l10n.insightsAskingInline,
            AppColors.accentFor(Theme.of(context).brightness),
          )
        : diff > 0
        ? (l10n.insightsAskingAbove(pct), const Color(0xFFE0A93E))
        : (l10n.insightsAskingBelow(pct), const Color(0xFF4CAF50));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            diff > 0
                ? Icons.trending_up_rounded
                : diff < 0
                ? Icons.trending_down_rounded
                : Icons.trending_flat_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

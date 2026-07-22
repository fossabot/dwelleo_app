import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/api_result.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import '../../domain/usecases/get_property_detail.dart';
import '../cubit/compare_cubit.dart';

/// Side-by-side compare of the two tray properties — dwelleo.sa's Compare,
/// mobile-sized.
///
/// The tray can be filled from a LIST card, whose payload carries no AI
/// scores (those only ship on `/properties/{slug}`). So this screen upgrades
/// each entry to its full detail on open; rows where NEITHER side has a
/// value are dropped rather than rendered as a wall of dashes.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final CompareCubit _tray = sl<CompareCubit>();

  /// slug -> fully hydrated property.
  final Map<String, Property> _detailed = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final items = _tray.state;
    if (items.isEmpty) return;
    setState(() => _loading = true);

    final getDetail = sl<GetPropertyDetail>();
    for (final item in items) {
      if (_detailed.containsKey(item.slug)) continue;
      final result = await getDetail(item.slug);
      if (!mounted) return;
      if (result case ApiSuccess(:final data)) _detailed[item.slug] = data;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Property _best(Property tray) => _detailed[tray.slug] ?? tray;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compareTitle),
        actions: [
          IconButton(
            tooltip: l10n.reset,
            onPressed: () {
              _tray.clear();
              _detailed.clear();
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: BlocBuilder<CompareCubit, List<Property>>(
        bloc: _tray,
        builder: (context, tray) {
          if (tray.length < 2) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  l10n.compareEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final a = _best(tray[0]);
          final b = _best(tray[1]);

          String? money(num? v) => v == null ? null : Formatters.priceValue(v);
          String? plain(Object? v) => v?.toString();
          String? score(num? v) => v == null ? null : '${v.round()}';

          // (label, valueA, valueB) — nulls mean "not published for this
          // listing"; a row renders only when at least one side has data.
          final rows = <(String, String?, String?)>[
            (l10n.price, money(a.price), money(b.price)),
            (
              l10n.type,
              plain(a.propertyType?.name),
              plain(b.propertyType?.name),
            ),
            (l10n.city, plain(a.cityName), plain(b.cityName)),
            (l10n.beds, plain(a.bedrooms), plain(b.bedrooms)),
            (l10n.baths, plain(a.bathrooms), plain(b.bathrooms)),
            (
              l10n.area,
              a.areaSqm == null ? null : Formatters.area(a.areaSqm),
              b.areaSqm == null ? null : Formatters.area(b.areaSqm),
            ),
            (
              l10n.furnishing,
              plain(a.furnishingStatus),
              plain(b.furnishingStatus),
            ),
            (
              l10n.insightsInvestmentScore,
              score(a.investmentScores?.total),
              score(b.investmentScores?.total),
            ),
            (
              l10n.insightsLifestyleScore,
              score(a.lifestyleScore?.total),
              score(b.lifestyleScore?.total),
            ),
          ].where((r) => r.$2 != null || r.$3 != null).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(child: _Header(property: a)),
                  const SizedBox(width: 10),
                  Expanded(child: _Header(property: b)),
                ],
              ),
              const SizedBox(height: 14),
              for (final (label, va, vb) in rows) _Row(label, va, vb),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Property property;

  const _Header({required this.property});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = property.coverImage?.displayThumb;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RoutePaths.propertyDetailPath(property.slug)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: thumb == null
                  ? ColoredBox(color: scheme.surfaceContainerHighest)
                  : CachedNetworkImage(
                      imageUrl: DwelleoImages.optimized(thumb, width: 640),
                      httpHeaders: DwelleoImages.headers,
                      fit: BoxFit.cover,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                property.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? a;
  final String? b;

  const _Row(this.label, this.a, this.b);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _Value(a)),
              Container(width: 1, height: 18, color: scheme.outlineVariant),
              Expanded(child: _Value(b)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final String? value;

  const _Value(this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      value ?? '—',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: value == null ? scheme.onSurfaceVariant : scheme.onSurface,
      ),
    );
  }
}

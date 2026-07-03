import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/city_market_stat.dart';
import '../cubit/home_state.dart';
import '../cubit/market_map_cubit.dart';
import 'labeled_toggle.dart';
import 'map_price_marker.dart';
import 'section_error_box.dart';

/// dwelleo.sa's "Interactive Market map": a dark Google map of Saudi cities
/// with lime price bubbles; tapping a city drops into its districts
/// (`/market/districts`), with Apartment/Villa and buy/Rent toggles.
class MarketMapSection extends StatefulWidget {
  const MarketMapSection({super.key});

  @override
  State<MarketMapSection> createState() => _MarketMapSectionState();
}

class _MarketMapSectionState extends State<MarketMapSection> {
  static const CameraPosition _saudiView = CameraPosition(
    target: LatLng(24.2, 45.1),
    zoom: 4.6,
  );

  GoogleMapController? _map;
  Set<Marker> _markers = const {};
  MapType _mapType = MapType.normal;

  /// Identity of the data the current markers were built from — avoids
  /// rebuilding bitmaps on unrelated rebuilds.
  Object? _markerSource;
  Brightness? _markerBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme flip (light/dark) → regenerate the price bubbles in the new accent
    // (purple in light, lime in dark), matching dwelleo.sa.
    _rebuildMarkers(context.read<MarketMapCubit>().state);
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _rebuildMarkers(MarketMapState state) async {
    final focused = state.focusedCity;
    final source = focused == null ? state.cities : state.districts;
    final b = Theme.of(context).brightness;
    if (identical(_markerSource, source) && _markerBrightness == b) return;
    _markerSource = source;
    _markerBrightness = b;

    final body = AppColors.accentFor(b);
    final onBody = AppColors.onAccentFor(b);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final markers = <Marker>{};

    // Heatmap semantics (like the website's legend): pricier = bigger
    // and brighter. Intensity is normalized within the visible set.
    double intensityOf(num value, num min, num max) =>
        max <= min ? 1.0 : ((value - min) / (max - min)).toDouble();

    if (focused == null) {
      if (state.cities case SectionLoaded<List<CityMarketStat>>(:final data)) {
        final values = [for (final c in data) c.value];
        final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
        final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
        for (final city in data) {
          if (city.lat == null || city.lng == null) continue;
          final icon = await MapPriceMarker.bubble(
            title: city.name,
            price: Formatters.statValue(city.value.roundToDouble()),
            devicePixelRatio: dpr,
            intensity: intensityOf(city.value, min, max),
            body: body,
            onBody: onBody,
          );
          markers.add(
            Marker(
              markerId: MarkerId('city-${city.cityId}'),
              position: LatLng(city.lat!, city.lng!),
              icon: icon,
              anchor: const Offset(0.5, 0.5),
              // Pricier bubbles paint on top of the overlap.
              zIndexInt: (intensityOf(city.value, min, max) * 100).round(),
              onTap: () => context.read<MarketMapCubit>().focusCity(city),
            ),
          );
        }
      }
    } else if (state.districts case SectionLoaded<List<MarketDistrict>>(
      :final data,
    )) {
      // Declutter: the API returns 100+ districts per city — keep the
      // priciest N so the drill-down stays readable (site-style density
      // without the pile-up).
      final top = [...data]..sort((a, b) => b.value.compareTo(a.value));
      final shown = top.take(_maxDistricts).toList(growable: false);
      final values = [for (final d in shown) d.value];
      final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
      final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
      for (final d in shown) {
        if (d.lat == null || d.lng == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId('district-${d.districtId}'),
            position: LatLng(d.lat!, d.lng!),
            icon: await MapPriceMarker.bubble(
              price: Formatters.statValue(d.value.roundToDouble()),
              devicePixelRatio: dpr,
              intensity: intensityOf(d.value, min, max),
              body: body,
              onBody: onBody,
            ),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: (intensityOf(d.value, min, max) * 100).round(),
            infoWindow: InfoWindow(
              title: d.name,
              snippet: Formatters.statValue(d.value),
            ),
          ),
        );
      }
    }

    if (!mounted || !identical(_markerSource, source)) return;
    setState(() => _markers = markers);
  }

  static const int _maxDistricts = 60;

  Future<void> _moveCamera(MarketMapState state) async {
    final map = _map;
    if (map == null) return;
    final focused = state.focusedCity;
    if (focused != null && focused.lat != null && focused.lng != null) {
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(focused.lat!, focused.lng!), 10.6),
      );
      return;
    }
    // Country view: frame ALL city bubbles (never lets the user stay lost
    // after panning away — see also the Recenter chip).
    final points = switch (state.cities) {
      SectionLoaded<List<CityMarketStat>>(:final data) => [
        for (final c in data)
          if (c.lat != null && c.lng != null) LatLng(c.lat!, c.lng!),
      ],
      _ => const <LatLng>[],
    };
    if (points.length < 2) {
      await map.animateCamera(CameraUpdate.newCameraPosition(_saudiView));
      return;
    }
    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        // Generous padding so edge bubbles render fully inside the card.
        72,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return BlocConsumer<MarketMapCubit, MarketMapState>(
      listener: (context, state) {
        _rebuildMarkers(state);
        _moveCamera(state);
      },
      builder: (context, state) {
        final cubit = context.read<MarketMapCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 26, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      l10n.marketIntelligenceTag.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.interactiveMarketMap,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.marketMapSubtitle,
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
                label: l10n.propertyTypeLabel.toUpperCase(),
                first: l10n.apartment,
                second: l10n.villa,
                firstSelected:
                    state.query.unitTypeId == MarketUnitTypes.apartment,
                onFirst: () => cubit.setUnitType(MarketUnitTypes.apartment),
                onSecond: () => cubit.setUnitType(MarketUnitTypes.villa),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
              child: LabeledToggle(
                label: l10n.listingLabel.toUpperCase(),
                first: l10n.buy,
                second: l10n.rent,
                firstSelected: state.query.transaction == MarketTransaction.buy,
                onFirst: () => cubit.setTransaction(MarketTransaction.buy),
                onSecond: () => cubit.setTransaction(MarketTransaction.rent),
              ),
            ),
            if (state.cities case SectionError<List<CityMarketStat>>(
              :final failure,
            ))
              SectionErrorBox(
                message: failure.localized(l10n),
                onRetry: () => cubit.load(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 400,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _saudiView,
                          style: _nightStyle,
                          mapType: _mapType,
                          markers: _markers,
                          onMapCreated: (c) {
                            _map = c;
                            _rebuildMarkers(state);
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          // Let the map own drag gestures inside the page
                          // scroll view.
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                              EagerGestureRecognizer.new,
                            ),
                          },
                        ),
                        if (state.cities is SectionLoading ||
                            state.districts is SectionLoading)
                          const Align(
                            alignment: Alignment.topCenter,
                            child: LinearProgressIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              minHeight: 3,
                            ),
                          ),
                        // Drill-down: back to country view.
                        if (state.focusedCity != null)
                          PositionedDirectional(
                            top: 12,
                            start: 12,
                            child: _MapChip(
                              icon: Icons.arrow_back_rounded,
                              label:
                                  '${l10n.backToCities} · ${state.focusedCity!.name}',
                              onTap: cubit.clearFocus,
                            ),
                          ),
                        // Hybrid (satellite) toggle, like the website's 🛰️.
                        PositionedDirectional(
                          top: 12,
                          end: 12,
                          child: _MapChip(
                            icon: Icons.satellite_alt_rounded,
                            label: l10n.hybrid,
                            active: _mapType == MapType.hybrid,
                            onTap: () => setState(() {
                              _mapType = _mapType == MapType.hybrid
                                  ? MapType.normal
                                  : MapType.hybrid;
                            }),
                          ),
                        ),
                        // Re-frame the bubbles after free panning.
                        PositionedDirectional(
                          bottom: 12,
                          end: 12,
                          child: _MapChip(
                            icon: Icons.center_focus_strong_rounded,
                            label: l10n.recenter,
                            onTap: () => _moveCamera(state),
                          ),
                        ),
                        // Heatmap intensity legend.
                        PositionedDirectional(
                          bottom: 12,
                          start: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xE61B1B1B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.heatmapIntensity,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.lowLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                for (final alpha in [0.35, 0.55, 0.75, 1.0])
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: alpha,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 1),
                                Text(
                                  l10n.highLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
              child: Text(
                '${l10n.sortedByPriceDesc}  ·  ${l10n.sourceDwelleoIndex}',
                style: TextStyle(
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MapChip({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : const Color(0xE61B1B1B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? AppColors.ink : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.ink : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark map styling in the site's navy-night look (Google's night theme,
/// tuned to keep road/label contrast close to dwelleo.sa's map).
const String _nightStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

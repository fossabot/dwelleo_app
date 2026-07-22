import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';

/// The website's Location block: a map centred on the listing with the
/// property pin plus its nearby points of interest, the full address, and a
/// "open in maps" affordance.
///
/// Data is entirely from the VERIFIED detail payload — `location.lat/lng`,
/// `location.address` and the `spots[]` array (each carrying `category`,
/// `distance` and `commute_time`). Nothing is geocoded client-side, so the
/// pins always agree with the website's.
class PropertyLocationSection extends StatefulWidget {
  final Property property;

  const PropertyLocationSection({super.key, required this.property});

  @override
  State<PropertyLocationSection> createState() =>
      _PropertyLocationSectionState();
}

class _PropertyLocationSectionState extends State<PropertyLocationSection> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    final point = widget.property.location?.point;
    final lat = point?.lat;
    final lng = point?.lng;
    final address = widget.property.location?.address;

    // Nothing to show without coordinates — and we do NOT guess them.
    if (lat == null || lng == null) {
      if (address == null || address.isEmpty) return const SizedBox.shrink();
      return _AddressOnly(address: address);
    }

    final target = LatLng(lat, lng);
    final spots = widget.property.spots
        .where((s) => s.hasPoint)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.location,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: target,
                    zoom: 14.5,
                  ),
                  onMapCreated: (c) => _controller = c,
                  markers: {
                    Marker(
                      markerId: const MarkerId('property'),
                      position: target,
                      infoWindow: InfoWindow(title: widget.property.title),
                    ),
                    for (final spot in spots)
                      Marker(
                        markerId: MarkerId('spot-${spot.id}'),
                        position: LatLng(spot.lat!, spot.lng!),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                        infoWindow: InfoWindow(
                          title: spot.name,
                          snippet: spot.distance,
                        ),
                      ),
                  },
                  // The card is inside a scrolling page: keep the map from
                  // stealing vertical drags, but allow pinch-zoom.
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  scrollGesturesEnabled: false,
                  liteModeEnabled: false,
                ),
                PositionedDirectional(
                  bottom: 10,
                  end: 10,
                  child: Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ContactLauncher.openMap(
                        lat: lat,
                        lng: lng,
                        label: widget.property.title,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 15, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              l10n.openInMaps,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (address != null && address.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (widget.property.spots.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            l10n.nearbyPlaces,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final spot in widget.property.spots.take(6))
            _SpotRow(spot: spot),
        ],
      ],
    );
  }
}

class _SpotRow extends StatelessWidget {
  final PropertySpot spot;

  const _SpotRow({required this.spot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(spot.category), size: 15, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              spot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          if (spot.distance != null) ...[
            const SizedBox(width: 8),
            Text(
              spot.distance!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Maps the API's `category` slug onto an icon. Unknown categories fall
  /// back to a neutral pin rather than being dropped.
  static IconData _iconFor(String? category) => switch (category) {
    'education' || 'school' => Icons.school_outlined,
    'health' || 'medical' => Icons.local_hospital_outlined,
    'shopping' || 'mall' => Icons.shopping_bag_outlined,
    'restaurant' || 'food' => Icons.restaurant_outlined,
    'transport' || 'metro' => Icons.directions_transit_outlined,
    'park' || 'recreation' => Icons.park_outlined,
    'mosque' || 'worship' => Icons.mosque_outlined,
    'business_and_services' => Icons.business_center_outlined,
    _ => Icons.place_outlined,
  };
}

class _AddressOnly extends StatelessWidget {
  final String address;

  const _AddressOnly({required this.address});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.location,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

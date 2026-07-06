import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of the location picker: a human-readable address + coordinates.
class PickedLocation {
  final double lat;
  final double lng;
  final String address;
  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

/// Opens the full-screen "Select Location" modal (mirrors dwelleo.sa): a map
/// with a fixed center pin ("move the map to position the pin"), a
/// Use-Current-Location button, the resolved address, and Confirm.
///
/// NOTE: the Google map tiles require a NATIVE Maps API key in
/// android/app/src/main/AndroidManifest.xml and ios AppDelegate. The web key
/// from the site is HTTP-referrer-restricted and must NOT be committed here;
/// create restricted Android/iOS keys. Without a key the tiles are blank but
/// Use-Current-Location + reverse geocoding still return a valid address.
Future<PickedLocation?> showLocationPicker(BuildContext context) {
  return Navigator.of(context).push<PickedLocation>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _LocationPickerScreen(),
    ),
  );
}

class _LocationPickerScreen extends StatefulWidget {
  const _LocationPickerScreen();

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  // Default view: Riyadh (real coordinates, not invented data).
  static const _fallback = LatLng(24.7136, 46.6753);

  // geocoding v5 replaced the top-level functions with an instance API.
  // Created once per screen (never inside build) and reused for every
  // reverse-geocode as the pin moves.
  final Geocoding _geocoder = Geocoding();

  GoogleMapController? _map;
  LatLng _center = _fallback;
  String _address = '';
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    // Resolve the default (office) address up front so Confirm is usable even
    // before the user moves the map — mirrors the website opening centered on
    // the Dwelleo office.
    _resolve(_fallback);
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _resolve(LatLng at) async {
    setState(() => _resolving = true);
    try {
      final marks = await _geocoder.placemarkFromCoordinates(
        at.latitude,
        at.longitude,
      );
      if (!mounted) return;
      final p = marks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((e) => e != null && e.isNotEmpty).cast<String>();
      setState(() => _address = parts.join(', '));
    } catch (_) {
      if (mounted) setState(() => _address = '');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _useCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Turn on location services to use your current location.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _snack('Location permission is disabled. Enable it in Settings.');
        await Geolocator.openAppSettings();
        return;
      }
      if (perm == LocationPermission.denied) {
        _snack('Location permission denied');
        return;
      }
      setState(() => _resolving = true);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
      setState(() => _center = here);
      await _resolve(here);
    } catch (_) {
      if (mounted) setState(() => _resolving = false);
      _snack('Could not get your location. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _useCurrent,
                  // The global FilledButton theme forces width=infinity
                  // (Size.fromHeight); override so this compact button can size
                  // to its content inside the Row (else: infinite-width crash).
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Use Current Location'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _resolving
                        ? 'Resolving…'
                        : (_address.isEmpty
                              ? 'Move the map to position the pin'
                              : _address),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Positioned.fill gives the platform view a finite size; without
                // it the GoogleMap gets unbounded constraints inside the Stack
                // and throws "RenderBox was not laid out … hasSize".
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _fallback,
                      zoom: 14,
                    ),
                    onMapCreated: (c) => _map = c,
                    myLocationButtonEnabled: false,
                    onCameraMove: (pos) => _center = pos.target,
                    onCameraIdle: () => _resolve(_center),
                  ),
                ),
                // Fixed center pin — the map moves under it. IgnorePointer so the
                // pin never intercepts the map's gestures (re-triggers hit-test).
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: const Alignment(0, -0.04),
                      child: Icon(
                        Icons.location_on,
                        size: 44,
                        color: scheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _address.isEmpty
                          ? null
                          : () => Navigator.pop(
                              context,
                              PickedLocation(
                                lat: _center.latitude,
                                lng: _center.longitude,
                                address: _address,
                              ),
                            ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Confirm Location'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// A city option for dropdowns (id + localized name), from /api/v1/lookup.
class CityOption {
  final String id;
  final String name;
  const CityOption({required this.id, required this.name});
}

/// A property-type option (id + localized name), from /api/v1/lookup.
class PropertyTypeOption {
  final int id;
  final String name;
  const PropertyTypeOption({required this.id, required this.name});
}

/// An area/district option (id + localized name), from /api/v1/lookup.
class AreaOption {
  final int id;
  final String name;
  final int? cityId;
  const AreaOption({required this.id, required this.name, this.cityId});
}

/// Fetches filter lookups (cities, property types, …) from the real backend
/// and caches them (the lists rarely change within a session).
///
/// LOCALE-AWARE CACHE. These lists are localized by the API via the
/// `Accept-Language` header (`?locale=` is ignored — verified live). A plain
/// cache therefore keeps serving the PREVIOUS language after the user
/// switches: English chips would keep reading "شقة 2,324" and vice-versa.
/// The cache is stamped with the locale it was built for and dropped the
/// moment that changes.
class LookupService {
  final Dio _dio;
  final SecureStorage _storage;

  LookupService(this._dio, this._storage);

  List<CityOption>? _citiesCache;
  List<PropertyTypeOption>? _typesCache;
  List<AreaOption>? _areasCache;

  /// The `/lookup` endpoint returns EVERY section (cities, property_types,
  /// areas) in one response. Cache the in-flight fetch so cities()/
  /// propertyTypes()/areas() — which fire together on startup — coalesce into
  /// a single network round-trip instead of three identical GETs.
  Future<Map>? _lookupData;

  /// Locale the caches above were populated with.
  String? _cachedLocale;

  /// Drops every cached list when the app language changed since last call.
  Future<void> _syncLocale() async {
    final locale = await _storage.getLocale() ?? 'en';
    if (_cachedLocale == locale) return;
    _cachedLocale = locale;
    _citiesCache = null;
    _typesCache = null;
    _areasCache = null;
    _lookupData = null;
  }

  Future<List<CityOption>> cities() async {
    await _syncLocale();
    final cached = _citiesCache;
    if (cached != null) return cached;
    final raw = await _section('cities');
    final list = raw
        .map(
          (m) => CityOption(
            id: '${m['id']}',
            name: (m['name'] ?? m['title'] ?? '').toString(),
          ),
        )
        .where((c) => c.name.isNotEmpty)
        .toList(growable: false);
    _citiesCache = list;
    return list;
  }

  Future<List<PropertyTypeOption>> propertyTypes() async {
    await _syncLocale();
    final cached = _typesCache;
    if (cached != null) return cached;
    final raw = await _section('property_types');
    final list = raw
        .map(
          (m) => PropertyTypeOption(
            id: int.tryParse('${m['id']}') ?? 0,
            name: (m['name'] ?? m['title'] ?? '').toString(),
          ),
        )
        .where((t) => t.id > 0 && t.name.isNotEmpty)
        .toList(growable: false);
    _typesCache = list;
    return list;
  }

  Future<List<AreaOption>> areas() async {
    await _syncLocale();
    final cached = _areasCache;
    if (cached != null) return cached;
    final raw = await _section('areas');
    final list = raw
        .map(
          (m) => AreaOption(
            id: int.tryParse('${m['id']}') ?? 0,
            name: (m['name'] ?? m['title'] ?? '').toString(),
            cityId: int.tryParse('${m['city_id']}'),
          ),
        )
        .where((a) => a.id > 0 && a.name.isNotEmpty)
        .toList(growable: false);
    _areasCache = list;
    return list;
  }

  Future<List<Map>> _section(String key) async {
    final data = await (_lookupData ??= _fetchLookup());
    final raw = data[key];
    return raw is List
        ? raw.whereType<Map>().toList(growable: false)
        : const [];
  }

  /// Fetches the full `/lookup` payload once. On failure the cached future is
  /// cleared so the next section call retries rather than replaying the error.
  Future<Map> _fetchLookup() async {
    try {
      final res = await _dio.get<dynamic>(ApiEndpoints.lookup);
      final body = res.data;
      final data = body is Map ? body['data'] : null;
      return data is Map ? data : const {};
    } catch (_) {
      _lookupData = null;
      rethrow;
    }
  }
}

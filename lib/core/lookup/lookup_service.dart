import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';

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

/// Fetches filter lookups (cities, property types, …) from the real backend
/// and caches them (the lists rarely change within a session).
class LookupService {
  final Dio _dio;
  LookupService(this._dio);

  List<CityOption>? _citiesCache;
  List<PropertyTypeOption>? _typesCache;

  Future<List<CityOption>> cities() async {
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

  Future<List<Map>> _section(String key) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.lookup);
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    final raw = data is Map ? data[key] : null;
    return raw is List
        ? raw.whereType<Map>().toList(growable: false)
        : const [];
  }
}

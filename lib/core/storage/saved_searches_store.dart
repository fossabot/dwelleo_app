import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A persisted property search: the user's filter set with a display label
/// (mobile upgrade of the website's repeat-search habit).
class SavedSearch {
  final String label;
  final String? listingType;
  final List<int> propertyTypeIds;
  final int? cityId;
  final int? minBedrooms;
  final int? minBathrooms;
  final num? minPrice;
  final num? maxPrice;
  final String? furnishingStatus;

  const SavedSearch({
    required this.label,
    this.listingType,
    this.propertyTypeIds = const [],
    this.cityId,
    this.minBedrooms,
    this.minBathrooms,
    this.minPrice,
    this.maxPrice,
    this.furnishingStatus,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'lt': listingType,
    'pts': propertyTypeIds,
    'city': cityId,
    'beds': minBedrooms,
    'baths': minBathrooms,
    'minP': minPrice,
    'maxP': maxPrice,
    'furn': furnishingStatus,
  };

  static SavedSearch? fromJson(dynamic v) {
    if (v is! Map) return null;
    final label = v['label'];
    if (label is! String || label.isEmpty) return null;
    return SavedSearch(
      label: label,
      listingType: v['lt'] as String?,
      propertyTypeIds: v['pts'] is List
          ? (v['pts'] as List).whereType<int>().toList(growable: false)
          : const [],
      cityId: v['city'] as int?,
      minBedrooms: v['beds'] as int?,
      minBathrooms: v['baths'] as int?,
      minPrice: v['minP'] as num?,
      maxPrice: v['maxP'] as num?,
      furnishingStatus: v['furn'] as String?,
    );
  }
}

/// Local persistence for saved searches (newest first, label-deduplicated).
class SavedSearchesStore {
  static const String _key = 'saved_searches_v1';
  static const int _max = 10;

  Future<List<SavedSearch>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(SavedSearch.fromJson)
          .whereType<SavedSearch>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<SavedSearch>> add(SavedSearch search) async {
    final next = [
      search,
      ...(await load()).where((s) => s.label != search.label),
    ].take(_max).toList(growable: false);
    await _write(next);
    return next;
  }

  Future<List<SavedSearch>> remove(String label) async {
    final next = (await load())
        .where((s) => s.label != label)
        .toList(growable: false);
    await _write(next);
    return next;
  }

  Future<void> _write(List<SavedSearch> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final s in items) s.toJson()]),
    );
  }
}

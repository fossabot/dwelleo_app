import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/entities/type_count.dart';

/// Session cache for the type-count strip so revisiting a list doesn't re-fire
/// the same per-type fan-out (6 GETs) on every screen open. Counts are keyed by
/// the shared base query — the strip is the same for every visit of that query.
///
/// LOCALE-AWARE, like [LookupService]: the counts carry localized type names, so
/// the whole cache is dropped when the app language changes.
class TypeCountsCache {
  final SecureStorage _storage;

  TypeCountsCache(this._storage);

  final Map<PropertyQuery, List<TypeCount>> _byQuery = {};

  /// Locale the entries above were populated with.
  String? _cachedLocale;

  /// Cached counts for [key], or null on a miss. Drops everything first if the
  /// language changed since the last call — the single locale read per load.
  Future<List<TypeCount>?> get(PropertyQuery key) async {
    final locale = await _storage.getLocale() ?? 'en';
    if (_cachedLocale != locale) {
      _cachedLocale = locale;
      _byQuery.clear();
    }
    return _byQuery[key];
  }

  /// Stores [counts] for [key], overwriting any prior entry. Always called right
  /// after [get] within the same load, so the locale is already in sync — no
  /// extra keychain read here. A forced refresh overwrites on success only, so a
  /// failed refresh leaves the previous good entry in place.
  void put(PropertyQuery key, List<TypeCount> counts) {
    _byQuery[key] = counts;
  }
}

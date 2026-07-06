import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/city_market_stat.dart';

/// Maps `/api/v1/market/cities` and `/api/v1/market/districts` JSON into
/// domain entities.
///
/// CAPTURED live (2026-07-02): with `unit_type_id` in the query the API
/// returns `filtered_stats` as an OBJECT; the bare call returns it as an
/// ARRAY of per-unit-type entries. The buy shape carries `price_of_meter`,
/// the rent shape carries `monthly_price`. Both are tolerated here.
abstract final class CityMarketStatModel {
  static List<CityMarketStat> listFromEnvelope(
    Map<String, dynamic> json, {
    required MarketQuery query,
  }) {
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) => cityFromJson(j, query: query))
        .whereType<CityMarketStat>()
        .toList(growable: false);
  }

  static CityMarketStat? cityFromJson(
    Map<String, dynamic> j, {
    required MarketQuery query,
  }) {
    final value = statValue(j['filtered_stats'], query);
    if (value == null) return null; // no data for this combination → drop city
    return CityMarketStat(
      cityId: JsonParse.toInt(j['city_id']) ?? 0,
      name: (j['name'] ?? '').toString(),
      lat: JsonParse.toDouble(j['lat']),
      lng: JsonParse.toDouble(j['lng']),
      value: value,
      median: statMedian(j['filtered_stats'], query),
      lastUpdated: j['last_updated']?.toString(),
    );
  }

  static List<MarketDistrict> districtsFromEnvelope(
    Map<String, dynamic> json, {
    required MarketQuery query,
  }) {
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) {
          final value = statValue(j['filtered_stats'], query);
          if (value == null) return null;
          return MarketDistrict(
            districtId: JsonParse.toInt(j['district_id']) ?? 0,
            name: (j['name'] ?? '').toString(),
            lat: JsonParse.toDouble(j['lat']),
            lng: JsonParse.toDouble(j['lng']),
            value: value,
            median: statMedian(j['filtered_stats'], query),
          );
        })
        .whereType<MarketDistrict>()
        .toList(growable: false);
  }

  // ── filtered_stats readers (object OR legacy array shape) ─────────────────

  static num? statValue(dynamic stats, MarketQuery query) {
    final m = _statMap(stats, query.unitTypeId);
    if (m == null) return null;
    return switch (query.transaction) {
      MarketTransaction.buy => JsonParse.toNum(m['price_of_meter']),
      MarketTransaction.rent => JsonParse.toNum(m['monthly_price']),
    };
  }

  static num? statMedian(dynamic stats, MarketQuery query) =>
      JsonParse.toNum(_statMap(stats, query.unitTypeId)?['median']);

  static Map<String, dynamic>? _statMap(dynamic stats, int unitTypeId) {
    final asMap = JsonParse.asMap(stats);
    if (asMap != null) {
      final id = JsonParse.toInt(asMap['unit_type_id']);
      return (id == null || id == unitTypeId) ? asMap : null;
    }
    if (stats is List) {
      for (final e in stats.whereType<Map<String, dynamic>>()) {
        if (JsonParse.toInt(e['unit_type_id']) == unitTypeId) return e;
      }
    }
    return null;
  }
}

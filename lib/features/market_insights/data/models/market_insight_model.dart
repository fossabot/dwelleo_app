import '../../domain/entities/market_insight.dart';

/// Parsers for the `/market-insights/...` envelopes.
///
/// Row keys are dynamic: the API publishes `commercial_2020` /
/// `commercial_2024` today, so the year is read OUT of the key rather than
/// hardcoded — when the backend adds 2025 the app picks it up for free.
abstract final class MarketInsightModel {
  static final RegExp _yearKey = RegExp(r'_(\d{4})$');

  static MarketInsightSeries seriesFromEnvelope(
    Map<dynamic, dynamic> json,
    MarketInsightChart chart,
  ) {
    final data = json['data'];
    final body = data is Map ? data : const {};
    final rows = body['data'];

    final points = <MarketInsightPoint>[];
    int? baseYear;
    int? latestYear;

    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;

        // Label: `city` on the two city charts, `region` on the third.
        final label = (row['city'] ?? row['region'] ?? '').toString();
        if (label.isEmpty) continue;

        // Collect every `*_<year>` numeric column, then take the earliest as
        // the base and the latest as the current value.
        final byYear = <int, num>{};
        for (final entry in row.entries) {
          final match = _yearKey.firstMatch('${entry.key}');
          if (match == null) continue;
          final year = int.tryParse(match.group(1)!);
          final value = _num(entry.value);
          if (year != null && value != null) byYear[year] = value;
        }
        if (byYear.length < 2) continue;

        final years = byYear.keys.toList()..sort();
        baseYear ??= years.first;
        latestYear ??= years.last;

        points.add(
          MarketInsightPoint(
            label: label,
            base: byYear[years.first]!,
            latest: byYear[years.last]!,
          ),
        );
      }
    }

    return MarketInsightSeries(
      chart: chart,
      // Localized by the API through Accept-Language — render as-is.
      name: (body['name'] ?? '').toString(),
      description: (body['description'] ?? '').toString(),
      points: List.unmodifiable(points),
      baseYear: baseYear,
      latestYear: latestYear,
    );
  }

  static MarketInsightLookups lookupsFromEnvelope(Map<dynamic, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return MarketInsightLookups.empty;

    return MarketInsightLookups(
      regions: _labels(data['regions']),
      cities: _labels(data['cities']),
      unitTypes: _options(data['unit_types']),
      unitPurposes: _options(data['unit_purposes']),
      years: [
        for (final y in (data['years'] is List ? data['years'] as List : []))
          if (y is Map && _int(y['value']) != null) _int(y['value'])!,
      ],
    );
  }

  static List<String> _labels(dynamic raw) => [
    for (final item in (raw is List ? raw : const []))
      if (item is Map && '${item['label'] ?? ''}'.isNotEmpty)
        '${item['label']}',
  ];

  static List<MarketInsightOption> _options(dynamic raw) => [
    for (final item in (raw is List ? raw : const []))
      if (item is Map &&
          '${item['value'] ?? ''}'.isNotEmpty &&
          '${item['label'] ?? ''}'.isNotEmpty)
        MarketInsightOption(
          value: '${item['value']}',
          label: '${item['label']}',
        ),
  ];

  static num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

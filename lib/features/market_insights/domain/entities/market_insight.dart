/// Domain models for Market Insights (dwelleo.sa/en/market-insights).
///
/// CONTRACT CAPTURED LIVE 2026-07-21 from the page's own network traffic:
///
///   /api/v1/market-insights/{insight_type}/lookups
///   /api/v1/market-insights/{insight_type}/top-cities-commercial-growth
///   /api/v1/market-insights/{insight_type}/highest-commercial-growth-cities
///   /api/v1/market-insights/{insight_type}/commercial-units-growth
///
/// Only `insight_type = rental` is live; `sale` returns 404 — the website's
/// own Rent/Sale toggle has no Sale data behind it.
///
/// Every chart responds with the same envelope:
/// `{chart_type, insight_type, name, description, data[], filters_applied}`
/// where `name`/`description` arrive ALREADY LOCALIZED via the
/// `Accept-Language` header (`?locale=` is ignored). They must therefore be
/// rendered from the payload, never from ARB.
library;

enum MarketInsightChart {
  /// 15 cities · dumbbell chart (base → latest).
  topCitiesCommercialGrowth,

  /// 10 cities · ranked bars with growth % and ×multiplier.
  highestCommercialGrowthCities,

  /// 13 regions · cards with a relative-scale bar.
  commercialUnitsGrowth;

  /// Path segment on the API.
  String get path => switch (this) {
    MarketInsightChart.topCitiesCommercialGrowth =>
      'top-cities-commercial-growth',
    MarketInsightChart.highestCommercialGrowthCities =>
      'highest-commercial-growth-cities',
    MarketInsightChart.commercialUnitsGrowth => 'commercial-units-growth',
  };
}

/// One row: a city or region measured in two years.
class MarketInsightPoint {
  /// City or region name, localized by the API.
  final String label;

  /// Value in the earliest published year (e.g. 2020).
  final num base;

  /// Value in the latest published year (e.g. 2024).
  final num latest;

  const MarketInsightPoint({
    required this.label,
    required this.base,
    required this.latest,
  });

  /// Growth as a fraction. VERIFIED against the website: Riyadh
  /// 10.3 → 15.37 renders as "+49%", and (15.37-10.3)/10.3 = 0.4922.
  double get growth => base == 0 ? 0 : (latest - base) / base;

  /// How many times the latest year exceeded the base — the site's "×1.5".
  double get multiplier => base == 0 ? 0 : latest / base;
}

/// A fully-resolved chart: API-localized copy plus its rows and totals.
class MarketInsightSeries {
  final MarketInsightChart chart;

  /// Localized title from the API (never hardcoded).
  final String name;

  /// Localized explanatory paragraph from the API.
  final String description;

  final List<MarketInsightPoint> points;

  /// Years parsed from the payload keys (`commercial_2020` → 2020), so a
  /// backend that starts publishing 2025 needs no app change.
  final int? baseYear;
  final int? latestYear;

  const MarketInsightSeries({
    required this.chart,
    required this.name,
    required this.description,
    required this.points,
    this.baseYear,
    this.latestYear,
  });

  num get baseTotal => points.fold<num>(0, (sum, p) => sum + p.base);

  num get latestTotal => points.fold<num>(0, (sum, p) => sum + p.latest);

  /// The site's "OVERALL GROWTH" figure — computed over the totals, not as
  /// an average of per-row growths (those differ, and the site shows the
  /// former: 164.69 → 228.77 prints +39%).
  double get overallGrowth =>
      baseTotal == 0 ? 0 : (latestTotal - baseTotal) / baseTotal;

  /// Largest latest-year value, for relative bar scaling.
  num get maxLatest => points.isEmpty
      ? 0
      : points.map((p) => p.latest).reduce((a, b) => a > b ? a : b);

  /// Largest growth, for scaling the ranked-bar chart.
  double get maxGrowth => points.isEmpty
      ? 0
      : points.map((p) => p.growth).reduce((a, b) => a > b ? a : b);
}

/// Filter options from `/lookups`.
class MarketInsightLookups {
  final List<String> regions;
  final List<String> cities;
  final List<MarketInsightOption> unitTypes;
  final List<MarketInsightOption> unitPurposes;
  final List<int> years;

  const MarketInsightLookups({
    this.regions = const [],
    this.cities = const [],
    this.unitTypes = const [],
    this.unitPurposes = const [],
    this.years = const [],
  });

  static const empty = MarketInsightLookups();
}

/// `{value, label}` pair — value goes to the API, label to the user.
class MarketInsightOption {
  final String value;
  final String label;

  const MarketInsightOption({required this.value, required this.label});
}

/// Active filter selection. Sent as query params; omitted when null.
class MarketInsightFilters {
  final String? region;
  final String? city;
  final String? unitType;
  final String? unitPurpose;

  const MarketInsightFilters({
    this.region,
    this.city,
    this.unitType,
    this.unitPurpose,
  });

  bool get isEmpty =>
      region == null && city == null && unitType == null && unitPurpose == null;

  int get activeCount =>
      [region, city, unitType, unitPurpose].where((v) => v != null).length;

  MarketInsightFilters copyWith({
    String? Function()? region,
    String? Function()? city,
    String? Function()? unitType,
    String? Function()? unitPurpose,
  }) {
    return MarketInsightFilters(
      region: region == null ? this.region : region(),
      city: city == null ? this.city : city(),
      unitType: unitType == null ? this.unitType : unitType(),
      unitPurpose: unitPurpose == null ? this.unitPurpose : unitPurpose(),
    );
  }

  Map<String, String> toQueryParams() => {
    'region': ?region,
    'city': ?city,
    'unit_type': ?unitType,
    'unit_purpose': ?unitPurpose,
  };
}

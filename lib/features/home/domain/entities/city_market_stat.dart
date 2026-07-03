import 'package:equatable/equatable.dart';

/// Unit types for market stats. CONFIRMED against live data (2026-07-02):
/// /lookup property_types id 1 = Apartment (شقة), id 2 = Villa (فيلا), and the
/// market endpoints filter with the same ids.
abstract final class MarketUnitTypes {
  static const int apartment = 1;
  static const int villa = 2;
}

/// Listing side of the market stats — the website's LISTING Buy|Rent toggle.
/// API values CAPTURED from live network traffic (2026-07-02):
/// `transaction_type=buy` | `transaction_type=rent`.
enum MarketTransaction {
  buy('buy'),
  rent('rent');

  final String apiValue;
  const MarketTransaction(this.apiValue);
}

/// Filter for `/market/cities` and `/market/districts` — the exact params the
/// website sends: `?unit_type_id={id}&heatmap=price&transaction_type={tx}`.
class MarketQuery extends Equatable {
  final int unitTypeId;
  final MarketTransaction transaction;

  const MarketQuery({
    this.unitTypeId = MarketUnitTypes.apartment,
    this.transaction = MarketTransaction.buy,
  });

  MarketQuery copyWith({int? unitTypeId, MarketTransaction? transaction}) =>
      MarketQuery(
        unitTypeId: unitTypeId ?? this.unitTypeId,
        transaction: transaction ?? this.transaction,
      );

  /// Cache key for already-fetched combinations.
  String get key => '$unitTypeId-${transaction.apiValue}';

  @override
  List<Object?> get props => [unitTypeId, transaction];
}

/// Market stats for one Saudi city, already filtered server-side by the
/// query. CAPTURED response shapes (2026-07-02):
///  buy : filtered_stats { unit_type_id, price_of_meter, median }   → SAR/m²
///  rent: filtered_stats { unit_type_id, monthly_price, annual_price,
///        median }                                                  → SAR/mo
/// Envelope: `{success: true, data: [...]}`.
class CityMarketStat extends Equatable {
  final int cityId;
  final String name;
  final double? lat;
  final double? lng;

  /// The headline number for the requested query:
  /// price per m² for buy, monthly price for rent.
  final num value;
  final num? median;
  final String? lastUpdated;

  const CityMarketStat({
    required this.cityId,
    required this.name,
    this.lat,
    this.lng,
    required this.value,
    this.median,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    cityId,
    name,
    lat,
    lng,
    value,
    median,
    lastUpdated,
  ];
}

/// District-level stats inside one city (`/market/districts?city_id=…`),
/// used by the Interactive Market map's drill-down.
/// CAPTURED envelope: `{success, city_id, data: [...]}` (121 Riyadh districts).
class MarketDistrict extends Equatable {
  final int districtId;
  final String name;
  final double? lat;
  final double? lng;
  final num value;
  final num? median;

  const MarketDistrict({
    required this.districtId,
    required this.name,
    this.lat,
    this.lng,
    required this.value,
    this.median,
  });

  @override
  List<Object?> get props => [districtId, name, lat, lng, value, median];
}

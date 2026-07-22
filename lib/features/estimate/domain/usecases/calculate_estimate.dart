import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../../home/domain/entities/city_market_stat.dart';
import '../../../home/domain/usecases/get_market_districts.dart';
import '../entities/estimate_models.dart';

/// Turns the wizard's answers into a price band using ONLY verified market
/// numbers (`/market/districts`) — no invented model.
///
/// The formula is the site's own, reverse-checked against a live run
/// (Riyadh · Al Amal Dist. · apartment · 180 m² → 7,747 SAR/m² →
/// 1,394,400 mid, 1,268,904 low, 1,492,008 high):
///
///   mid  = area x district SAR/m²        (buy stats, matching unit type)
///   low  = mid x 0.91                    (EXACT ratio observed)
///   high = mid x 1.07                    (EXACT ratio observed)
///
/// Rent side: the API publishes rent as an ABSOLUTE monthly figure per
/// district (never per-m²), so annual rent = monthly x 12 and the net yield
/// is annual rent / sale price — both straight from the same endpoint.
/// The ±spread ([lowRatio]/[highRatio]) was only ever observed on the SALE
/// run, so the rent band reuses it as a STATED market-uncertainty
/// assumption, not as observed rent precision (see [rentBandIsAssumed]).
///
/// NOT implemented on purpose: the site's "expected days to sell" band. One
/// observed sample is not a model, and guessing it would put a fabricated
/// number in front of a seller.
class CalculateEstimate {
  final GetMarketDistricts _getDistricts;

  const CalculateEstimate(this._getDistricts);

  /// Site-verified spread around the mid point (observed on the sale run).
  static const double lowRatio = 0.91;
  static const double highRatio = 1.07;

  /// The rent low/high band is the sale-observed spread reused as an
  /// assumption — surfaced so the UI can label the rent band accordingly and
  /// never present it as separately verified.
  static const bool rentBandIsAssumed = true;

  Future<ApiResult<EstimateResult>> call(EstimateInput input) async {
    final cityId = input.cityId;
    final districtId = input.districtId;
    final area = input.areaSqm;
    if (cityId == null || districtId == null || area == null || area <= 0) {
      return const ApiError(
        ValidationFailure('Location and floor area are required'),
      );
    }

    final query = MarketQuery(
      unitTypeId: input.unitTypeId,
      transaction: MarketTransaction.buy,
    );
    final buyResult = await _getDistricts(cityId, query);

    return buyResult.when(
      success: (districts) async {
        final district = _find(districts, districtId);
        if (district == null) {
          return const ApiError(
            ValidationFailure('No market data for this district yet'),
          );
        }

        final pricePerSqm = district.value;
        final salePrice = pricePerSqm * area;

        // Rent side is a second call; if it fails we still ship the sale
        // band rather than blocking the whole result.
        num? annualRent;
        final rentResult = await _getDistricts(
          cityId,
          query.copyWith(transaction: MarketTransaction.rent),
        );
        rentResult.when(
          success: (rentDistricts) {
            final monthly = _find(rentDistricts, districtId)?.value;
            if (monthly != null && monthly > 0) annualRent = monthly * 12;
          },
          error: (_) {},
        );

        final renting = input.purpose == EstimatePurpose.rent;
        final headline = renting ? (annualRent ?? 0) : salePrice;
        if (headline <= 0) {
          return const ApiError(
            ValidationFailure('No market data for this district yet'),
          );
        }

        final rent = annualRent;
        // Sale: [lowRatio]/[highRatio] are the site-verified spread. Rent: no
        // rent-specific spread was ever observed, so the same band is reused
        // as a stated assumption ([rentBandIsAssumed]) rather than invented
        // precision.
        return ApiSuccess(
          EstimateResult(
            mid: headline,
            low: headline * lowRatio,
            high: headline * highRatio,
            pricePerSqm: renting ? null : pricePerSqm,
            annualRent: rent,
            netYield: (rent != null && salePrice > 0) ? rent / salePrice : null,
            confidence: input.confidence,
            factors: _factors(input),
          ),
        );
      },
      error: (failure) async => ApiError(failure),
    );
  }

  static MarketDistrict? _find(List<MarketDistrict> all, int id) {
    for (final d in all) {
      if (d.districtId == id) return d;
    }
    return null;
  }

  /// The site's "Why this estimate?" rows. Qualitative only — each row
  /// reflects an answer the user actually gave, never a made-up weight.
  static List<EstimateFactor> _factors(EstimateInput input) {
    final currentYear = DateTime.now().year;
    final builtYear = input.yearBuilt;
    final amenityCount = [
      input.elevator,
      input.parking,
      input.storageRoom,
      input.security247,
    ].where((e) => e).length;

    return [
      const EstimateFactor(EstimateFactorKey.districtPrice, positive: true),
      EstimateFactor(
        EstimateFactorKey.areaAndRooms,
        positive: (input.areaSqm ?? 0) >= 120 || input.bedrooms >= 3,
      ),
      if (builtYear != null)
        EstimateFactor(
          EstimateFactorKey.buildingAge,
          // The site marked a 2015 build "Negative" in 2026 — anything past
          // a decade reads as ageing stock.
          positive: currentYear - builtYear < 10,
        ),
      EstimateFactor(EstimateFactorKey.amenities, positive: amenityCount >= 2),
    ];
  }
}

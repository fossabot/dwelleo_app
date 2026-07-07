import '../../../../core/errors/failure.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../properties/domain/entities/property_query.dart';

/// What the on-device interpreter recognized in a natural-language utterance.
///
/// Every field maps 1:1 to a **verified** `/properties` filter param
/// (see docs/api/REAL_API_SPEC.md). Anything the backend contract does not
/// support (amenities values, districts, "cheapest" ranking …) is deliberately
/// NOT represented here — the PENDING `/user/ai/*` endpoints will own that
/// once their payloads are captured. Never invent contract fields.
class AiInterpretation {
  /// `for-sale` | `for-rent` | null (no listing filter).
  final String? listingType;
  final PropertyTypeOption? propertyType;
  final CityOption? city;
  final int? minBedrooms;
  final int? minBathrooms;
  final num? minPrice;
  final num? maxPrice;

  /// Verified enum only: unfurnished | semi-furnished | partially_furnished.
  final String? furnishingStatus;

  const AiInterpretation({
    this.listingType,
    this.propertyType,
    this.city,
    this.minBedrooms,
    this.minBathrooms,
    this.minPrice,
    this.maxPrice,
    this.furnishingStatus,
  });

  /// True when at least one actionable filter was recognized.
  bool get hasSignal =>
      listingType != null ||
      propertyType != null ||
      city != null ||
      minBedrooms != null ||
      minBathrooms != null ||
      minPrice != null ||
      maxPrice != null ||
      furnishingStatus != null;

  /// The verified search query this interpretation resolves to (page 1).
  PropertyQuery toQuery() => PropertyQuery(
    listingType: listingType,
    propertyTypeIds: [if (propertyType != null) propertyType!.id],
    cityId: city == null ? null : int.tryParse(city!.id),
    minBedrooms: minBedrooms,
    minBathrooms: minBathrooms,
    minPrice: minPrice,
    maxPrice: maxPrice,
    furnishingStatus: furnishingStatus,
  );
}

/// A resolved assistant answer: interpretation + live results from the
/// verified `/properties` search.
class AiSearchAnswer {
  final AiInterpretation interpretation;

  /// The exact query that produced [total]/[preview] — handed to the full
  /// results screen so both show identical data.
  final PropertyQuery query;
  final int total;
  final List<Property> preview;

  const AiSearchAnswer({
    required this.interpretation,
    required this.query,
    required this.total,
    required this.preview,
  });
}

/// One chat turn: the user's utterance and the assistant's outcome.
/// Exactly one of [loading] / [answer] / [failure] / [unrecognized] is
/// meaningful at a time.
class AiSearchTurn {
  final String utterance;
  final bool loading;
  final AiSearchAnswer? answer;
  final Failure? failure;
  final bool unrecognized;

  const AiSearchTurn({
    required this.utterance,
    this.loading = false,
    this.answer,
    this.failure,
    this.unrecognized = false,
  });
}

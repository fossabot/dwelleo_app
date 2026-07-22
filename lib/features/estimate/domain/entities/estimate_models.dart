/// Domain models for the 6-phase Estimate Property wizard.
///
/// Contract CAPTURED from dwelleo.sa/en/Estimate (2026-07-21) by walking the
/// live wizard end to end:
///   1 Purpose      → Sell my property | Rent my property
///   2 Location     → City → District (cascading; district is required)
///   3 Property type→ Apartment | Villa ONLY (the site labels Penthouse /
///                    Studio / Rest house / Commercial "coming soon" — the
///                    market API only publishes unit_type_id 1 and 2)
///   4 Details      → floor area (HIGH IMPACT), bedrooms (HIGH IMPACT),
///                    living rooms, bathrooms, year built, streets facing
///   5 Condition    → fitted kitchen, furnished, AC installed, AC type
///   6 Features     → elevator, parking, storage room, 24/7 security
///   + optional     → facing direction, balcony ("raise the confidence index")
///
/// The site computes the estimate CLIENT-SIDE (verified: submitting the
/// wizard fires no backend call — only analytics), so this app does the same
/// over the already-verified /market/districts numbers.
library;

enum EstimatePurpose { sell, rent }

enum AcType { none, split, central, concealed }

enum FacingDirection { north, east, south, west }

/// Everything the wizard collects. Immutable; the cubit rebuilds it per edit.
class EstimateInput {
  final EstimatePurpose purpose;

  // Step 2 — location (district drives the whole valuation).
  final int? cityId;
  final String? cityName;
  final int? districtId;
  final String? districtName;

  // Step 3 — unit type: MarketUnitTypes.apartment (1) or .villa (2).
  final int unitTypeId;

  // Step 4 — details.
  final num? areaSqm;
  final int bedrooms;
  final int livingRooms;
  final int bathrooms;
  final int? yearBuilt;
  final int streetsFacing;

  // Step 5 — condition.
  final bool fittedKitchen;
  final bool furnished;
  final bool acInstalled;
  final AcType acType;

  // Step 6 — features.
  final bool elevator;
  final bool parking;
  final bool storageRoom;
  final bool security247;

  // Optional accuracy booster.
  final FacingDirection? facing;
  final bool balcony;

  const EstimateInput({
    this.purpose = EstimatePurpose.sell,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.unitTypeId = 1,
    this.areaSqm,
    this.bedrooms = 0,
    this.livingRooms = 0,
    this.bathrooms = 0,
    this.yearBuilt,
    this.streetsFacing = 0,
    this.fittedKitchen = false,
    this.furnished = false,
    this.acInstalled = false,
    this.acType = AcType.none,
    this.elevator = false,
    this.parking = false,
    this.storageRoom = false,
    this.security247 = false,
    this.facing,
    this.balcony = false,
  });

  /// Step 2 gate — the site keeps Next disabled until BOTH are chosen.
  bool get hasLocation => cityId != null && districtId != null;

  /// Step 4 gate — the site's "fill in all required fields to continue".
  bool get hasRequiredDetails => (areaSqm ?? 0) > 0 && bedrooms > 0;

  /// Drives the site's 5-dot confidence index: the base six phases give a
  /// solid read, and each optional characteristic adds a dot.
  int get confidence {
    var dots = 3;
    if (yearBuilt != null) dots++;
    if (facing != null || balcony) dots++;
    return dots.clamp(1, 5);
  }

  EstimateInput copyWith({
    EstimatePurpose? purpose,
    int? Function()? cityId,
    String? Function()? cityName,
    int? Function()? districtId,
    String? Function()? districtName,
    int? unitTypeId,
    num? Function()? areaSqm,
    int? bedrooms,
    int? livingRooms,
    int? bathrooms,
    int? Function()? yearBuilt,
    int? streetsFacing,
    bool? fittedKitchen,
    bool? furnished,
    bool? acInstalled,
    AcType? acType,
    bool? elevator,
    bool? parking,
    bool? storageRoom,
    bool? security247,
    FacingDirection? Function()? facing,
    bool? balcony,
  }) {
    return EstimateInput(
      purpose: purpose ?? this.purpose,
      cityId: cityId == null ? this.cityId : cityId(),
      cityName: cityName == null ? this.cityName : cityName(),
      districtId: districtId == null ? this.districtId : districtId(),
      districtName: districtName == null ? this.districtName : districtName(),
      unitTypeId: unitTypeId ?? this.unitTypeId,
      areaSqm: areaSqm == null ? this.areaSqm : areaSqm(),
      bedrooms: bedrooms ?? this.bedrooms,
      livingRooms: livingRooms ?? this.livingRooms,
      bathrooms: bathrooms ?? this.bathrooms,
      yearBuilt: yearBuilt == null ? this.yearBuilt : yearBuilt(),
      streetsFacing: streetsFacing ?? this.streetsFacing,
      fittedKitchen: fittedKitchen ?? this.fittedKitchen,
      furnished: furnished ?? this.furnished,
      acInstalled: acInstalled ?? this.acInstalled,
      acType: acType ?? this.acType,
      elevator: elevator ?? this.elevator,
      parking: parking ?? this.parking,
      storageRoom: storageRoom ?? this.storageRoom,
      security247: security247 ?? this.security247,
      facing: facing == null ? this.facing : facing(),
      balcony: balcony ?? this.balcony,
    );
  }
}

/// One row of the site's "Why this estimate?" panel.
enum EstimateFactorKey { districtPrice, areaAndRooms, buildingAge, amenities }

class EstimateFactor {
  final EstimateFactorKey key;
  final bool positive;

  const EstimateFactor(this.key, {required this.positive});
}

/// The result card. For [EstimatePurpose.sell] the headline is a sale price;
/// for rent it is the expected ANNUAL rent (the market API publishes rent as
/// an absolute monthly figure, never per-m²).
class EstimateResult {
  /// Headline figure (sale price, or annual rent when renting).
  final num mid;
  final num low;
  final num high;

  /// Sale price per m² — null on the rent path (no per-m² rent published).
  final num? pricePerSqm;

  /// Expected annual rent for the same unit, when the rent side is known.
  final num? annualRent;

  /// annualRent / salePrice — only computable when BOTH sides resolved.
  final double? netYield;

  final int confidence;
  final List<EstimateFactor> factors;

  const EstimateResult({
    required this.mid,
    required this.low,
    required this.high,
    this.pricePerSqm,
    this.annualRent,
    this.netYield,
    required this.confidence,
    this.factors = const [],
  });
}

/// A saved estimate row (DB v3 `estimates`) — the owner's requirement that
/// the wizard "effect on database" and stay attached to the user's account.
class SavedEstimate {
  final int id;
  final EstimatePurpose purpose;
  final String cityName;
  final String districtName;
  final int unitTypeId;
  final num areaSqm;
  final num mid;
  final num low;
  final num high;
  final DateTime createdAt;

  const SavedEstimate({
    required this.id,
    required this.purpose,
    required this.cityName,
    required this.districtName,
    required this.unitTypeId,
    required this.areaSqm,
    required this.mid,
    required this.low,
    required this.high,
    required this.createdAt,
  });
}

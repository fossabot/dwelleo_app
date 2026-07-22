import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point.dart';
import '../../../../core/domain/entities/media_image.dart';
import '../../../../core/domain/entities/named_ref.dart';

// Shared value objects (MediaImage, NamedRef, GeoPoint) moved to core/ when the
// home feature started using them too. Re-exported so existing imports of this
// file keep resolving them unchanged.
export '../../../../core/domain/entities/geo_point.dart';
export '../../../../core/domain/entities/media_image.dart';
export '../../../../core/domain/entities/named_ref.dart';

/// `listing_type`: `{key, label}` — key is stable (`for-sale`/`for-rent`),
/// label is localized by `Accept-Language`.
class ListingType extends Equatable {
  final String key;
  final String label;

  const ListingType({required this.key, required this.label});

  bool get isForSale => key == 'for-sale';
  bool get isForRent => key == 'for-rent';

  @override
  List<Object?> get props => [key, label];
}

/// The listing owner (developer / broker / agent / individual_broker).
class PropertyOwner extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? userType;
  final bool verified;
  final MediaImage? image;

  const PropertyOwner({
    required this.id,
    required this.name,
    this.phone,
    this.userType,
    this.verified = false,
    this.image,
  });

  @override
  List<Object?> get props => [id, name, phone, userType, verified, image];
}

class Amenity extends Equatable {
  final int id;
  final String title;
  final MediaImage? icon;

  const Amenity({required this.id, required this.title, this.icon});

  @override
  List<Object?> get props => [id, title, icon];
}

class PropertyTag extends Equatable {
  final int id;
  final String title;
  final String? color;

  const PropertyTag({required this.id, required this.title, this.color});

  @override
  List<Object?> get props => [id, title, color];
}

/// A nearby place returned in the detail payload's `spots` array.
class PropertySpot extends Equatable {
  final int id;
  final String name;
  final String? category;
  final String? distance;
  final String? commuteTime;
  final double? lat;
  final double? lng;
  final bool isAiSuggested;

  const PropertySpot({
    required this.id,
    required this.name,
    this.category,
    this.distance,
    this.commuteTime,
    this.lat,
    this.lng,
    this.isAiSuggested = false,
  });

  bool get hasPoint => lat != null && lng != null;

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    distance,
    commuteTime,
    lat,
    lng,
    isAiSuggested,
  ];
}

class PropertyLocation extends Equatable {
  final String? address;
  final GeoPoint? point;
  final String? adLicenseNumber;
  final String? direction;
  final String? buildingYear;

  const PropertyLocation({
    this.address,
    this.point,
    this.adLicenseNumber,
    this.direction,
    this.buildingYear,
  });

  @override
  List<Object?> get props => [
    address,
    point,
    adLicenseNumber,
    direction,
    buildingYear,
  ];
}

/// Core domain entity for a Dwelleo property listing.
/// Fields mirror the verified real API schema (see docs/api/REAL_API_SPEC.md).
class Property extends Equatable {
  final int id;
  final String slug;
  final String title;
  final String? description;
  final num? price;

  final ListingType? listingType;
  final NamedRef? propertyType;

  final int? bedrooms;
  final int? bathrooms;
  final num? areaSqm;
  final int? floorNumber;
  final int? maidRoom;
  final int? driverRoom;

  final String? furnishingStatus;
  final String? availabilityStatus;
  final String? landType;

  final bool isFeatured;
  final bool isFavorite;
  final bool isBoosted;

  final MediaImage? coverImage;
  final List<MediaImage> images;

  /// Gallery size as published by the API (`number_of_images`) — powers the
  /// site's photo-count badge on list cards.
  final int? photoCount;

  final NamedRef? region;
  final NamedRef? city;
  final NamedRef? area;

  final PropertyOwner? owner;
  final PropertyLocation? location;

  /// Nearby points of interest — the pins the website drops around the
  /// property on its Location map. VERIFIED keys (2026-07-21):
  /// `{id, name, address, category, distance, commute_time, lat, lng,
  /// is_ai_suggested}`.
  final List<PropertySpot> spots;

  final List<Amenity> amenities;
  final List<PropertyTag> tags;

  final String? handoverDate;

  // ── AI insights (VERIFIED public payload, probed 2026-07-21):
  //    price_prediction / investment_scores (bilingual reasons) /
  //    lifestyle_score / roi. Null when the API omits them. ──────────────────
  final PricePrediction? pricePrediction;
  final InvestmentScores? investmentScores;
  final LifestyleScore? lifestyleScore;
  final num? roi;

  const Property({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.price,
    this.listingType,
    this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.areaSqm,
    this.floorNumber,
    this.maidRoom,
    this.driverRoom,
    this.furnishingStatus,
    this.availabilityStatus,
    this.landType,
    this.isFeatured = false,
    this.isFavorite = false,
    this.isBoosted = false,
    this.coverImage,
    this.images = const [],
    this.photoCount,
    this.region,
    this.city,
    this.area,
    this.owner,
    this.location,
    this.spots = const [],
    this.amenities = const [],
    this.tags = const [],
    this.handoverDate,
    this.pricePrediction,
    this.investmentScores,
    this.lifestyleScore,
    this.roi,
  });

  String? get cityName => city?.name ?? region?.name;
  bool get hasMaidRoom => (maidRoom ?? 0) > 0;
  bool get hasDriverRoom => (driverRoom ?? 0) > 0;

  /// Gallery images with the cover first and NO duplicates. The API's `images`
  /// array already contains the cover, so naively prepending [coverImage]
  /// showed the first photo twice — this dedupes by [MediaImage.path], keeping
  /// first occurrence. Domain logic (kept out of the widget layer so it is
  /// testable and reused wherever the gallery renders).
  List<MediaImage> get galleryImages {
    final seen = <String>{};
    return [
      for (final img in [?coverImage, ...images])
        if (seen.add(img.path)) img,
    ];
  }

  @override
  List<Object?> get props => [
    id,
    slug,
    title,
    description,
    price,
    listingType,
    propertyType,
    bedrooms,
    bathrooms,
    areaSqm,
    floorNumber,
    maidRoom,
    driverRoom,
    furnishingStatus,
    availabilityStatus,
    landType,
    isFeatured,
    isFavorite,
    isBoosted,
    coverImage,
    images,
    photoCount,
    region,
    city,
    area,
    owner,
    location,
    spots,
    amenities,
    tags,
    handoverDate,
    pricePrediction,
    investmentScores,
    lifestyleScore,
    roi,
  ];
}

/// `price_prediction {min_price, mid_price, max_price, predicted_price}`.
class PricePrediction {
  final num? min;
  final num? mid;
  final num? max;
  final num? predicted;

  const PricePrediction({this.min, this.mid, this.max, this.predicted});

  bool get hasAny =>
      min != null || mid != null || max != null || predicted != null;

  /// Whether this prediction is worth a card.
  ///
  /// A predicted price alone IS presentable — the card gives it context by
  /// comparing it to the asking price (exactly what the website does; its
  /// "Our AI rates this price" band is derived from predicted-vs-asking, and
  /// it shows for listings whose min/max range is null too). The numeric
  /// range bar is an extra that appears only when min/max are present.
  bool get isPresentable => predicted != null;

  /// True when the full min–max range is available (richer UI).
  bool get hasRange => min != null && max != null && (max! > min!);
}

/// One bilingual explanation from `investment_scores.reasons` — the API
/// ships BOTH languages, so language switching never refetches.
class ScoreReason {
  final String key;
  final String en;
  final String ar;

  const ScoreReason({required this.key, required this.en, required this.ar});

  String forArabic(bool arabic) =>
      arabic ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
}

/// `investment_scores` — ML composite (0–100) + four factor scores.
class InvestmentScores {
  final double total;
  final double valueVsMarket;
  final double locationQuality;
  final double incomeReturn;
  final double marketSaturation;
  final String? benchmarkLevel;
  final List<ScoreReason> reasons;

  const InvestmentScores({
    required this.total,
    required this.valueVsMarket,
    required this.locationQuality,
    required this.incomeReturn,
    required this.marketSaturation,
    this.benchmarkLevel,
    this.reasons = const [],
  });

  ScoreReason? reason(String key) {
    for (final r in reasons) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// `lifestyle_score.scores` — 0–100 per metric + `lifestyle_total`.
class LifestyleScore {
  final double total;

  /// Keys as served: walkability, busy, wellness, noise, bikeability,
  /// transport (unknown future keys pass through untouched).
  final Map<String, double> metrics;

  const LifestyleScore({required this.total, required this.metrics});
}

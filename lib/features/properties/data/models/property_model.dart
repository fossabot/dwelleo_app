import '../../../../core/data/models/shared_models.dart';
import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/page_info.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_page.dart';

/// Maps the verified real Dwelleo JSON (see docs/api/REAL_API_SPEC.md) into
/// domain [Property] entities. All parsing is null-tolerant and type-tolerant
/// (API numbers occasionally arrive as strings).
abstract final class PropertyModel {
  /// Parse the list envelope `{data:{properties:[...]}}` into entities.
  static List<Property> listFromEnvelope(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final raw = data?['properties'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  /// Parse a paginated-search envelope `{data:{properties:[...],
  /// pagination:{...}}}` (present whenever `page` is sent — verified live).
  static PropertyPage pageFromEnvelope(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final pag = _asMap(data?['pagination']);
    return PropertyPage(
      properties: listFromEnvelope(json),
      pageInfo: pag == null
          ? null
          : PageInfo(
              total: _toInt(pag['total']) ?? 0,
              count: _toInt(pag['count']) ?? 0,
              perPage: _toInt(pag['per_page']) ?? 20,
              currentPage: _toInt(pag['current_page']) ?? 1,
              totalPages: _toInt(pag['total_pages']) ?? 1,
            ),
    );
  }

  /// Parse the detail envelope. Tolerates `{data:{...}}` or `{data:{property:{...}}}`.
  static Property detailFromEnvelope(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;
    final inner = _asMap(data['property']) ?? data;
    return fromJson(inner);
  }

  static Property fromJson(Map<String, dynamic> j) {
    return Property(
      id: _toInt(j['id']) ?? 0,
      slug: (j['slug'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: j['description']?.toString(),
      price: _toNum(j['price']),
      listingType: _listingType(j['listing_type']),
      propertyType: _namedRef(j['property_type']),
      bedrooms: _toInt(j['bedrooms']),
      bathrooms: _toInt(j['bathrooms']),
      areaSqm: _toNum(j['area_sqm']),
      floorNumber: _toInt(j['floor_number']),
      maidRoom: _toInt(j['maid_room']),
      driverRoom: _toInt(j['driver_room']),
      furnishingStatus: j['furnishing_status']?.toString(),
      availabilityStatus: j['availability_status']?.toString(),
      landType: j['land_type']?.toString(),
      isFeatured: _toBool(j['is_featured']),
      isFavorite: _toBool(j['is_favorite']),
      isBoosted: _toBool(j['is_boosted']),
      coverImage: _image(j['image']),
      images: _imageList(j['images']),
      photoCount: JsonParse.toInt(j['number_of_images']),
      region: _namedRef(j['region']),
      city: _namedRef(j['city']),
      area: _namedRef(j['area']),
      owner: _owner(j['owner']),
      location: _location(j['location']),
      spots: _spots(j['spots']),
      amenities: _amenities(j['amenities']),
      tags: _tags(j['tags']),
      handoverDate: j['handover_date']?.toString(),
      pricePrediction: _pricePrediction(j['price_prediction']),
      investmentScores: _investmentScores(j['investment_scores']),
      lifestyleScore: _lifestyleScore(j['lifestyle_score']),
      roi: _toNum(j['roi']),
    );
  }

  // ── nested parsers ─────────────────────────────────────────────────────────

  static PricePrediction? _pricePrediction(dynamic v) {
    if (v is! Map) return null;
    final p = PricePrediction(
      min: _toNum(v['min_price']),
      mid: _toNum(v['mid_price']),
      max: _toNum(v['max_price']),
      predicted: _toNum(v['predicted_price']),
    );
    return p.hasAny ? p : null;
  }

  static InvestmentScores? _investmentScores(dynamic v) {
    if (v is! Map) return null;
    final total = _toNum(v['total_score'])?.toDouble();
    if (total == null) return null;
    final reasons = <ScoreReason>[];
    final raw = v['reasons'];
    if (raw is Map) {
      for (final e in raw.entries) {
        final val = e.value;
        if (val is Map) {
          reasons.add(
            ScoreReason(
              key: '${e.key}',
              en: '${val['en'] ?? ''}',
              ar: '${val['ar'] ?? ''}',
            ),
          );
        }
      }
    }
    return InvestmentScores(
      total: total,
      valueVsMarket: _toNum(v['value_vs_market_score'])?.toDouble() ?? 0,
      locationQuality: _toNum(v['location_quality_score'])?.toDouble() ?? 0,
      incomeReturn: _toNum(v['income_return_score'])?.toDouble() ?? 0,
      marketSaturation: _toNum(v['market_saturation_score'])?.toDouble() ?? 0,
      benchmarkLevel: v['benchmark_level']?.toString(),
      reasons: List.unmodifiable(reasons),
    );
  }

  static LifestyleScore? _lifestyleScore(dynamic v) {
    if (v is! Map) return null;
    final scores = v['scores'];
    if (scores is! Map) return null;
    final total = _toNum(scores['lifestyle_total'])?.toDouble();
    if (total == null) return null;
    final metrics = <String, double>{};
    for (final e in scores.entries) {
      final value = _toNum(e.value)?.toDouble();
      if (e.key != 'lifestyle_total' && value != null) {
        metrics['${e.key}'] = value;
      }
    }
    return LifestyleScore(total: total, metrics: Map.unmodifiable(metrics));
  }

  static MediaImage? _image(dynamic v) => MediaImageModel.fromJson(v);

  static List<MediaImage> _imageList(dynamic v) {
    if (v is! List) return const [];
    return v.map(_image).whereType<MediaImage>().toList(growable: false);
  }

  static ListingType? _listingType(dynamic v) {
    final m = _asMap(v);
    if (m == null) return null;
    final key = m['key']?.toString();
    if (key == null || key.isEmpty) return null;
    return ListingType(key: key, label: (m['label'] ?? key).toString());
  }

  static NamedRef? _namedRef(dynamic v) => NamedRefModel.fromJson(v);

  static PropertyOwner? _owner(dynamic v) {
    final m = _asMap(v);
    if (m == null) return null;
    return PropertyOwner(
      id: _toInt(m['id']) ?? 0,
      name: (m['name'] ?? '').toString(),
      phone: m['phone']?.toString(),
      userType: m['user_type']?.toString(),
      verified: _toBool(m['verified']),
      image: _image(m['image']),
    );
  }

  static List<PropertySpot> _spots(dynamic v) {
    if (v is! List) return const [];
    final out = <PropertySpot>[];
    for (final item in v) {
      if (item is! Map) continue;
      final id = _toInt(item['id']);
      final name = '${item['name'] ?? ''}'.trim();
      if (id == null || name.isEmpty) continue;
      out.add(
        PropertySpot(
          id: id,
          name: name,
          category: item['category']?.toString(),
          distance: item['distance']?.toString(),
          commuteTime: item['commute_time']?.toString(),
          lat: _toDouble(item['lat']),
          lng: _toDouble(item['lng']),
          isAiSuggested: item['is_ai_suggested'] == true,
        ),
      );
    }
    return List.unmodifiable(out);
  }

  static PropertyLocation? _location(dynamic v) {
    final m = _asMap(v);
    if (m == null) return null;
    return PropertyLocation(
      address: m['address']?.toString(),
      point: GeoPoint(lat: _toDouble(m['lat']), lng: _toDouble(m['lng'])),
      adLicenseNumber: m['ad_license_number']?.toString(),
      direction: m['direction']?.toString(),
      buildingYear: m['building_year']?.toString(),
    );
  }

  static List<Amenity> _amenities(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map((m) {
          return Amenity(
            id: _toInt(m['id']) ?? 0,
            title: (m['title'] ?? m['name'] ?? '').toString(),
            icon: _image(m['image']) ?? _image(m['icon']),
          );
        })
        .toList(growable: false);
  }

  static List<PropertyTag> _tags(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map((m) {
          return PropertyTag(
            id: _toInt(m['id']) ?? 0,
            title: (m['title'] ?? m['name'] ?? '').toString(),
            color: m['color']?.toString(),
          );
        })
        .toList(growable: false);
  }

  // ── primitive coercion (shared, see core/utils/json_parse.dart) ────────────

  static Map<String, dynamic>? _asMap(dynamic v) => JsonParse.asMap(v);
  static int? _toInt(dynamic v) => JsonParse.toInt(v);
  static num? _toNum(dynamic v) => JsonParse.toNum(v);
  static double? _toDouble(dynamic v) => JsonParse.toDouble(v);
  static bool _toBool(dynamic v) => JsonParse.toBool(v);
}

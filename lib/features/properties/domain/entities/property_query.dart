import 'package:equatable/equatable.dart';

/// Domain-level search criteria for the property list.
/// Maps to the real Spatie `filter[...]` params in the data layer
/// (see PropertyFilters in lib/core/constants/api_endpoints.dart).
class PropertyQuery extends Equatable {
  /// `for-sale` | `for-rent`.
  final String? listingType;
  final int? propertyTypeId;
  final int? cityId;
  final int? areaId;
  final int? regionId;
  final int? developerId;
  final int? minBedrooms;
  final int? minBathrooms;
  final num? minPrice;
  final num? maxPrice;

  /// Built area in m² → real `filter[from_area]` / `filter[to_area]`.
  final num? minArea;
  final num? maxArea;
  final String? furnishingStatus;
  final bool? onlyFavorites;

  /// `created_at` (asc) or `-created_at` (desc).
  final String sort;
  final int page;

  const PropertyQuery({
    this.listingType,
    this.propertyTypeId,
    this.cityId,
    this.areaId,
    this.regionId,
    this.developerId,
    this.minBedrooms,
    this.minBathrooms,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.furnishingStatus,
    this.onlyFavorites,
    this.sort = '-created_at',
    this.page = 1,
  });

  PropertyQuery copyWith({
    String? listingType,
    int? propertyTypeId,
    int? cityId,
    int? areaId,
    int? regionId,
    int? developerId,
    int? minBedrooms,
    int? minBathrooms,
    num? minPrice,
    num? maxPrice,
    num? minArea,
    num? maxArea,
    String? furnishingStatus,
    bool? onlyFavorites,
    String? sort,
    int? page,
  }) {
    return PropertyQuery(
      listingType: listingType ?? this.listingType,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      cityId: cityId ?? this.cityId,
      areaId: areaId ?? this.areaId,
      regionId: regionId ?? this.regionId,
      developerId: developerId ?? this.developerId,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      sort: sort ?? this.sort,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [
    listingType,
    propertyTypeId,
    cityId,
    areaId,
    regionId,
    developerId,
    minBedrooms,
    minBathrooms,
    minPrice,
    maxPrice,
    minArea,
    maxArea,
    furnishingStatus,
    onlyFavorites,
    sort,
    page,
  ];
}

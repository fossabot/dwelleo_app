import 'package:equatable/equatable.dart';

/// Domain-level search criteria for the property list.
/// Maps to the real Spatie `filter[...]` params in the data layer
/// (see PropertyFilters in lib/core/constants/api_endpoints.dart).
///
/// CONTRACT (re-verified live 2026-07-06): sending `page` switches
/// `/properties` into the paginated search (pagination envelope present);
/// `filter[property_types][]` (ARRAY syntax) filters by type — the singular
/// `filter[property_type]` is accepted but silently ignored by the backend
/// and must not be sent.
class PropertyQuery extends Equatable {
  /// `for-sale` | `for-rent`.
  final String? listingType;

  /// Property-type ids (multi-select, like the website's type menu).
  final List<int> propertyTypeIds;
  final int? cityId;
  final int? areaId;
  final int? regionId;
  final int? developerId;
  final int? minBedrooms;
  final int? minBathrooms;
  final num? minPrice;
  final num? maxPrice;
  final String? furnishingStatus;
  final bool? onlyFavorites;

  /// `created_at` (asc) or `-created_at` (desc).
  final String sort;
  final int page;

  const PropertyQuery({
    this.listingType,
    this.propertyTypeIds = const [],
    this.cityId,
    this.areaId,
    this.regionId,
    this.developerId,
    this.minBedrooms,
    this.minBathrooms,
    this.minPrice,
    this.maxPrice,
    this.furnishingStatus,
    this.onlyFavorites,
    this.sort = '-created_at',
    this.page = 1,
  });

  /// Number of user-visible filters applied (for the filter-badge count).
  int get activeFilterCount =>
      (propertyTypeIds.isEmpty ? 0 : 1) +
      (cityId == null ? 0 : 1) +
      (minBedrooms == null ? 0 : 1) +
      (minBathrooms == null ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1) +
      (furnishingStatus == null ? 0 : 1);

  /// Nullable-aware copy: pass a closure to SET (or clear with `() => null`);
  /// omit to keep the current value.
  PropertyQuery copyWith({
    String? Function()? listingType,
    List<int>? propertyTypeIds,
    int? Function()? cityId,
    int? Function()? areaId,
    int? Function()? regionId,
    int? Function()? developerId,
    int? Function()? minBedrooms,
    int? Function()? minBathrooms,
    num? Function()? minPrice,
    num? Function()? maxPrice,
    String? Function()? furnishingStatus,
    bool? Function()? onlyFavorites,
    String? sort,
    int? page,
  }) {
    return PropertyQuery(
      listingType: listingType == null ? this.listingType : listingType(),
      propertyTypeIds: propertyTypeIds ?? this.propertyTypeIds,
      cityId: cityId == null ? this.cityId : cityId(),
      areaId: areaId == null ? this.areaId : areaId(),
      regionId: regionId == null ? this.regionId : regionId(),
      developerId: developerId == null ? this.developerId : developerId(),
      minBedrooms: minBedrooms == null ? this.minBedrooms : minBedrooms(),
      minBathrooms: minBathrooms == null ? this.minBathrooms : minBathrooms(),
      minPrice: minPrice == null ? this.minPrice : minPrice(),
      maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
      furnishingStatus: furnishingStatus == null
          ? this.furnishingStatus
          : furnishingStatus(),
      onlyFavorites: onlyFavorites == null
          ? this.onlyFavorites
          : onlyFavorites(),
      sort: sort ?? this.sort,
      page: page ?? this.page,
    );
  }

  PropertyQuery withPage(int page) => copyWith(page: page);

  @override
  List<Object?> get props => [
    listingType,
    propertyTypeIds,
    cityId,
    areaId,
    regionId,
    developerId,
    minBedrooms,
    minBathrooms,
    minPrice,
    maxPrice,
    furnishingStatus,
    onlyFavorites,
    sort,
    page,
  ];
}

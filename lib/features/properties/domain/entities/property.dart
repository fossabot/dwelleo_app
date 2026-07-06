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

  final NamedRef? region;
  final NamedRef? city;
  final NamedRef? area;

  final PropertyOwner? owner;
  final PropertyLocation? location;

  final List<Amenity> amenities;
  final List<PropertyTag> tags;

  final String? handoverDate;

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
    this.region,
    this.city,
    this.area,
    this.owner,
    this.location,
    this.amenities = const [],
    this.tags = const [],
    this.handoverDate,
  });

  String? get cityName => city?.name ?? region?.name;
  bool get hasMaidRoom => (maidRoom ?? 0) > 0;
  bool get hasDriverRoom => (driverRoom ?? 0) > 0;

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
    region,
    city,
    area,
    owner,
    location,
    amenities,
    tags,
    handoverDate,
  ];
}

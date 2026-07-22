import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point.dart';
import '../../../../core/domain/entities/media_image.dart';
import '../../../../core/domain/entities/named_ref.dart';

/// The developer attached to a project list item
/// (`{id, name, phone, whatsapp, image, is_verified}` per REAL_API_SPEC §2).
class ProjectDeveloper extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? whatsapp;
  final MediaImage? image;
  final bool isVerified;

  const ProjectDeveloper({
    required this.id,
    required this.name,
    this.phone,
    this.whatsapp,
    this.image,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [id, name, phone, whatsapp, image, isVerified];
}

/// An off-plan development project (`GET /api/v1/projects`, REAL_API_SPEC §2).
/// Note: projects carry `name` (not `title`) and `starting_price`.
class Project extends Equatable {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final MediaImage? image;
  final NamedRef? city;
  final String? locationLabel;
  final GeoPoint? coordinates;
  final num? startingPrice;
  final bool isOffPlan;
  final bool isFavorite;
  final String? launchDate;
  final String? expectedHandoverDate;
  final ProjectDeveloper? developer;

  // Detail-page fields (VERIFIED on GET /projects/{id}, probed 2026-07-22).
  final String? overviewDescription;
  final List<String> keyFeatures;
  final List<String> amenityNames;

  const Project({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.image,
    this.city,
    this.locationLabel,
    this.coordinates,
    this.startingPrice,
    this.isOffPlan = false,
    this.isFavorite = false,
    this.launchDate,
    this.expectedHandoverDate,
    this.developer,
    this.overviewDescription,
    this.keyFeatures = const [],
    this.amenityNames = const [],
  });

  String? get cityName => city?.name;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    description,
    image,
    city,
    locationLabel,
    coordinates,
    startingPrice,
    isOffPlan,
    isFavorite,
    launchDate,
    expectedHandoverDate,
    developer,
  ];
}

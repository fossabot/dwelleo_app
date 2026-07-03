import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/media_image.dart';

/// A real-estate developer list item (`GET /api/v1/developers`, REAL_API_SPEC §3):
/// `{id, name, image, rating, featured, featuredInHome}`.
class Developer extends Equatable {
  final int id;
  final String name;
  final MediaImage? image;
  final num rating;
  final bool featured;

  /// The backend's own flag for the website's "Featured Developers" section.
  final bool featuredInHome;

  const Developer({
    required this.id,
    required this.name,
    this.image,
    this.rating = 0,
    this.featured = false,
    this.featuredInHome = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    image,
    rating,
    featured,
    featuredInHome,
  ];
}

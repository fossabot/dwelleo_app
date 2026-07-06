import 'package:equatable/equatable.dart';

/// A nullable-safe lat/lng pair as delivered by the API.
///
/// Lives in core because it is shared by the properties AND home features.
class GeoPoint extends Equatable {
  final double? lat;
  final double? lng;

  const GeoPoint({this.lat, this.lng});

  bool get isValid => lat != null && lng != null;

  @override
  List<Object?> get props => [lat, lng];
}

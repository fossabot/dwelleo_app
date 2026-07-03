import 'package:equatable/equatable.dart';

/// A localized reference object (property_type, region, city, area, …).
/// `name`/`title` come pre-resolved for the requested `Accept-Language`.
///
/// Lives in core because it is shared by the properties AND home features.
class NamedRef extends Equatable {
  final int id;
  final String name;

  const NamedRef({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

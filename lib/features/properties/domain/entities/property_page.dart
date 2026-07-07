import 'page_info.dart';
import 'property.dart';

/// One page of paginated search results (`/properties?page=N`).
class PropertyPage {
  final List<Property> properties;
  final PageInfo? pageInfo;

  const PropertyPage({required this.properties, this.pageInfo});
}

/// One entry of the site's type-count strip ("Apartment · 2321").
///
/// A plain domain value object: a property type paired with how many live
/// listings match it, sourced from the search endpoint's `pagination.total`.
class TypeCount {
  final int typeId;
  final String name;
  final int total;

  const TypeCount({
    required this.typeId,
    required this.name,
    required this.total,
  });
}

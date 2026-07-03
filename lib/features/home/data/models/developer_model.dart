import '../../../../core/data/models/shared_models.dart';
import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/developer.dart';

/// Maps the verified `/api/v1/developers` JSON (REAL_API_SPEC §3) into domain
/// [Developer] entities.
abstract final class DeveloperModel {
  /// Parse the list envelope `{message, data:{developers:[...], pagination}}`.
  static List<Developer> listFromEnvelope(Map<String, dynamic> json) {
    final data = JsonParse.asMap(json['data']);
    final raw = data?['developers'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  static Developer fromJson(Map<String, dynamic> j) {
    return Developer(
      id: JsonParse.toInt(j['id']) ?? 0,
      name: (j['name'] ?? '').toString().trim(),
      image: MediaImageModel.fromJson(j['image']),
      rating: JsonParse.toNum(j['rating']) ?? 0,
      featured: JsonParse.toBool(j['featured']),
      featuredInHome: JsonParse.toBool(j['featuredInHome']),
    );
  }
}

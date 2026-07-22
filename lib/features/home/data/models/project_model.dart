import '../../../../core/data/models/shared_models.dart';
import '../../../../core/domain/entities/geo_point.dart';
import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/project.dart';

/// Maps the verified `/api/v1/projects` JSON (REAL_API_SPEC §2) into domain
/// [Project] entities. Null-and-type tolerant like the rest of the data layer.
abstract final class ProjectModel {
  /// Parse the list envelope `{message, data:{projects:[...]}}`.
  static List<Project> listFromEnvelope(Map<String, dynamic> json) {
    final data = JsonParse.asMap(json['data']);
    final raw = data?['projects'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  /// GET /projects/{id} → `{data:{project:{...}}}` or `{data:{...}}`.
  static Project? detailFromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) return null;
    final node = data['project'] is Map ? data['project'] : data;
    return fromJson(Map<String, dynamic>.from(node as Map));
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v
        .map((e) {
          if (e is String) return e;
          if (e is Map) return '${e['title'] ?? e['name'] ?? ''}';
          return '';
        })
        .where((t) => t.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Project fromJson(Map<String, dynamic> j) {
    final coords = JsonParse.asMap(j['location_coordinates']);
    return Project(
      id: JsonParse.toInt(j['id']) ?? 0,
      slug: (j['slug'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      image: MediaImageModel.fromJson(j['image']),
      city: NamedRefModel.fromJson(j['city']),
      locationLabel: j['location']?.toString(),
      coordinates: coords == null
          ? null
          : GeoPoint(
              lat: JsonParse.toDouble(coords['lat']),
              lng: JsonParse.toDouble(coords['lng']),
            ),
      startingPrice: JsonParse.toNum(j['starting_price']),
      isOffPlan: JsonParse.toBool(j['is_off_plan']),
      isFavorite: JsonParse.toBool(j['is_favorite']),
      launchDate: j['launch_date']?.toString(),
      expectedHandoverDate: j['expected_handover_date']?.toString(),
      developer: _developer(j['developer']),
      overviewDescription: (j['overview_description'] ?? j['description'])
          ?.toString(),
      keyFeatures: _stringList(j['key_features']),
      amenityNames: _stringList(j['amenities']),
    );
  }

  static ProjectDeveloper? _developer(dynamic v) {
    final m = JsonParse.asMap(v);
    if (m == null) return null;
    return ProjectDeveloper(
      id: JsonParse.toInt(m['id']) ?? 0,
      name: (m['name'] ?? '').toString(),
      phone: m['phone']?.toString(),
      whatsapp: m['whatsapp']?.toString(),
      image: MediaImageModel.fromJson(m['image']),
      isVerified: JsonParse.toBool(m['is_verified']),
    );
  }
}

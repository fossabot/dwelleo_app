import '../../domain/entities/media_image.dart';
import '../../domain/entities/named_ref.dart';
import '../../utils/json_parse.dart';

/// JSON parsers for the shared value objects used across features
/// (properties, projects, developers all carry the same shapes).
abstract final class MediaImageModel {
  /// `{id, path, path_thumbnail, mime_type}` → [MediaImage]; null when the
  /// object is missing or has no usable `path`.
  static MediaImage? fromJson(dynamic v) {
    final m = JsonParse.asMap(v);
    if (m == null) return null;
    final path = m['path']?.toString();
    if (path == null || path.isEmpty) return null;
    return MediaImage(
      id: JsonParse.toInt(m['id']) ?? 0,
      path: path,
      thumbnail: m['path_thumbnail']?.toString(),
      mimeType: m['mime_type']?.toString(),
    );
  }
}

abstract final class NamedRefModel {
  /// Localized reference `{id, name|title, …}` → [NamedRef]; null when the
  /// object carries neither an id nor a name.
  static NamedRef? fromJson(dynamic v) {
    final m = JsonParse.asMap(v);
    if (m == null) return null;
    final id = JsonParse.toInt(m['id']);
    final name = (m['name'] ?? m['title'] ?? '').toString();
    if (id == null && name.isEmpty) return null;
    return NamedRef(id: id ?? 0, name: name);
  }
}

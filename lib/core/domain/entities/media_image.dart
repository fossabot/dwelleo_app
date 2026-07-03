import 'package:equatable/equatable.dart';

/// A media object as returned by the API: `{id, path, path_thumbnail, mime_type}`.
/// `path`/`thumbnail` are absolute S3 URLs.
///
/// Lives in core because it is shared by the properties AND home features
/// (properties, projects, developers all carry the same image envelope).
class MediaImage extends Equatable {
  final int id;
  final String path;
  final String? thumbnail;
  final String? mimeType;

  const MediaImage({
    required this.id,
    required this.path,
    this.thumbnail,
    this.mimeType,
  });

  /// Best URL for a small/list context, falling back to the full path.
  String get displayThumb => thumbnail?.isNotEmpty == true ? thumbnail! : path;

  @override
  List<Object?> get props => [id, path, thumbnail, mimeType];
}

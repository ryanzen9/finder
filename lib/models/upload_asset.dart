enum UploadSource { camera, gallery, file }

class CachedUpload {
  final String id;
  final String name;
  final String path;
  final UploadSource source;
  final DateTime createdAt;

  const CachedUpload({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    required this.createdAt,
  });
}

enum UploadSource { camera, gallery, file }
enum SyncStatus { pending, synced, failed }

class CachedUpload {
  final String id;
  final String name;
  final String path;
  final UploadSource source;
  final DateTime createdAt;

  final String brand;
  final String category;
  final String description;
  final String nickname;
  final SyncStatus syncStatus;
  final String? syncMessage;

  const CachedUpload({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    required this.createdAt,
    this.brand = '',
    this.category = '',
    this.description = '',
    this.nickname = '',
    this.syncStatus = SyncStatus.pending,
    this.syncMessage,
  });

  CachedUpload copyWith({
    String? id,
    String? name,
    String? path,
    UploadSource? source,
    DateTime? createdAt,
    String? brand,
    String? category,
    String? description,
    String? nickname,
    SyncStatus? syncStatus,
    String? syncMessage,
  }) {
    return CachedUpload(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      description: description ?? this.description,
      nickname: nickname ?? this.nickname,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: syncMessage ?? this.syncMessage,
    );
  }
}

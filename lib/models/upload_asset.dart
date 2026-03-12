enum UploadSource { camera, gallery, file }
enum SyncStatus { pending, synced, failed }

class CachedUpload {
  final String id;
  final String name;
  final String path;
  final UploadSource source;
  final DateTime createdAt;

  final String batchId;
  final String brand;
  final String description;
  final String nickname;
  final SyncStatus syncStatus;
  final String? syncMessage;
  final bool isDraft;

  const CachedUpload({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    required this.createdAt,
    this.batchId = '',
    this.brand = '',
    this.description = '',
    this.nickname = '',
    this.syncStatus = SyncStatus.pending,
    this.syncMessage,
    this.isDraft = false,
  });

  CachedUpload copyWith({
    String? id,
    String? name,
    String? path,
    UploadSource? source,
    DateTime? createdAt,
    String? batchId,
    String? brand,
    String? description,
    String? nickname,
    SyncStatus? syncStatus,
    String? syncMessage,
    bool? isDraft,
  }) {
    return CachedUpload(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      batchId: batchId ?? this.batchId,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      nickname: nickname ?? this.nickname,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: syncMessage ?? this.syncMessage,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}

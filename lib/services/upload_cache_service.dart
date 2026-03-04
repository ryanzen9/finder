import 'dart:convert';

import 'package:finder/core/database/database_helper.dart';
import 'package:finder/models/upload_asset.dart';

class UploadCacheService {
  Future<List<CachedUpload>> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseHelper.uploadCacheTable,
      orderBy: 'updated_at DESC',
    );

    return rows
        .map((r) => _fromJson(jsonDecode((r['payload'] ?? '{}').toString()) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<CachedUpload> items) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    batch.delete(DatabaseHelper.uploadCacheTable);

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in items) {
      batch.insert(DatabaseHelper.uploadCacheTable, {
        'id': e.id,
        'payload': jsonEncode(_toJson(e)),
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Map<String, dynamic> _toJson(CachedUpload e) {
    return {
      'id': e.id,
      'name': e.name,
      'path': e.path,
      'source': e.source.name,
      'createdAt': e.createdAt.toIso8601String(),
      'brand': e.brand,
      'category': e.category,
      'description': e.description,
      'nickname': e.nickname,
      'syncStatus': e.syncStatus.name,
      'syncMessage': e.syncMessage,
      'isDraft': e.isDraft,
    };
  }

  CachedUpload _fromJson(Map<String, dynamic> json) {
    final sourceName = (json['source'] ?? 'file').toString();
    final source = UploadSource.values.firstWhere(
      (v) => v.name == sourceName,
      orElse: () => UploadSource.file,
    );

    final statusName = (json['syncStatus'] ?? 'pending').toString();
    final syncStatus = SyncStatus.values.firstWhere(
      (v) => v.name == statusName,
      orElse: () => SyncStatus.pending,
    );

    return CachedUpload(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      source: source,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      brand: (json['brand'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      syncStatus: syncStatus,
      syncMessage: json['syncMessage']?.toString(),
      isDraft: json['isDraft'] == true,
    );
  }
}

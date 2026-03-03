import 'dart:convert';

import 'package:finder/models/upload_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadCacheService {
  static const _key = 'finder.cached_uploads.v1';

  Future<List<CachedUpload>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
    return arr.map((e) => _fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<void> save(List<CachedUpload> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(_toJson).toList());
    await prefs.setString(_key, encoded);
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
    );
  }
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/utils/net/api.dart';

class UploadSyncResult {
  final bool ok;
  final String message;
  const UploadSyncResult({required this.ok, required this.message});
}

class UploadSyncService {
  const UploadSyncService();

  Future<UploadSyncResult> sync(CachedUpload upload) async {
    try {
      final file = File(upload.path);
      final form = FormData.fromMap({
        'brand': upload.brand,
        'category': upload.category,
        'description': upload.description,
        'nickname': upload.nickname,
        'source': upload.source.name,
        'createdAt': upload.createdAt.toIso8601String(),
        'file': await MultipartFile.fromFile(file.path, filename: upload.name),
      });

      await Api.post('/uploads/sync', data: form);
      return const UploadSyncResult(ok: true, message: '已同步');
    } catch (_) {
      return const UploadSyncResult(ok: false, message: '同步失败（已保存在本地）');
    }
  }
}

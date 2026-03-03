import 'dart:async';

import 'package:finder/models/upload_asset.dart';

class UploadSyncResult {
  final bool ok;
  final String message;
  const UploadSyncResult({required this.ok, required this.message});
}

class UploadSyncService {
  const UploadSyncService();

  Future<UploadSyncResult> sync(CachedUpload upload) async {
    // 模拟远程同步成功（后续接真实 API 时替换）
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const UploadSyncResult(ok: true, message: '上传成功');
  }
}

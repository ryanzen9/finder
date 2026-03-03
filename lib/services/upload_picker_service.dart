import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:image_picker/image_picker.dart';

class UploadPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<CachedUpload?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file == null) return null;
    return _toUpload(file.path, file.name, UploadSource.camera);
  }

  Future<List<CachedUpload>> pickMultiFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 92);
    if (files.isEmpty) return [];
    return files.map((f) => _toUpload(f.path, f.name, UploadSource.gallery)).toList();
  }

  Future<List<CachedUpload>> pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
    if (result == null || result.files.isEmpty) return [];

    return result.files
        .where((f) => (f.path ?? '').isNotEmpty)
        .map((f) => _toUpload(f.path!, f.name.isNotEmpty ? f.name : 'unknown', UploadSource.file))
        .toList();
  }

  CachedUpload _toUpload(String path, String name, UploadSource source) {
    return CachedUpload(
      id: '${DateTime.now().microsecondsSinceEpoch}-${name.hashCode}',
      name: name,
      path: path,
      source: source,
      createdAt: DateTime.now(),
    );
  }

  bool exists(CachedUpload upload) {
    if (upload.path.isEmpty) return false;
    return File(upload.path).existsSync();
  }
}

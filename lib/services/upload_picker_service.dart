import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:image_picker/image_picker.dart';

class UploadPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<CachedUpload?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (file == null) return null;
    return CachedUpload(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      path: file.path,
      source: UploadSource.camera,
      createdAt: DateTime.now(),
    );
  }

  Future<CachedUpload?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (file == null) return null;
    return CachedUpload(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: file.name,
      path: file.path,
      source: UploadSource.gallery,
      createdAt: DateTime.now(),
    );
  }

  Future<CachedUpload?> pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false, withData: false);
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    final fileName = f.name.isNotEmpty ? f.name : (f.path ?? 'unknown');
    return CachedUpload(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: fileName,
      path: f.path ?? '',
      source: UploadSource.file,
      createdAt: DateTime.now(),
    );
  }

  bool exists(CachedUpload upload) {
    if (upload.path.isEmpty) return false;
    return File(upload.path).existsSync();
  }
}

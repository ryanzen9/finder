import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  Future<Directory> getImageDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(docsDir.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  Future<String> saveImage(File sourceFile) async {
    final imageDir = await getImageDirectory();
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(imageDir.path, fileName);

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourceFile.absolute.path,
        targetPath,
        quality: 82,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('图片压缩失败');
      }

      final saved = File(result.path);
      if (!await saved.exists()) {
        throw Exception('图片保存失败');
      }

      return saved.path;
    } catch (e) {
      throw Exception('saveImage failed: $e');
    }
  }

  Future<void> deleteImage(String imagePath) async {
    if (imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        throw Exception('deleteImage failed: $e');
      }
    }
  }
}

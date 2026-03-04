import 'dart:io';

import 'package:finder/core/storage/image_storage.dart';
import 'package:finder/data/datasources/photo_local_datasource.dart';
import 'package:finder/data/models/photo_model.dart';
import 'package:finder/domain/repositories/photo_repository.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoLocalDataSource _local;
  final ImageStorageService _storage;

  PhotoRepositoryImpl({
    PhotoLocalDataSource? local,
    ImageStorageService? storage,
  })  : _local = local ?? PhotoLocalDataSource(),
        _storage = storage ?? ImageStorageService();

  @override
  Future<PhotoModel> addPhoto({
    required String title,
    required File imageFile,
  }) async {
    String? savedPath;
    try {
      savedPath = await _storage.saveImage(imageFile);

      final createdAt = DateTime.now().millisecondsSinceEpoch;
      final id = await _local.insertPhoto(
        PhotoModel(
          title: title,
          imagePath: savedPath,
          createdAt: createdAt,
        ),
      );

      return PhotoModel(
        id: id,
        title: title,
        imagePath: savedPath,
        createdAt: createdAt,
      );
    } catch (e) {
      if (savedPath != null) {
        try {
          await _storage.deleteImage(savedPath);
        } catch (_) {
          // Keep original error; rollback best-effort.
        }
      }
      throw Exception('addPhoto failed: $e');
    }
  }

  @override
  Future<List<PhotoModel>> getPhotos() {
    return _local.getPhotos();
  }

  @override
  Future<PhotoModel> updatePhoto({
    required int id,
    required String title,
    File? imageFile,
  }) async {
    final current = await _local.getPhotoById(id);
    if (current == null) {
      throw Exception('updatePhoto failed: photo($id) not found');
    }

    String finalPath = current.imagePath;
    String? newSavedPath;

    try {
      if (imageFile != null) {
        newSavedPath = await _storage.saveImage(imageFile);
        finalPath = newSavedPath;
      }

      final updated = current.copyWith(
        title: title,
        imagePath: finalPath,
      );

      final count = await _local.updatePhoto(updated);
      if (count == 0) {
        throw Exception('database row not updated');
      }

      if (newSavedPath != null && current.imagePath != newSavedPath) {
        try {
          await _storage.deleteImage(current.imagePath);
        } catch (_) {
          // Non-fatal; record already points to new file.
        }
      }

      return updated;
    } catch (e) {
      if (newSavedPath != null) {
        try {
          await _storage.deleteImage(newSavedPath);
        } catch (_) {}
      }
      throw Exception('updatePhoto failed: $e');
    }
  }

  @override
  Future<void> deletePhoto(int id) async {
    final current = await _local.getPhotoById(id);
    if (current == null) return;

    final count = await _local.deletePhoto(id);
    if (count == 0) {
      throw Exception('deletePhoto failed: database row not deleted');
    }

    try {
      await _storage.deleteImage(current.imagePath);
    } catch (e) {
      throw Exception('deletePhoto partial failure: db deleted but file delete failed: $e');
    }
  }
}

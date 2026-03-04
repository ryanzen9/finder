import 'dart:io';

import 'package:finder/data/models/photo_model.dart';

abstract class PhotoRepository {
  Future<PhotoModel> addPhoto({
    required String title,
    required File imageFile,
  });

  Future<List<PhotoModel>> getPhotos();

  Future<PhotoModel> updatePhoto({
    required int id,
    required String title,
    File? imageFile,
  });

  Future<void> deletePhoto(int id);
}

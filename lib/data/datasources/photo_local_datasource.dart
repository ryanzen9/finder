import 'package:finder/core/database/database_helper.dart';
import 'package:finder/data/models/photo_model.dart';

class PhotoLocalDataSource {
  final DatabaseHelper _dbHelper;

  PhotoLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertPhoto(PhotoModel photo) async {
    final db = await _dbHelper.database;
    return db.insert(
      DatabaseHelper.photosTable,
      photo.toMap()..remove('id'),
    );
  }

  Future<List<PhotoModel>> getPhotos() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.photosTable,
      orderBy: 'created_at DESC',
    );
    return maps.map(PhotoModel.fromMap).toList();
  }

  Future<PhotoModel?> getPhotoById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.photosTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PhotoModel.fromMap(maps.first);
  }

  Future<int> deletePhoto(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.photosTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePhoto(PhotoModel photo) async {
    if (photo.id == null) {
      throw ArgumentError('updatePhoto requires non-null id');
    }

    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.photosTable,
      photo.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }
}

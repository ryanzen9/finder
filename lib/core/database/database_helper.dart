import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'app.db';
  static const int _dbVersion = 2;

  static const String photosTable = 'photos';
  static const String uploadCacheTable = 'upload_cache';
  static const String manualShelfTable = 'manual_shelf';
  static const String appKvTable = 'app_kv';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createPhotosTable(db);
    await _createUploadCacheTable(db);
    await _createManualShelfTable(db);
    await _createAppKvTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUploadCacheTable(db);
      await _createManualShelfTable(db);
      await _createAppKvTable(db);
    }
  }

  Future<void> _createPhotosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $photosTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createUploadCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $uploadCacheTable (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createManualShelfTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $manualShelfTable (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createAppKvTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $appKvTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

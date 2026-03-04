import 'dart:convert';

import 'package:finder/core/database/database_helper.dart';
import 'package:finder/models/user_profile.dart';
import 'package:sqflite/sqflite.dart';

class AuthProfileCacheService {
  static const _key = 'user_profile';

  Future<UserProfile?> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseHelper.appKvTable,
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = (rows.first['value'] ?? '').toString();
    if (raw.isEmpty) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> save(UserProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      DatabaseHelper.appKvTable,
      {
        'key': _key,
        'value': jsonEncode(profile.toJson()),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      DatabaseHelper.appKvTable,
      where: 'key = ?',
      whereArgs: [_key],
    );
  }
}

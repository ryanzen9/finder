import 'package:finder/core/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AppSettingsStorageService {
  static const _themeModeKey = 'theme_mode';

  Future<ThemeMode> loadThemeMode() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseHelper.appKvTable,
      where: 'key = ?',
      whereArgs: [_themeModeKey],
      limit: 1,
    );
    if (rows.isEmpty) return ThemeMode.system;
    final raw = (rows.first['value'] ?? 'system').toString();
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      DatabaseHelper.appKvTable,
      {
        'key': _themeModeKey,
        'value': mode.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

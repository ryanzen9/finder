import 'dart:convert';

import 'package:finder/core/database/database_helper.dart';
import 'package:finder/models/manual.dart';

class ManualShelfCacheService {
  Future<List<ManualItem>> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      DatabaseHelper.manualShelfTable,
      orderBy: 'updated_at DESC',
    );

    return rows
        .map((r) => ManualItem.fromJson(jsonDecode((r['payload'] ?? '{}').toString()) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<ManualItem> items) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    batch.delete(DatabaseHelper.manualShelfTable);

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final e in items) {
      batch.insert(DatabaseHelper.manualShelfTable, {
        'id': e.id,
        'payload': jsonEncode(e.toJson()),
        'updated_at': now,
      });
    }

    await batch.commit(noResult: true);
  }
}

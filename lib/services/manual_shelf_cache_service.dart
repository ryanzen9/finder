import 'dart:convert';

import 'package:finder/models/manual.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManualShelfCacheService {
  static const _key = 'finder.manual.shelf.local.v1';

  Future<List<ManualItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final arr = jsonDecode(raw) as List<dynamic>;
    return arr
        .map((e) => ManualItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(List<ManualItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}

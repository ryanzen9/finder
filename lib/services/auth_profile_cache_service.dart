import 'dart:convert';

import 'package:finder/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProfileCacheService {
  static const _key = 'finder.user.profile.v1';

  Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

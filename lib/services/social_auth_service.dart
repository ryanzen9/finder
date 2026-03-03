import 'package:finder/app/config.dart';
import 'package:finder/models/user_profile.dart';
import 'package:finder/utils/net/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialAuthService {
  Future<void> ensureInitialized() async {
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: Config.supabaseUrl,
        anonKey: Config.supabaseAnonKey,
      );
    }
  }

  Future<UserProfile?> signInWithGoogle() async {
    await ensureInitialized();
    final client = Supabase.instance.client;
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      authScreenLaunchMode: LaunchMode.inAppWebView,
      redirectTo: 'io.supabase.flutter://login-callback/',
      queryParams: const {'access_type': 'offline', 'prompt': 'consent'},
    );
    final user = client.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user, 'google');
  }

  Future<UserProfile?> signInWithApple() async {
    await ensureInitialized();
    final client = Supabase.instance.client;
    await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      authScreenLaunchMode: LaunchMode.inAppWebView,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
    final user = client.auth.currentUser;
    if (user == null) return null;
    return _mapUser(user, 'apple');
  }

  Future<void> syncProfileToBackend(UserProfile profile) async {
    // 后端接口结构先定义，服务端后续补齐实现
    await Api.post('/auth/profile/sync', data: profile.toJson());
  }

  UserProfile _mapUser(User user, String provider) {
    final meta = user.userMetadata ?? {};
    final nickname = (meta['full_name'] ?? meta['name'] ?? user.email ?? 'User').toString();
    final avatar = (meta['avatar_url'] ?? meta['picture'])?.toString();
    return UserProfile(
      id: user.id,
      nickname: nickname,
      avatarUrl: avatar,
      provider: provider,
    );
  }
}

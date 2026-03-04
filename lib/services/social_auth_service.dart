import 'dart:io';

import 'package:finder/models/user_profile.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  bool _isIosSimulator() {
    if (!Platform.isIOS) return false;
    final env = Platform.environment;
    return env.containsKey('SIMULATOR_DEVICE_NAME') ||
        env.containsKey('IPHONE_SIMULATOR_ROOT') ||
        env.containsKey('SIMULATOR_ROOT');
  }


  Future<UserProfile?> signInWithGoogle() async {
    if (_isIosSimulator()) {
      throw Exception('iOS 模拟器不支持完整 Google 登录，请在真机测试或先配置 iOS Client ID / URL Scheme');
    }
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    return UserProfile(
      id: account.id,
      nickname: account.displayName ?? account.email,
      avatarUrl: account.photoUrl,
      provider: 'google',
    );
  }

  Future<UserProfile?> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw Exception('Apple 登录仅支持 iOS/macOS');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final name = [credential.givenName, credential.familyName]
        .where((e) => (e ?? '').isNotEmpty)
        .join(' ')
        .trim();

    return UserProfile(
      id: credential.userIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nickname: name.isNotEmpty ? name : (credential.email ?? 'Apple User'),
      avatarUrl: null,
      provider: 'apple',
    );
  }

  Future<void> syncProfileToBackend(UserProfile profile) async {
    // mock API: later replace with real endpoint integration
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

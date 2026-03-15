import 'dart:convert';
import 'dart:io';

import 'package:finder/models/user_profile.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  static const String _googleDiscoveryUrl = 'https://accounts.google.com/.well-known/openid-configuration';
  static const String _googleClientId = String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  static const String _googleRedirectUri = String.fromEnvironment('GOOGLE_OAUTH_REDIRECT_URI');

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
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

    if (_googleClientId.isNotEmpty && _googleRedirectUri.isNotEmpty) {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _googleClientId,
          _googleRedirectUri,
          discoveryUrl: _googleDiscoveryUrl,
          scopes: const ['openid', 'email', 'profile'],
          promptValues: const ['consent', 'select_account'],
        ),
      );

      final payload = _parseIdTokenPayload(result?.idToken);
      if (payload == null) {
        throw Exception('Google 登录成功但未拿到用户信息（id_token）');
      }

      final id = (payload['sub'] ?? '').toString();
      final name = (payload['name'] ?? payload['email'] ?? 'Google User').toString();
      final avatar = payload['picture']?.toString();
      if (id.isEmpty) {
        throw Exception('Google id_token 缺少 sub');
      }

      return UserProfile(
        id: id,
        nickname: name,
        avatarUrl: avatar,
        provider: 'google',
      );
    }

    // fallback: if appauth env is not configured yet
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

  Map<String, dynamic>? _parseIdTokenPayload(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    final parts = idToken.split('.');
    if (parts.length < 2) return null;

    final normalized = base64Url.normalize(parts[1]);
    final jsonStr = utf8.decode(base64Url.decode(normalized));
    return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
  }

  Future<void> syncProfileToBackend(UserProfile profile) async {
    // mock API: later replace with real endpoint integration
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}

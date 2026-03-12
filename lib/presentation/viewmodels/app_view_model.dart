import 'package:finder/models/manual.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/models/user_profile.dart';
import 'package:finder/services/auth_profile_cache_service.dart';
import 'package:finder/services/manual_shelf_cache_service.dart';
import 'package:finder/services/social_auth_service.dart';
import 'package:finder/services/upload_cache_service.dart';
import 'package:finder/services/upload_sync_service.dart';
import 'package:flutter/foundation.dart';

class UploadFormMeta {
  final String brand;
  final String description;
  final String nickname;

  const UploadFormMeta({
    required this.brand,
    required this.description,
    required this.nickname,
  });
}

class UploadCommitResult {
  final bool discarded;
  final int successCount;
  final int totalCount;

  const UploadCommitResult({
    required this.discarded,
    required this.successCount,
    required this.totalCount,
  });
}

class AppViewModel extends ChangeNotifier {
  final UploadCacheService _uploadCache;
  final UploadSyncService _syncService;
  final SocialAuthService _authService;
  final AuthProfileCacheService _authCache;
  final ManualShelfCacheService _manualCache;

  AppViewModel({
    UploadCacheService? uploadCache,
    UploadSyncService? syncService,
    SocialAuthService? authService,
    AuthProfileCacheService? authCache,
    ManualShelfCacheService? manualCache,
  })  : _uploadCache = uploadCache ?? UploadCacheService(),
        _syncService = syncService ?? const UploadSyncService(),
        _authService = authService ?? SocialAuthService(),
        _authCache = authCache ?? AuthProfileCacheService(),
        _manualCache = manualCache ?? ManualShelfCacheService();

  int _currentIndex = 0;
  final List<CachedUpload> _cachedUploads = [];
  final List<ManualItem> _localManuals = [];
  UserProfile? _profile;
  bool _initialized = false;

  int get currentIndex => _currentIndex;
  List<CachedUpload> get cachedUploads => List.unmodifiable(_cachedUploads);
  List<ManualItem> get localManuals => List.unmodifiable(_localManuals);
  UserProfile? get profile => _profile;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final uploads = await _uploadCache.load();
    final profile = await _authCache.load();
    final manuals = await _manualCache.load();

    _cachedUploads
      ..clear()
      ..addAll(uploads);
    _profile = profile;
    _localManuals
      ..clear()
      ..addAll(manuals);
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  Future<UserProfile?> loginByProvider(String provider) async {
    UserProfile? profile;
    if (provider == 'google') {
      profile = await _authService.signInWithGoogle();
    } else if (provider == 'apple') {
      profile = await _authService.signInWithApple();
    }
    if (profile == null) return null;

    await _authCache.save(profile);
    _profile = profile;
    notifyListeners();

    try {
      await _authService.syncProfileToBackend(profile);
    } catch (_) {}

    return profile;
  }

  Future<void> removeUploadById(String uploadId) async {
    if (uploadId.startsWith('upb-')) {
      final batchId = uploadId.substring(4);
      _cachedUploads.removeWhere((e) => e.batchId == batchId);
    } else {
      _cachedUploads.removeWhere((e) => e.id == uploadId || 'up-${e.id}' == uploadId);
    }
    await _uploadCache.save(_cachedUploads);
    notifyListeners();
  }

  Future<void> updateUploadMeta({
    required String uploadId,
    required String title,
    required String brand,
    required String description,
  }) async {
    if (uploadId.startsWith('upb-')) {
      final batchId = uploadId.substring(4);
      bool changed = false;
      for (var i = 0; i < _cachedUploads.length; i++) {
        final cur = _cachedUploads[i];
        if (cur.batchId == batchId) {
          _cachedUploads[i] = cur.copyWith(
            nickname: title,
            brand: brand,
            description: description,
            isDraft: false,
          );
          changed = true;
        }
      }
      if (!changed) return;
    } else {
      final idx = _cachedUploads.indexWhere((e) => e.id == uploadId || 'up-${e.id}' == uploadId);
      if (idx < 0) return;
      final cur = _cachedUploads[idx];
      _cachedUploads[idx] = cur.copyWith(
        nickname: title,
        brand: brand,
        description: description,
        isDraft: false,
      );
    }

    await _uploadCache.save(_cachedUploads);
    notifyListeners();
  }

  Future<void> addManualToShelf(ManualItem item) async {
    final exists = _localManuals.any((e) => e.id == item.id);
    if (exists) return;
    _localManuals.insert(0, item);
    await _manualCache.save(_localManuals);
    notifyListeners();
  }

  Future<UploadCommitResult> commitUploadForm({
    required List<CachedUpload> uploads,
    required UploadFormMeta meta,
    required bool discarded,
    required List<String> replacedDraftIds,
  }) async {
    if (discarded) {
      return const UploadCommitResult(discarded: true, successCount: 0, totalCount: 0);
    }

    if (replacedDraftIds.isNotEmpty) {
      _cachedUploads.removeWhere((e) => replacedDraftIds.contains(e.id));
    }

    final batchId = DateTime.now().millisecondsSinceEpoch.toString();
    final prepared = uploads
        .map(
          (u) => u.copyWith(
            batchId: batchId,
            brand: meta.brand,
            nickname: meta.nickname,
            description: meta.description,
            isDraft: false,
            syncStatus: SyncStatus.pending,
          ),
        )
        .toList();

    _cachedUploads.insertAll(0, prepared);
    await _uploadCache.save(_cachedUploads);

    int success = 0;
    for (final item in prepared) {
      final sync = await _syncService.sync(item);
      final next = item.copyWith(
        syncStatus: sync.ok ? SyncStatus.synced : SyncStatus.failed,
        syncMessage: sync.message,
        isDraft: !sync.ok,
      );
      final idx = _cachedUploads.indexWhere((e) => e.id == item.id);
      if (idx >= 0) _cachedUploads[idx] = next;
      if (sync.ok) success++;
    }

    await _uploadCache.save(_cachedUploads);
    notifyListeners();

    return UploadCommitResult(
      discarded: false,
      successCount: success,
      totalCount: prepared.length,
    );
  }
}

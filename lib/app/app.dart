import 'dart:io';

import 'package:finder/api/finder_api.dart';
import 'package:finder/api/finder_mock_api.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/models/user_profile.dart';
import 'package:finder/services/auth_profile_cache_service.dart';
import 'package:finder/services/social_auth_service.dart';
import 'package:finder/services/upload_cache_service.dart';
import 'package:finder/services/upload_picker_service.dart';
import 'package:finder/services/upload_sync_service.dart';
import 'package:finder/views/explore.dart';
import 'package:finder/views/library.dart';
import 'package:finder/views/settings.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final IFinderApi _api = const FinderMockApi();
  final UploadPickerService _uploadService = UploadPickerService();
  final UploadCacheService _cacheService = UploadCacheService();
  final UploadSyncService _syncService = const UploadSyncService();
  final SocialAuthService _authService = SocialAuthService();
  final AuthProfileCacheService _authCache = AuthProfileCacheService();

  final List<CachedUpload> _cachedUploads = [];
  UserProfile? _profile;
  bool _cacheReady = false;

  int get _draftCount => _cachedUploads.where((e) => e.isDraft).length;

  @override
  void initState() {
    super.initState();
    _restoreUploadCache();
    _restoreProfile();
  }

  Future<void> _restoreUploadCache() async {
    final restored = await _cacheService.load();
    if (!mounted) return;
    setState(() {
      _cachedUploads
        ..clear()
        ..addAll(restored);
      _cacheReady = true;
    });
  }

  Future<void> _restoreProfile() async {
    final profile = await _authCache.load();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _onAvatarTap() async {
    if (_profile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已登录：${_profile!.nickname}')),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('登录'), subtitle: Text('请选择登录方式')),
            ListTile(
              leading: const Icon(Icons.g_mobiledata_rounded, size: 32),
              title: const Text('使用 Google 登录'),
              subtitle: const Text('官方 Google SDK'),
              onTap: () => Navigator.pop(ctx, 'google'),
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('使用 Apple 登录'),
              subtitle: const Text('官方 Apple 登录'),
              onTap: () => Navigator.pop(ctx, 'apple'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    try {
      UserProfile? profile;
      if (action == 'google') {
        profile = await _authService.signInWithGoogle();
      } else {
        profile = await _authService.signInWithApple();
      }
      if (profile == null || !mounted) return;

      await _authCache.save(profile);
      setState(() => _profile = profile);

      try {
        await _authService.syncProfileToBackend(profile);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录成功，欢迎 ${profile.nickname}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录失败：$e')),
      );
    }
  }

  Future<void> _onScanTap() async {
    // 如果存在草稿，直接恢复最近草稿表单
    final drafts = _cachedUploads.where((e) => e.isDraft).toList();
    if (drafts.isNotEmpty) {
      drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final first = drafts.first;
      await _openUploadFormSheet(
        initials: drafts,
        replacedDraftIds: drafts.map((e) => e.id).toList(),
        initialBrand: first.brand,
        initialCategory: first.category,
        initialNickname: first.nickname,
        initialDescription: first.description,
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照上传'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('相册选择（支持多张）'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('文件上传（支持多选）'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;
    final picked = await _pickByAction(action);
    if (!mounted || picked.isEmpty) return;

    await _openUploadFormSheet(initials: picked, replacedDraftIds: const []);
  }

  Future<List<CachedUpload>> _pickByAction(String action) async {
    if (action == 'camera') {
      final one = await _uploadService.pickFromCamera();
      return one == null ? [] : [one];
    }
    if (action == 'gallery') {
      return _uploadService.pickMultiFromGallery();
    }
    return _uploadService.pickFromFiles();
  }

  Future<void> _openUploadFormSheet({
    required List<CachedUpload> initials,
    required List<String> replacedDraftIds,
    String? initialBrand,
    String? initialCategory,
    String? initialNickname,
    String? initialDescription,
  }) async {
    final result = await showModalBottomSheet<_UploadSubmitResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _UploadFormSheet(
        initials: initials,
        picker: _uploadService,
        initialBrand: initialBrand,
        initialCategory: initialCategory,
        initialNickname: initialNickname,
        initialDescription: initialDescription,
      ),
    );

    if (result == null || !mounted) return;

    if (replacedDraftIds.isNotEmpty) {
      _cachedUploads.removeWhere((e) => replacedDraftIds.contains(e.id));
    }

    final prepared = result.uploads
        .map(
          (u) => u.copyWith(
            brand: result.brand,
            category: result.category,
            nickname: result.nickname,
            description: result.description,
            isDraft: result.isDraft,
            syncStatus: SyncStatus.pending,
          ),
        )
        .toList();

    setState(() => _cachedUploads.insertAll(0, prepared));
    await _cacheService.save(_cachedUploads);

    if (result.isDraft) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存草稿（${prepared.length}）')),
      );
      return;
    }

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

    await _cacheService.save(_cachedUploads);
    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success == prepared.length ? Colors.green.shade600 : Colors.orange.shade700,
        content: Row(
          children: [
            Icon(success == prepared.length ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(success == prepared.length ? '上传成功（$success）并加入本地书架' : '部分同步失败，已转为草稿'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LibraryPage(api: _api, cachedUploads: _cachedUploads, profile: _profile, onAvatarTap: _onAvatarTap),
      ExplorePage(api: _api),
      const SettingsPage(),
    ];

    final scanLabel = !_cacheReady ? 'Scan (...)' : (_draftCount == 0 ? 'Scan' : 'Scan ($_draftCount)');

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _onScanTap,
              label: Text(scanLabel),
              icon: const Icon(Icons.camera_alt_outlined),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: '书架'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: '探索'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

class _UploadSubmitResult {
  final List<CachedUpload> uploads;
  final String brand;
  final String category;
  final String description;
  final String nickname;
  final bool isDraft;

  const _UploadSubmitResult({
    required this.uploads,
    required this.brand,
    required this.category,
    required this.description,
    required this.nickname,
    required this.isDraft,
  });
}

class _UploadFormSheet extends StatefulWidget {
  final List<CachedUpload> initials;
  final UploadPickerService picker;
  final String? initialBrand;
  final String? initialCategory;
  final String? initialDescription;
  final String? initialNickname;

  const _UploadFormSheet({
    required this.initials,
    required this.picker,
    this.initialBrand,
    this.initialCategory,
    this.initialDescription,
    this.initialNickname,
  });

  @override
  State<_UploadFormSheet> createState() => _UploadFormSheetState();
}

class _UploadFormSheetState extends State<_UploadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _nickCtrl;

  late List<CachedUpload> _uploads;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _uploads = List<CachedUpload>.from(widget.initials);
    _brandCtrl = TextEditingController(text: widget.initialBrand ?? '');
    _categoryCtrl = TextEditingController(text: widget.initialCategory ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _nickCtrl = TextEditingController(text: widget.initialNickname ?? '');

    for (final c in [_brandCtrl, _categoryCtrl, _descCtrl, _nickCtrl]) {
      c.addListener(() {
        if (!_dirty && mounted) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMore() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('继续拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('继续从相册添加'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('继续从文件添加'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;

    List<CachedUpload> more = [];
    if (action == 'camera') {
      final one = await widget.picker.pickFromCamera();
      if (one != null) more = [one];
    } else if (action == 'gallery') {
      more = await widget.picker.pickMultiFromGallery();
    } else {
      more = await widget.picker.pickFromFiles();
    }

    if (more.isEmpty) return;
    setState(() {
      _uploads.addAll(more);
      _dirty = true;
    });
  }

  Future<_CloseAction> _confirmCloseAction() async {
    if (!_dirty) return _CloseAction.discard;
    final action = await showDialog<_CloseAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('检测到未保存内容'),
        content: const Text('你可以放弃修改，或先保存草稿。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.cancel), child: const Text('继续编辑')),
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.discard), child: const Text('放弃修改')),
          FilledButton(onPressed: () => Navigator.pop(ctx, _CloseAction.draft), child: const Text('保存草稿')),
        ],
      ),
    );
    return action ?? _CloseAction.cancel;
  }

  _UploadSubmitResult _buildResult({required bool draft}) {
    return _UploadSubmitResult(
      uploads: _uploads,
      brand: _brandCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      nickname: _nickCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isDraft: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final act = await _confirmCloseAction();
        if (!context.mounted) return;
        if (act == _CloseAction.discard) {
          Navigator.of(context).pop();
        } else if (act == _CloseAction.draft) {
          Navigator.of(context).pop(_buildResult(draft: true));
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.94,
        minChildSize: 0.62,
        maxChildSize: 0.98,
        expand: false,
        builder: (context, controller) {
          return Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      Text('上传资料', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('共 ${_uploads.length} 个文件（可继续添加）', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      _MultiPreviewCard(uploads: _uploads, onAddTap: _pickMore),
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _m3Field(
                              ctrl: _brandCtrl,
                              label: '品牌 *',
                              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入品牌' : null,
                            ),
                            const SizedBox(height: 10),
                            _m3Field(
                              ctrl: _categoryCtrl,
                              label: '分类 *',
                              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入分类' : null,
                            ),
                            const SizedBox(height: 10),
                            _m3Field(ctrl: _nickCtrl, label: '昵称'),
                            const SizedBox(height: 10),
                            _m3Field(ctrl: _descCtrl, label: '描述', maxLines: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('保存草稿'),
                          onPressed: () => Navigator.pop(context, _buildResult(draft: true)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('保存并上传'),
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.pop(context, _buildResult(draft: false));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _m3Field({
    required TextEditingController ctrl,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}

enum _CloseAction { cancel, discard, draft }

class _MultiPreviewCard extends StatelessWidget {
  final List<CachedUpload> uploads;
  final VoidCallback onAddTap;

  const _MultiPreviewCard({required this.uploads, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 164,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: uploads.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            if (i == uploads.length) {
              return InkWell(
                onTap: onAddTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 28),
                      SizedBox(height: 8),
                      Text('继续上传'),
                    ],
                  ),
                ),
              );
            }

            final u = uploads[i];
            final ext = u.name.toLowerCase();
            final isImage = ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg') || u.source != UploadSource.file;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 130,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: isImage && u.path.isNotEmpty
                    ? Image.file(
                        File(u.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                      )
                    : const Icon(Icons.insert_drive_file_outlined, size: 40),
              ),
            );
          },
        ),
      ),
    );
  }
}

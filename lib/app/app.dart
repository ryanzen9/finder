import 'dart:io';

import 'package:finder/api/finder_api.dart';
import 'package:finder/api/finder_mock_api.dart';
import 'package:finder/models/upload_asset.dart';
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

  final List<CachedUpload> _cachedUploads = [];
  bool _cacheReady = false;

  int get _draftCount => _cachedUploads.where((e) => e.isDraft).length;

  @override
  void initState() {
    super.initState();
    _restoreUploadCache();
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

  Future<void> _openScanPicker() async {
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
              subtitle: const Text('调用相机拍摄后上传'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('相册选择'),
              subtitle: const Text('从系统相册选择图片'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('文件上传'),
              subtitle: const Text('从文件系统选择文档/PDF'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;

    CachedUpload? picked;
    if (action == 'camera') {
      picked = await _uploadService.pickFromCamera();
    } else if (action == 'gallery') {
      picked = await _uploadService.pickFromGallery();
    } else {
      picked = await _uploadService.pickFromFiles();
    }

    if (!mounted || picked == null) return;
    await _openUploadFormSheet(picked);
  }

  Future<void> _openUploadFormSheet(CachedUpload upload) async {
    final result = await showModalBottomSheet<CachedUpload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _UploadFormSheet(initial: upload),
    );

    if (result == null || !mounted) return;

    setState(() => _cachedUploads.insert(0, result));
    await _cacheService.save(_cachedUploads);

    if (result.isDraft) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存草稿')),
      );
      return;
    }

    final sync = await _syncService.sync(result);
    final syncedUpload = result.copyWith(
      syncStatus: sync.ok ? SyncStatus.synced : SyncStatus.failed,
      syncMessage: sync.message,
      isDraft: !sync.ok,
    );

    final idx = _cachedUploads.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      _cachedUploads[idx] = syncedUpload;
      await _cacheService.save(_cachedUploads);
      if (!mounted) return;
      setState(() {});
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: sync.ok ? Colors.green.shade600 : Colors.orange.shade700,
        content: Row(
          children: [
            Icon(sync.ok ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(sync.ok ? '上传成功，已加入本地书架' : '本地已保存，远程同步失败'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LibraryPage(api: _api, cachedUploads: _cachedUploads),
      ExplorePage(api: _api),
      const SettingsPage(),
    ];

    final scanLabel = !_cacheReady ? 'Scan (...)' : (_draftCount == 0 ? 'Scan' : 'Scan ($_draftCount)');

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openScanPicker,
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

class _UploadFormSheet extends StatefulWidget {
  final CachedUpload initial;
  const _UploadFormSheet({required this.initial});

  @override
  State<_UploadFormSheet> createState() => _UploadFormSheetState();
}

class _UploadFormSheetState extends State<_UploadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _nickCtrl;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _nickCtrl = TextEditingController();

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

  Future<_CloseAction> _confirmCloseAction() async {
    if (!_dirty) return _CloseAction.discard;
    final action = await showDialog<_CloseAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('检测到未保存内容'),
        content: const Text('你可以放弃修改，或先保存草稿后稍后继续。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.cancel), child: const Text('继续编辑')),
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.discard), child: const Text('放弃修改')),
          FilledButton(onPressed: () => Navigator.pop(ctx, _CloseAction.draft), child: const Text('保存草稿')),
        ],
      ),
    );
    return action ?? _CloseAction.cancel;
  }

  CachedUpload _buildResult({required bool draft}) {
    return widget.initial.copyWith(
      brand: _brandCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      nickname: _nickCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      syncStatus: draft ? SyncStatus.pending : SyncStatus.pending,
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
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SizedBox(height: 6),
                Text('上传资料', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('填写资料后将保存到本地并同步到远程', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _PreviewCard(upload: widget.initial),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _brandCtrl,
                        decoration: const InputDecoration(labelText: '品牌 *', filled: true, border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '请输入品牌' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(labelText: '分类 *', filled: true, border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '请输入分类' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nickCtrl,
                        decoration: const InputDecoration(labelText: '昵称', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: '描述', filled: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
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
}

enum _CloseAction { cancel, discard, draft }

class _PreviewCard extends StatelessWidget {
  final CachedUpload upload;
  const _PreviewCard({required this.upload});

  @override
  Widget build(BuildContext context) {
    final ext = upload.name.toLowerCase();
    final isImage = ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg') || upload.source != UploadSource.file;
    final sourceText = switch (upload.source) {
      UploadSource.camera => '相机',
      UploadSource.gallery => '相册',
      UploadSource.file => '文件',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(label: Text(sourceText)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(upload.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isImage && upload.path.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(upload.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Text('图片预览失败'),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.insert_drive_file_outlined, size: 40),
            ),
        ],
      ),
    );
  }
}

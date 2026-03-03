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

    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择失败：$e')),
      );
    }
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

    final sync = await _syncService.sync(result);
    final syncedUpload = result.copyWith(
      syncStatus: sync.ok ? SyncStatus.synced : SyncStatus.failed,
      syncMessage: sync.message,
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
      SnackBar(content: Text(sync.ok ? '已本地保存并完成远程同步' : '已本地保存，远程同步失败')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LibraryPage(api: _api, cachedUploads: _cachedUploads),
      ExplorePage(api: _api),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openScanPicker,
              label: Text(!_cacheReady ? 'Scan (...)' : (_cachedUploads.isEmpty ? 'Scan' : 'Scan (${_cachedUploads.length})')),
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

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_dirty) return true;
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('放弃填写内容？'),
            content: const Text('你已填写部分内容，下拉关闭会丢失这些输入。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续编辑')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放弃')),
            ],
          ),
        ) ??
        false;
    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscardIfNeeded();
        if (!context.mounted) return;
        if (leave) Navigator.of(context).pop();
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SizedBox(height: 8),
                Text('上传资料', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _PreviewCard(upload: widget.initial),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _brandCtrl,
                        decoration: const InputDecoration(labelText: '品牌*', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '请输入品牌' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(labelText: '分类*', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? '请输入分类' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nickCtrl,
                        decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('保存并同步'),
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            final result = widget.initial.copyWith(
                              brand: _brandCtrl.text.trim(),
                              category: _categoryCtrl.text.trim(),
                              nickname: _nickCtrl.text.trim(),
                              description: _descCtrl.text.trim(),
                              syncStatus: SyncStatus.pending,
                            );
                            Navigator.pop(context, result);
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
}

class _PreviewCard extends StatelessWidget {
  final CachedUpload upload;
  const _PreviewCard({required this.upload});

  @override
  Widget build(BuildContext context) {
    final ext = upload.name.toLowerCase();
    final isImage = ext.endsWith('.png') || ext.endsWith('.jpg') || ext.endsWith('.jpeg') || upload.source != UploadSource.file;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(upload.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (isImage && upload.path.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(upload.path), height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: const Text('图片预览失败'),
                );
              }),
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

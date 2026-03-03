import 'package:finder/api/finder_api.dart';
import 'package:finder/api/finder_mock_api.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/services/upload_cache_service.dart';
import 'package:finder/services/upload_picker_service.dart';
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
      CachedUpload? upload;
      if (action == 'camera') {
        upload = await _uploadService.pickFromCamera();
      } else if (action == 'gallery') {
        upload = await _uploadService.pickFromGallery();
      } else {
        upload = await _uploadService.pickFromFiles();
      }

      if (!mounted || upload == null) return;

      setState(() {
        _cachedUploads.insert(0, upload!);
      });
      await _cacheService.save(_cachedUploads);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已缓存：${upload.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败：$e')),
      );
    }
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

import 'dart:io';

import 'package:finder/api/finder_mock_api.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/presentation/viewmodels/app_view_model.dart';
import 'package:finder/services/upload_picker_service.dart';
import 'package:finder/views/explore.dart';
import 'package:finder/views/library.dart';
import 'package:finder/views/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const MainScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<void> _onAvatarTap() async {
    final vm = context.read<AppViewModel>();
    if (vm.profile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已登录：${vm.profile!.nickname}')),
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
      final profile = await vm.loginByProvider(action);
      if (!mounted || profile == null) return;
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
    final vm = context.read<AppViewModel>();

    final drafts = vm.cachedUploads.where((e) => e.isDraft).toList();
    if (drafts.isNotEmpty) {
      drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final first = drafts.first;
      await _openUploadFormSheet(
        initials: drafts,
        replacedDraftIds: drafts.map((e) => e.id).toList(),
        initialBrand: first.brand,
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
    final picker = UploadPickerService();
    if (action == 'camera') {
      final one = await picker.pickFromCamera();
      return one == null ? [] : [one];
    }
    if (action == 'gallery') {
      return picker.pickMultiFromGallery();
    }
    return picker.pickFromFiles();
  }

  Future<void> _openUploadFormSheet({
    required List<CachedUpload> initials,
    required List<String> replacedDraftIds,
    String? initialBrand,
    String? initialNickname,
    String? initialDescription,
  }) async {
    final picker = UploadPickerService();
    final result = await showModalBottomSheet<_UploadSubmitResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      builder: (_) => _UploadFormSheet(
        initials: initials,
        picker: picker,
        initialBrand: initialBrand,
        initialNickname: initialNickname,
        initialDescription: initialDescription,
      ),
    );

    if (result == null || !mounted) return;

    final vm = context.read<AppViewModel>();
    final commit = await vm.commitUploadForm(
      uploads: result.uploads,
      meta: UploadFormMeta(
        brand: result.brand,
        description: result.description,
        nickname: result.nickname,
      ),
      discarded: result.discarded,
      replacedDraftIds: replacedDraftIds,
    );

    if (!mounted || commit.discarded) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: commit.successCount == commit.totalCount ? Colors.green.shade600 : Colors.orange.shade700,
        content: Row(
          children: [
            Icon(commit.successCount == commit.totalCount ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(commit.successCount == commit.totalCount
                ? '上传成功（${commit.successCount}）并加入本地书架'
                : '部分同步失败，已转为草稿'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final pages = [
      LibraryPage(
        api: const FinderMockApi(),
        cachedUploads: vm.cachedUploads,
        profile: vm.profile,
        onAvatarTap: _onAvatarTap,
        onRemoveUpload: vm.removeUploadById,
        onUpdateUpload: (uploadId, {required title, required brand, required description}) =>
            vm.updateUploadMeta(
          uploadId: uploadId,
          title: title,
          brand: brand,
          description: description,
        ),
        extraManuals: vm.localManuals,
      ),
      ExplorePage(
        api: const FinderMockApi(),
        cachedUploads: vm.cachedUploads,
        localManuals: vm.localManuals,
        onAddManualToShelf: vm.addManualToShelf,
      ),
      SettingsPage(themeMode: widget.themeMode, onThemeModeChanged: widget.onThemeModeChanged),
    ];

    return Scaffold(
      body: IndexedStack(index: vm.currentIndex, children: pages),
      floatingActionButton: vm.currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _onScanTap,
              label: const Text('Scan'),
              icon: const Icon(Icons.camera_alt_outlined),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: vm.currentIndex,
        onDestinationSelected: vm.setCurrentIndex,
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
  final String description;
  final String nickname;
  final bool discarded;

  const _UploadSubmitResult({
    required this.uploads,
    required this.brand,
    required this.description,
    required this.nickname,
    this.discarded = false,
  });
}

class _UploadFormSheet extends StatefulWidget {
  final List<CachedUpload> initials;
  final UploadPickerService picker;
  final String? initialBrand;
  final String? initialDescription;
  final String? initialNickname;

  const _UploadFormSheet({
    required this.initials,
    required this.picker,
    this.initialBrand,
    this.initialDescription,
    this.initialNickname,
  });

  @override
  State<_UploadFormSheet> createState() => _UploadFormSheetState();
}

class _UploadFormSheetState extends State<_UploadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _nickCtrl;

  late List<CachedUpload> _uploads;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _uploads = List<CachedUpload>.from(widget.initials);
    _brandCtrl = TextEditingController(text: widget.initialBrand ?? '');
    _descCtrl = TextEditingController(text: widget.initialDescription ?? '');
    _nickCtrl = TextEditingController(text: widget.initialNickname ?? '');

    for (final c in [_brandCtrl, _descCtrl, _nickCtrl]) {
      c.addListener(() {
        if (!_dirty && mounted) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
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
        content: const Text('你有未保存内容，是否放弃修改？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.cancel), child: const Text('继续编辑')),
          TextButton(onPressed: () => Navigator.pop(ctx, _CloseAction.discard), child: const Text('放弃修改')),
          FilledButton(onPressed: () => Navigator.pop(ctx, _CloseAction.cancel), child: const Text('取消')),
        ],
      ),
    );
    return action ?? _CloseAction.cancel;
  }


  Future<void> _requestClose() async {
    final navigator = Navigator.of(context);
    final act = await _confirmCloseAction();
    if (!mounted) return;
    if (act == _CloseAction.discard) {
      navigator.pop(const _UploadSubmitResult(
        uploads: [],
        brand: '',
        description: '',
        nickname: '',
        discarded: true,
      ));
    }
  }

  _UploadSubmitResult _buildResult() {
    return _UploadSubmitResult(
      uploads: _uploads,
      brand: _brandCtrl.text.trim(),
      nickname: _nickCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _requestClose();
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('上传资料', style: Theme.of(context).textTheme.headlineSmall),
                          IconButton(onPressed: _requestClose, icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('共 ${_uploads.length} 个文件（可继续添加）', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                      _MultiPreviewCard(
                        uploads: _uploads,
                        onAddTap: _pickMore,
                        onRemoveAt: (index) {
                          setState(() {
                            _uploads.removeAt(index);
                            _dirty = true;
                          });
                        },
                      ),
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
                          icon: const Icon(Icons.close),
                          label: const Text('取消'),
                          onPressed: _requestClose,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('保存并上传'),
                          onPressed: () {
                            if (_uploads.isEmpty) return;
                            if (!_formKey.currentState!.validate()) return;
                            Navigator.pop(context, _buildResult());
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

enum _CloseAction { cancel, discard }

class _MultiPreviewCard extends StatelessWidget {
  final List<CachedUpload> uploads;
  final VoidCallback onAddTap;
  final void Function(int index) onRemoveAt;

  const _MultiPreviewCard({required this.uploads, required this.onAddTap, required this.onRemoveAt});

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
              child: Stack(
                children: [
                  Container(
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
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => onRemoveAt(i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

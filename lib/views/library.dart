import 'dart:io';
import 'dart:ui';

import 'package:finder/api/finder_api.dart';
import 'package:finder/models/manual.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/models/user_profile.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  final IFinderApi api;
  final List<CachedUpload> cachedUploads;
  final UserProfile? profile;
  final VoidCallback onAvatarTap;
  final Future<void> Function(String uploadId) onRemoveUpload;
  final Future<void> Function(String uploadId, {required String title, required String brand, required String description}) onUpdateUpload;
  final List<ManualItem> extraManuals;

  const LibraryPage({
    super.key,
    required this.api,
    required this.cachedUploads,
    required this.profile,
    required this.onAvatarTap,
    required this.onRemoveUpload,
    required this.onUpdateUpload,
    required this.extraManuals,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = true;
  List<ManualItem> _all = const [];
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _initLoad();
    _scrollCtrl.addListener(() {
      final v = _scrollCtrl.offset.clamp(0, 120).toDouble();
      if ((v - _scrollOffset).abs() > 0.5) {
        setState(() => _scrollOffset = v);
      }
    });
  }

  Future<void> _initLoad() async {
    setState(() => _loading = true);
    final data = await widget.api.getLibrary();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<_UploadBundle> get _uploadBundles {
    final synced = widget.cachedUploads
        .where((u) => !u.isDraft && u.syncStatus == SyncStatus.synced)
        .toList();

    final grouped = <String, List<CachedUpload>>{};
    for (final u in synced) {
      final key = u.batchId.isNotEmpty ? u.batchId : u.id;
      grouped.putIfAbsent(key, () => []).add(u);
    }

    return grouped.entries.map((e) {
      final files = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final first = files.first;
      final latest = files.last;
      return _UploadBundle(
        bundleId: e.key,
        uploads: files,
        title: first.nickname.isNotEmpty ? first.nickname : first.name,
        brand: first.brand.isNotEmpty ? first.brand : 'Unknown',
        updatedAt: latest.createdAt,
      );
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ManualItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    final fromUploads = _uploadBundles
        .map((b) => ManualItem(
              id: 'upb-${b.bundleId}',
              title: b.title,
              brand: b.brand,
              model: '${b.uploads.length} 张图片',
              room: '本地上传',
              updatedAt: b.updatedAt,
              tags: [const ManualTag(id: 'upload', name: '上传')],
              coverGradient: 'purple',
              underWarranty: false,
            ))
        .toList();

    final merged = [...widget.extraManuals, ...fromUploads, ..._all];
    return merged.where((e) {
      final matchQ = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.brand.toLowerCase().contains(q) ||
          e.model.toLowerCase().contains(q);
      return matchQ;
    }).toList();
  }

  Color _coverColor(String key, BuildContext context) {
    switch (key) {
      case 'blue':
        return Colors.lightBlue;
      case 'indigo':
        return Colors.indigo;
      case 'orange':
        return Colors.deepOrange;
      case 'red':
        return Colors.redAccent;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final progress = (_scrollOffset / 100).clamp(0.0, 1.0);
    final logoOpacity = (1 - progress).clamp(0.0, 1.0);
    final avatarOpacity = (1 - progress * 1.2).clamp(0.0, 1.0);
    final searchHeight = lerpDouble(52, 46, progress) ?? 48;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 118)),

                      if (list.isEmpty)
                        const SliverFillRemaining(child: Center(child: Text('暂无数据')))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final item = list[i];
                              final isUpload = item.id.startsWith('upb-');
                              return Card(
                                elevation: 0,
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (isUpload) {
                                          final bundleId = item.id.substring(4);
                                          _UploadBundle? bundle;
                                          for (final b in _uploadBundles) {
                                            if (b.bundleId == bundleId) {
                                              bundle = b;
                                              break;
                                            }
                                          }
                                          if (bundle != null) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              showDragHandle: true,
                                              useSafeArea: true,
                                              builder: (_) => FractionallySizedBox(
                                                heightFactor: 0.78,
                                                child: _UploadBundleDetailSheet(bundle: bundle),
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          showDragHandle: true,
                                          useSafeArea: true,
                                          builder: (_) => FractionallySizedBox(
                                            heightFactor: 0.74,
                                            child: _ManualDetailSheet(item: item),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 82,
                                            color: _coverColor(item.coverGradient, context),
                                            alignment: Alignment.bottomLeft,
                                            padding: const EdgeInsets.all(10),
                                            child: Text(item.model, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 2),
                                                  Text(item.room, style: Theme.of(context).textTheme.bodySmall),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '更新于 ${item.updatedAt.toString().split(' ').first}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isUpload)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: PopupMenuButton<String>(
                                          tooltip: '更多操作',
                                          surfaceTintColor: Theme.of(context).colorScheme.surface,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          icon: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.more_horiz, size: 16, color: Colors.white),
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'remove') {
                                              await widget.onRemoveUpload(item.id);
                                            } else if (value == 'edit') {
                                              final updated = await _showEditDialog(context, item);
                                              if (updated != null) {
                                                await widget.onUpdateUpload(
                                                  item.id,
                                                  title: updated.$1,
                                                  brand: updated.$2,
                                                  description: updated.$3,
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('更新')]),
                                            ),
                                            PopupMenuItem(
                                              value: 'remove',
                                              child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 8), Text('删除')]),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }, childCount: list.length),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: .9,
                            ),
                          ),
                        ),
                    ],
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            opacity: logoOpacity,
                            duration: const Duration(milliseconds: 120),
                            child: SizedBox(
                              height: 36 * logoOpacity,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Finder', style: Theme.of(context).textTheme.headlineMedium),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: searchHeight,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '搜索说明书、品牌或型号',
                                      isCollapsed: true,
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: avatarOpacity,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: widget.onAvatarTap,
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundImage: widget.profile?.avatarUrl != null ? NetworkImage(widget.profile!.avatarUrl!) : null,
                                        child: widget.profile?.avatarUrl == null
                                            ? Text((widget.profile?.nickname.isNotEmpty == true ? widget.profile!.nickname[0] : '林'))
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<(String, String, String)?> _showEditDialog(BuildContext context, ManualItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final brandCtrl = TextEditingController(text: item.brand);
    final descCtrl = TextEditingController();

    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('更新说明书信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '标题')),
              const SizedBox(height: 8),
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: '品牌')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (titleCtrl.text.trim(), brandCtrl.text.trim(), descCtrl.text.trim())),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    titleCtrl.dispose();
    brandCtrl.dispose();
    descCtrl.dispose();
    return result;
  }

}

class _ManualDetailSheet extends StatelessWidget {
  final ManualItem item;
  const _ManualDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(16),
          child: Text(
            item.model,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${item.brand} · ${item.model} · ${item.room}'),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('最近更新时间'),
            subtitle: Text(item.updatedAt.toString().split(' ').first),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: const Text('打开说明书')),
      ],
    );
  }
}

class _UploadBundle {
  final String bundleId;
  final List<CachedUpload> uploads;
  final String title;
  final String brand;
  final DateTime updatedAt;

  const _UploadBundle({
    required this.bundleId,
    required this.uploads,
    required this.title,
    required this.brand,
    required this.updatedAt,
  });
}

class _UploadBundleDetailSheet extends StatefulWidget {
  final _UploadBundle bundle;
  const _UploadBundleDetailSheet({required this.bundle});

  @override
  State<_UploadBundleDetailSheet> createState() => _UploadBundleDetailSheetState();
}

class _UploadBundleDetailSheetState extends State<_UploadBundleDetailSheet> {
  int _index = 0;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.bundle.uploads;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: files.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final u = files[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(u.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text('${_index + 1}/${files.length}', style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = i == _index;
              return GestureDetector(
                onTap: () => _pageCtrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(files[i].path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.image_not_supported_outlined, size: 16),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(widget.bundle.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${widget.bundle.brand} · 本地上传'),
        const SizedBox(height: 12),
        Text('更新于 ${widget.bundle.updatedAt.toString().split(' ').first}'),
      ],
    );
  }
}

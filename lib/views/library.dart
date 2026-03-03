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
  final Future<void> Function(String uploadId, {required String title, required String brand, required String category, required String description}) onUpdateUpload;

  const LibraryPage({
    super.key,
    required this.api,
    required this.cachedUploads,
    required this.profile,
    required this.onAvatarTap,
    required this.onRemoveUpload,
    required this.onUpdateUpload,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _selectedTag;
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

  List<ManualItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    final fromUploads = widget.cachedUploads
        .where((u) => !u.isDraft && u.syncStatus == SyncStatus.synced)
        .map((u) => ManualItem(
              id: 'up-${u.id}',
              title: u.nickname.isNotEmpty ? u.nickname : u.name,
              brand: u.brand.isNotEmpty ? u.brand : 'Unknown',
              model: u.category.isNotEmpty ? u.category : '未分类',
              room: '本地上传',
              updatedAt: u.createdAt,
              tags: [
                ManualTag(id: 'upload', name: '上传'),
                if (u.category.isNotEmpty) ManualTag(id: 'cat', name: u.category),
              ],
              coverGradient: 'purple',
              underWarranty: false,
            ))
        .toList();

    final merged = [...fromUploads, ..._all];
    return merged.where((e) {
      final matchQ = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.brand.toLowerCase().contains(q) ||
          e.model.toLowerCase().contains(q);
      final matchTag = _selectedTag == null || e.tags.any((t) => t.id == _selectedTag || t.name == _selectedTag);
      return matchQ && matchTag;
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
    final tags = const [
      ('tv', '影音'),
      ('kitchen', '厨房'),
      ('camera', '相机'),
      ('car', '汽车'),
      ('warranty', '保修中'),
    ];

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


                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 52,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: tags.map((e) {
                              final selected = _selectedTag == e.$1;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(e.$2),
                                  selected: selected,
                                  onSelected: (v) => setState(() => _selectedTag = v ? e.$1 : null),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (list.isEmpty)
                        const SliverFillRemaining(child: Center(child: Text('暂无数据')))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final item = list[i];
                              final isUpload = item.id.startsWith('up-');
                              return Card(
                                elevation: 0,
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    InkWell(
                                      onTap: () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        useSafeArea: true,
                                        builder: (_) => FractionallySizedBox(
                                          heightFactor: 0.74,
                                          child: _ManualDetailSheet(item: item),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 90,
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
                                                  const SizedBox(height: 4),
                                                  Text(item.room, style: Theme.of(context).textTheme.bodySmall),
                                                  const Spacer(),
                                                  if (item.tags.isNotEmpty)
                                                    Chip(
                                                      label: Text(item.tags.first.name),
                                                      visualDensity: VisualDensity.compact,
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
                                        top: 4,
                                        right: 4,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 18),
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
                                                  category: updated.$3,
                                                  description: updated.$4,
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(value: 'edit', child: Text('更新')),
                                            PopupMenuItem(value: 'remove', child: Text('移除')),
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
                              childAspectRatio: .82,
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

  Future<(String, String, String, String)?> _showEditDialog(BuildContext context, ManualItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final brandCtrl = TextEditingController(text: item.brand);
    final categoryCtrl = TextEditingController(text: item.model);
    final descCtrl = TextEditingController();

    final result = await showDialog<(String, String, String, String)>(
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
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: '分类')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, (titleCtrl.text.trim(), brandCtrl.text.trim(), categoryCtrl.text.trim(), descCtrl.text.trim())),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    titleCtrl.dispose();
    brandCtrl.dispose();
    categoryCtrl.dispose();
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
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: item.tags.map((t) => Chip(label: Text(t.name))).toList()),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('最近更新时间'),
            subtitle: Text(item.updatedAt.toString().split(' ').first),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('保修状态'),
            subtitle: Text(item.underWarranty ? '保修中' : '已过保'),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: const Text('打开说明书')),
      ],
    );
  }
}

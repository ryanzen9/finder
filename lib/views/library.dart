import 'dart:ui';

import 'package:finder/api/finder_api.dart';
import 'package:finder/models/manual.dart';
import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  final IFinderApi api;
  const LibraryPage({super.key, required this.api});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedTag;
  bool _loading = true;
  List<ManualItem> _all = const [];

  @override
  void initState() {
    super.initState();
    _initLoad();
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
    return _all.where((e) {
      final matchQ = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.brand.toLowerCase().contains(q) ||
          e.model.toLowerCase().contains(q);
      final matchTag = _selectedTag == null || e.tags.any((t) => t.id == _selectedTag);
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

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text('Finder', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchHeaderDelegate(
                      minExtentValue: 62,
                      maxExtentValue: 92,
                      childBuilder: (progress) {
                        final avatarOpacity = (1 - progress).clamp(0.0, 1.0);
                        final verticalPad = lerpDouble(14, 8, progress) ?? 10;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, verticalPad, 16, 8),
                          child: Container(
                            height: 48,
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
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: CircleAvatar(radius: 16, child: Text('林')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
                          return Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
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
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(item.room, style: Theme.of(context).textTheme.bodySmall),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: item.tags.take(2).map((t) => Chip(label: Text(t.name), visualDensity: VisualDensity.compact)).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentValue;
  final double maxExtentValue;
  final Widget Function(double progress) childBuilder;

  _SearchHeaderDelegate({
    required this.minExtentValue,
    required this.maxExtentValue,
    required this.childBuilder,
  });

  @override
  double get minExtent => minExtentValue;

  @override
  double get maxExtent => maxExtentValue;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Container(color: Theme.of(context).colorScheme.surface, child: childBuilder(progress));
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.minExtentValue != minExtentValue || oldDelegate.maxExtentValue != maxExtentValue;
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

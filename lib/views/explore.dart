import 'package:finder/api/finder_api.dart';
import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/presentation/viewmodels/explore_view_model.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  final IFinderApi api;
  final List<CachedUpload> cachedUploads;
  final List<ManualItem> localManuals;
  final Future<void> Function(ManualItem) onAddManualToShelf;

  const ExplorePage({
    super.key,
    required this.api,
    required this.cachedUploads,
    required this.localManuals,
    required this.onAddManualToShelf,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _ctrl = TextEditingController();
  final ExploreViewModel _vm = ExploreViewModel();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<ManualItem> get _myShelfFromUploads {
    return widget.cachedUploads
        .where((u) => !u.isDraft && u.syncStatus == SyncStatus.synced)
        .map(
          (u) => ManualItem(
            id: 'up-${u.id}',
            title: u.nickname.isNotEmpty ? u.nickname : u.name,
            brand: u.brand.isNotEmpty ? u.brand : 'Unknown',
            model: u.category.isNotEmpty ? u.category : '未分类',
            room: '本地上传',
            updatedAt: u.createdAt,
            tags: [const ManualTag(id: 'upload', name: '上传')],
            coverGradient: 'purple',
            underWarranty: false,
          ),
        )
        .toList();
  }

  Future<void> _openRespondSheet(HelpRequest request) async {
    final base = await widget.api.getLibrary();
    if (!mounted) return;
    final shelf = [...widget.localManuals, ..._myShelfFromUploads, ...base];

    final picked = await showModalBottomSheet<ManualItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.78,
        child: _SelectManualSheet(items: shelf),
      ),
    );

    if (picked == null || !mounted) return;

    final ok = await _vm.respondHelp(requestId: request.id, manualId: picked.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已响应：${picked.title}' : '响应失败，请稍后重试')),
    );
  }

  Future<void> _addToShelf(ManualItem item) async {
    final ok = await _vm.addCommunityManual(manualId: item.id);
    if (ok) {
      await widget.onAddManualToShelf(item);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已加入说明书架：${item.title}' : '添加失败，请稍后重试')),
    );
  }

  void _openHelpMore(List<HelpRequest> list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpListPage(
          requests: list,
          onRespond: _openRespondSheet,
        ),
      ),
    );
  }

  void _openCommunityFeed(List<ManualItem> list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityFeedPage(
          items: list,
          onTapItem: (item) => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            useSafeArea: true,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.74,
              child: _ManualDetailSheet(item: item),
            ),
          ),
          onAdd: _addToShelf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text('探索', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('发现外部资源与社区互助', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SearchBar(
              controller: _ctrl,
              hintText: '众包搜索：品牌/型号',
              onChanged: (_) => setState(() {}),
              leading: const Icon(Icons.search),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('求助悬赏', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<List<HelpRequest>>(
                  future: widget.api.getHelpRequests(),
                  builder: (context, snap) {
                    final list = snap.data ?? const <HelpRequest>[];
                    return TextButton(onPressed: list.isEmpty ? null : () => _openHelpMore(list), child: const Text('查看更多'));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<HelpRequest>>(
              future: widget.api.getHelpRequests(),
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: list
                      .take(3)
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(child: Text(e.author[0])),
                            title: Text(e.title),
                            subtitle: Text('${e.timeText} · ${e.location}'),
                            trailing: FilledButton(onPressed: () => _openRespondSheet(e), child: const Text('响应')),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('社区结果', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<List<ManualItem>>(
                  future: widget.api.searchCommunity(_ctrl.text),
                  builder: (context, snap) {
                    final list = snap.data ?? const <ManualItem>[];
                    return TextButton(onPressed: list.isEmpty ? null : () => _openCommunityFeed(list), child: const Text('查看更多'));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ManualItem>>(
              future: widget.api.searchCommunity(_ctrl.text),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? [];
                return Column(
                  children: list
                      .take(5)
                      .map((e) => Card(
                            elevation: 0,
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(e.title),
                              subtitle: Text('${e.brand} ${e.model}'),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                useSafeArea: true,
                                builder: (_) => FractionallySizedBox(
                                  heightFactor: 0.74,
                                  child: _ManualDetailSheet(item: e),
                                ),
                              ),
                              trailing: TextButton(onPressed: () => _addToShelf(e), child: const Text('Add')),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HelpListPage extends StatelessWidget {
  final List<HelpRequest> requests;
  final Future<void> Function(HelpRequest) onRespond;
  const HelpListPage({super.key, required this.requests, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('求助悬赏')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final e = requests[i];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(child: Text(e.author[0])),
              title: Text(e.title),
              subtitle: Text('${e.timeText} · ${e.location}'),
              trailing: FilledButton(onPressed: () => onRespond(e), child: const Text('响应')),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: requests.length,
      ),
    );
  }
}

class CommunityFeedPage extends StatelessWidget {
  final List<ManualItem> items;
  final void Function(ManualItem) onTapItem;
  final Future<void> Function(ManualItem) onAdd;

  const CommunityFeedPage({
    super.key,
    required this.items,
    required this.onTapItem,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社区说明书')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onTapItem(item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(10),
                    child: Text(item.model),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.brand} · ${item.room}', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(onPressed: () => onAdd(item), child: const Text('Add')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectManualSheet extends StatelessWidget {
  final List<ManualItem> items;
  const _SelectManualSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(item.title),
            subtitle: Text('${item.brand} · ${item.model}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, item),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: items.length,
      ),
    );
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
          child: Text(item.model, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 16),
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${item.brand} · ${item.model} · ${item.room}'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: item.tags.map((t) => Chip(label: Text(t.name))).toList()),
      ],
    );
  }
}

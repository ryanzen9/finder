import 'dart:io';

import 'package:finder/api/finder_api.dart';
import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';
import 'package:finder/models/upload_asset.dart';
import 'package:finder/presentation/viewmodels/explore_view_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final List<HelpRequest> _myPublishedRequests = [];
  final Set<String> _respondedRequestIds = <String>{};

  late Future<List<HelpRequest>> _helpRequestsFuture;
  late Future<List<ManualItem>> _communityFuture;

  @override
  void initState() {
    super.initState();
    _helpRequestsFuture = _loadHelpRequests();
    _communityFuture = widget.api.searchCommunity('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<List<HelpRequest>> _loadHelpRequests() async {
    final remote = await widget.api.getHelpRequests();
    return [..._myPublishedRequests, ...remote];
  }

  void _refreshExplore() {
    setState(() {
      _helpRequestsFuture = _loadHelpRequests();
      _communityFuture = widget.api.searchCommunity(_ctrl.text);
    });
  }

  List<ManualItem> get _myShelfFromUploads {
    return widget.cachedUploads
        .where((u) => !u.isDraft && u.syncStatus == SyncStatus.synced)
        .map(
          (u) => ManualItem(
            id: 'up-${u.id}',
            title: u.nickname.isNotEmpty ? u.nickname : u.name,
            brand: u.brand.isNotEmpty ? u.brand : 'Unknown',
            model: '-',
            room: '本地上传',
            updatedAt: u.createdAt,
            tags: [const ManualTag(id: 'upload', name: '上传')],
            coverGradient: 'purple',
            underWarranty: false,
          ),
        )
        .toList();
  }

  Future<bool> _openRespondSheet(HelpRequest request) async {
    if (_respondedRequestIds.contains(request.id)) return true;

    final base = await widget.api.getLibrary();
    if (!mounted) return false;
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

    if (picked == null || !mounted) return false;

    final ok = await _vm.respondHelp(requestId: request.id, manualId: picked.id);

    if (!mounted) return false;
    if (ok) {
      setState(() => _respondedRequestIds.add(request.id));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '已响应：${picked.title}' : '响应失败，请稍后重试')),
    );
    return ok;
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

  Future<void> _openPublishSheet() async {
    final result = await showModalBottomSheet<_PublishDraftResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PublishHelpSheet(),
    );

    if (result == null || !mounted) return;

    final ok = await _vm.publishHelpRequest(
      title: result.title,
      description: result.description,
      imagePath: result.imagePath,
    );

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布失败，请稍后重试')),
      );
      return;
    }

    _myPublishedRequests.insert(
      0,
      HelpRequest(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        author: '我',
        title: result.title,
        location: '我的位置',
        timeText: '刚刚',
        description: result.description,
        imagePath: result.imagePath,
      ),
    );
    _refreshExplore();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布成功')),
    );
  }

  void _openHelpMore(List<HelpRequest> list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpListPage(
          requests: list,
          respondedRequestIds: _respondedRequestIds,
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
              child: _ManualDetailSheet(
                item: item,
                onRespond: () => _addToShelf(item),
              ),
            ),
          ),
          onAdd: _addToShelf,
        ),
      ),
    );
  }

  void _openCommunitySearchPage(String keyword) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunitySearchPage(
          api: widget.api,
          initialKeyword: keyword,
          onRespond: _addToShelf,
        ),
      ),
    );
  }

  void _openHelpDetail(HelpRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.72,
        child: _HelpRequestDetailSheet(
          request: request,
          initiallyDone: _respondedRequestIds.contains(request.id),
          onRespond: () => _openRespondSheet(request),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openPublishSheet,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text('探索', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('发现外部资源与社区互助',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            SearchBar(
              controller: _ctrl,
              hintText: '众包搜索：品牌/型号',
              readOnly: true,
              onTap: () => _openCommunitySearchPage(_ctrl.text),
              leading: const Icon(Icons.search),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('求助悬赏', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<List<HelpRequest>>(
                  future: _helpRequestsFuture,
                  builder: (context, snap) {
                    final list = snap.data ?? const <HelpRequest>[];
                    return TextButton(
                      onPressed: list.isEmpty ? null : () => _openHelpMore(list),
                      child: const Text('查看更多'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<HelpRequest>>(
              future: _helpRequestsFuture,
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: list.take(3).map((e) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openHelpDetail(e),
                      leading: CircleAvatar(child: Text(e.author[0])),
                      title: Text(e.title),
                      subtitle: Text('${e.timeText} · ${e.location}'),
                      trailing: _RespondActionButton(
                        requestId: e.id,
                        initiallyDone: _respondedRequestIds.contains(e.id),
                        onRespond: () => _openRespondSheet(e),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('社区结果', style: Theme.of(context).textTheme.titleMedium),
                FutureBuilder<List<ManualItem>>(
                  future: _communityFuture,
                  builder: (context, snap) {
                    final list = snap.data ?? const <ManualItem>[];
                    return TextButton(
                      onPressed:
                          list.isEmpty ? null : () => _openCommunitySearchPage(_ctrl.text),
                      child: const Text('查看更多'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ManualItem>>(
              future: _communityFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? [];
                return Column(
                  children: list.take(5).map((e) {
                    return Card(
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
                            child: _ManualDetailSheet(
                              item: e,
                              onRespond: () => _addToShelf(e),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
  final Set<String> respondedRequestIds;
  final Future<bool> Function(HelpRequest) onRespond;

  const HelpListPage({
    super.key,
    required this.requests,
    required this.respondedRequestIds,
    required this.onRespond,
  });

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
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                useSafeArea: true,
                builder: (_) => FractionallySizedBox(
                  heightFactor: 0.72,
                  child: _HelpRequestDetailSheet(
                    request: e,
                    initiallyDone: respondedRequestIds.contains(e.id),
                    onRespond: () => onRespond(e),
                  ),
                ),
              ),
              leading: CircleAvatar(child: Text(e.author[0])),
              title: Text(e.title),
              subtitle: Text('${e.timeText} · ${e.location}'),
              trailing: _RespondActionButton(
                requestId: e.id,
                initiallyDone: respondedRequestIds.contains(e.id),
                onRespond: () => onRespond(e),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: requests.length,
      ),
    );
  }
}

class _RespondActionButton extends StatefulWidget {
  final String requestId;
  final bool initiallyDone;
  final Future<bool> Function() onRespond;

  const _RespondActionButton({
    required this.requestId,
    required this.initiallyDone,
    required this.onRespond,
  });

  @override
  State<_RespondActionButton> createState() => _RespondActionButtonState();
}

class _RespondActionButtonState extends State<_RespondActionButton> {
  @override
  Widget build(BuildContext context) {
    return _TriStateRespondButton(
      initiallyDone: widget.initiallyDone,
      onRespond: widget.onRespond,
      fullWidth: false,
    );
  }
}

class _TriStateRespondButton extends StatefulWidget {
  final bool initiallyDone;
  final Future<bool> Function() onRespond;
  final bool closeOnSuccess;
  final bool fullWidth;

  const _TriStateRespondButton({
    super.key,
    this.initiallyDone = false,
    required this.onRespond,
    this.closeOnSuccess = false,
    this.fullWidth = true,
  });

  @override
  State<_TriStateRespondButton> createState() => _TriStateRespondButtonState();
}

class _TriStateRespondButtonState extends State<_TriStateRespondButton> {
  late bool _done;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _done = widget.initiallyDone;
  }

  @override
  void didUpdateWidget(covariant _TriStateRespondButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyDone && !_done) {
      setState(() => _done = true);
    }
  }

  Future<void> _handleTap() async {
    if (_done || _loading) return;
    setState(() => _loading = true);
    final ok = await widget.onRespond();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _done = true;
        _loading = false;
      });
      if (widget.closeOnSuccess) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: (_done || _loading) ? null : _handleTap,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _done
                  ? const Icon(
                      Icons.check,
                      key: ValueKey('success'),
                      size: 18,
                      color: Colors.grey,
                    )
                  : const Text(
                      '响应',
                      key: ValueKey('idle'),
                    ),
        ),
      ),
    );
  }
}

class _HelpRequestDetailSheet extends StatelessWidget {
  final HelpRequest request;
  final bool initiallyDone;
  final Future<bool> Function() onRespond;

  const _HelpRequestDetailSheet({
    required this.request,
    required this.initiallyDone,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: request.imagePath == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '暂无图片',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                )
              : Image.file(File(request.imagePath!), fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Text(request.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${request.author} · ${request.timeText} · ${request.location}'),
        const SizedBox(height: 14),
        Text(
          request.description.isEmpty ? '暂无描述' : request.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _TriStateRespondButton(
          initiallyDone: initiallyDone,
          onRespond: onRespond,
        ),
      ],
    );
  }
}

class CommunitySearchPage extends StatefulWidget {
  final IFinderApi api;
  final String initialKeyword;
  final Future<void> Function(ManualItem) onRespond;

  const CommunitySearchPage({
    super.key,
    required this.api,
    required this.initialKeyword,
    required this.onRespond,
  });

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  late final TextEditingController _ctrl;
  late Future<List<ManualItem>> _future;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialKeyword);
    _future = widget.api.searchCommunity(widget.initialKeyword);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = widget.api.searchCommunity(_ctrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社区结果')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SearchBar(
            controller: _ctrl,
            hintText: '输入品牌/型号查询',
            onChanged: (_) => _search(),
            onSubmitted: (_) => _search(),
            leading: const Icon(Icons.search),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<ManualItem>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? const <ManualItem>[];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('未找到匹配结果')),
                );
              }
              return Column(
                children: list.map((e) {
                  return Card(
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
                          child: _ManualDetailSheet(
                            item: e,
                            onRespond: () => widget.onRespond(e),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
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
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.brand} · ${item.room}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => onAdd(item),
                        child: const Text('Add'),
                      ),
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
  final Future<void> Function()? onRespond;

  const _ManualDetailSheet({
    required this.item,
    this.onRespond,
  });

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
        if (onRespond != null) ...[
          const SizedBox(height: 20),
          _TriStateRespondButton(
            onRespond: () async {
              await onRespond!.call();
              return true;
            },
            closeOnSuccess: true,
          ),
        ],
      ],
    );
  }
}

class _PublishDraftResult {
  final String title;
  final String description;
  final String? imagePath;

  const _PublishDraftResult({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class _PublishHelpSheet extends StatefulWidget {
  const _PublishHelpSheet();

  @override
  State<_PublishHelpSheet> createState() => _PublishHelpSheetState();
}

class _PublishHelpSheetState extends State<_PublishHelpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _imagePath;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    setState(() => _imagePath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('发布寻物', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _m3Field(
                ctrl: _titleCtrl,
                label: '寻物标题 *',
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入标题' : null,
              ),
              const SizedBox(height: 10),
              _m3Field(
                ctrl: _descCtrl,
                label: '描述 *',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入描述' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  alignment: Alignment.center,
                  child: _imagePath == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined),
                            SizedBox(height: 6),
                            Text('点击添加图片'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 128,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(
                          context,
                          _PublishDraftResult(
                            title: _titleCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            imagePath: _imagePath,
                          ),
                        );
                      },
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('发布'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

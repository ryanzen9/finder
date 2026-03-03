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

  Future<List<ManualItem>> _load() {
    return widget.api.getLibrary(
      keyword: _searchCtrl.text,
      tag: _selectedTag,
    );
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
      default:
        return Theme.of(context).colorScheme.primary;
    }
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finder', style: Theme.of(context).textTheme.headlineMedium),
                        Text('你的说明书书架', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const CircleAvatar(child: Text('林')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: '搜索说明书、品牌或型号',
                leading: const Icon(Icons.search),
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(
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
            Expanded(
              child: FutureBuilder<List<ManualItem>>(
                future: _load(),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Center(child: Text('暂无数据'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .82,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            builder: (_) => _ManualDetailSheet(item: item),
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualDetailSheet extends StatelessWidget {
  final ManualItem item;
  const _ManualDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${item.brand} · ${item.model} · ${item.room}'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.menu_book_outlined), label: const Text('打开说明书')),
        ],
      ),
    );
  }
}

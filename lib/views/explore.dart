import 'package:finder/api/finder_api.dart';
import 'package:finder/models/help_request.dart';
import 'package:finder/models/manual.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  final IFinderApi api;
  const ExplorePage({super.key, required this.api});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _ctrl = TextEditingController();

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
            Text('求助悬赏', style: Theme.of(context).textTheme.titleMedium),
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
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(child: Text(e.author[0])),
                            title: Text(e.title),
                            subtitle: Text('${e.timeText} · ${e.location}'),
                            trailing: FilledButton(onPressed: () {}, child: const Text('响应')),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('社区结果', style: Theme.of(context).textTheme.titleMedium),
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
                      .map((e) => Card(
                            elevation: 0,
                            child: ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(e.title),
                              subtitle: Text('${e.brand} ${e.model}'),
                              trailing: TextButton(onPressed: () {}, child: const Text('Add')),
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

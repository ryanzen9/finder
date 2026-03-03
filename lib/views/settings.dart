import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Text('设置', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('管理同步、存储与偏好', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            const _SettingTile(
              icon: Icons.cloud_outlined,
              title: 'Google Drive',
              subtitle: '已连接 · 2.4 GB 同步',
              action: '管理',
            ),
            const _SettingTile(
              icon: Icons.storage_outlined,
              title: 'Supabase',
              subtitle: '最近同步 · 5 分钟前',
              action: '查看',
            ),
            const _SwitchTile(title: '深色模式', subtitle: '手动切换界面风格'),
            const _SwitchTile(title: '触感反馈', subtitle: '确认操作时轻震动', initial: true),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(onPressed: () {}, child: Text(action)),
      ),
    );
  }
}

class _SwitchTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initial;
  const _SwitchTile({required this.title, required this.subtitle, this.initial = false});

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  late bool v = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        value: v,
        onChanged: (n) => setState(() => v = n),
        title: Text(widget.title),
        subtitle: Text(widget.subtitle),
      ),
    );
  }
}

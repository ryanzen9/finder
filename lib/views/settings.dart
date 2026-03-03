import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

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
              title: 'Google Drive 同步',
              subtitle: '未连接',
              action: '连接',
            ),
            const _SettingTile(
              icon: Icons.backup_outlined,
              title: 'iCloud 同步',
              subtitle: '未连接',
              action: '连接',
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('主题样式', style: Theme.of(context).textTheme.titleMedium),
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (v) => onThemeModeChanged(v ?? ThemeMode.light),
                      title: const Text('浅色'),
                    ),
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (v) => onThemeModeChanged(v ?? ThemeMode.dark),
                      title: const Text('深色'),
                    ),
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (v) => onThemeModeChanged(v ?? ThemeMode.system),
                      title: const Text('跟随系统'),
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

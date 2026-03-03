import 'package:finder/app/app.dart';
import 'package:finder/app/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 沉浸式
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode _themeMode = ThemeMode.system;

  static const _themeKey = 'finder.themeMode.v1';

  @override
  void initState() {
    super.initState();
    _restoreThemeMode();
  }

  Future<void> _restoreThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);
    if (!mounted || raw == null) return;
    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    setState(() => _themeMode = mode);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }


  @override
  Widget build(BuildContext context) {
    // return const CupertinoApp(
    //   debugShowCheckedModeBanner: false,
    //   // home: HomePage(),
    //   home: HomePage(),
    // );
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 主题
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      // 底部导航栏
      // home: BottomMenuBarPage(),

      // SliverAppBar 示例
      // home: NestedScrollViewExample(),
      home: MainScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Hello')),
      child: Center(child: Text('It works!')),
    );
  }
}

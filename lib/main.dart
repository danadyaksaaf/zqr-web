import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/history_service.dart';

const _themeKey = 'dark_mode';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(_themeKey) ?? false;
  await HistoryService().init();
  runApp(MainApp(initialDarkMode: isDark));
}

class MainApp extends StatefulWidget {
  final bool initialDarkMode;

  const MainApp({super.key, required this.initialDarkMode});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late bool _isDarkMode = widget.initialDarkMode;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_themeKey, _isDarkMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zQR',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onToggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

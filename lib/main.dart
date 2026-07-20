import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/history_service.dart';

const _themeKey = 'dark_mode';

Future<bool> _checkConnectivity() async {
  try {
    final result = await Connectivity()
        .checkConnectivity()
        .timeout(const Duration(seconds: 5));
    return result.any((r) => r != ConnectivityResult.none);
  } on TimeoutException {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(_themeKey) ?? false;
  final isConnected = await _checkConnectivity();
  await HistoryService().init();
  runApp(MainApp(initialDarkMode: isDark, initialConnected: isConnected));
}

class MainApp extends StatefulWidget {
  final bool initialDarkMode;
  final bool initialConnected;

  const MainApp({
    super.key,
    required this.initialDarkMode,
    required this.initialConnected,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late bool _isDarkMode = widget.initialDarkMode;
  late bool _isConnected = widget.initialConnected;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_themeKey, _isDarkMode),
    );
  }

  Future<void> _retryConnection() async {
    final connected = await _checkConnectivity();
    setState(() {
      _isConnected = connected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zQR',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _isConnected
          ? HomeScreen(onToggleTheme: _toggleTheme, isDarkMode: _isDarkMode)
          : _OfflineScreen(onRetry: _retryConnection),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppTheme.error.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'No Connection',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

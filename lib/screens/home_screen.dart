import 'dart:async';
import 'package:flutter/material.dart';
import '../models/qr_data.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_messages.dart';
import 'generators/generator_resettable.dart';
import 'url_generator_screen.dart';
import 'vcard_generator_screen.dart';
import 'wifi_generator_screen.dart';
import 'text_generator_screen.dart';
import 'upload_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey textKey = GlobalKey();
  final GlobalKey urlKey = GlobalKey();
  final GlobalKey vcardKey = GlobalKey();
  final GlobalKey wifiKey = GlobalKey();

  StreamSubscription<bool>? _connectivitySubscription;
  QRData? _pendingData;
  int? _pendingTabIndex;
  bool _pendingMarkAsSaved = true;
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      TextGeneratorScreen(key: textKey),
      URLGeneratorScreen(key: urlKey),
      VCardGeneratorScreen(key: vcardKey),
      WiFiGeneratorScreen(key: wifiKey),
      UploadScreen(onNavigateToTab: navigateToTabWithData),
      HistoryScreen(onNavigateToTab: navigateToTabWithData),
    ];
    _initConnectivity();
  }

  void navigateToTabWithData(int tabIndex, QRData data, {bool markAsSaved = true}) {
    final keys = [textKey, urlKey, vcardKey, wifiKey];
    if (tabIndex < 0 || tabIndex >= keys.length) return;

    _pendingData = data;
    _pendingTabIndex = tabIndex;
    _pendingMarkAsSaved = markAsSaved;
    setState(() => _selectedIndex = tabIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingData != null && _pendingTabIndex != null && mounted) {
        final key = keys[_pendingTabIndex!];
        final state = key.currentState;
        if (state != null) {
          (state as GeneratorResettable).loadFromData(
            _pendingData!,
            markAsSaved: _pendingMarkAsSaved,
          );
        }
        _pendingData = null;
        _pendingTabIndex = null;
        _pendingMarkAsSaved = true;
      }
    });
  }

  Future<void> _initConnectivity() async {
    final connectivity = ConnectivityService();
    await connectivity.init();
    _connectivitySubscription = connectivity.onConnectivityChange.listen((
      isOnline,
    ) {
      if (mounted) {
        if (isOnline) {
          AppMessages.showSuccess(context, "You're back online.");
        } else {
          AppMessages.showError(
            context,
            "You're offline. Some features may be unavailable.",
          );
        }
      }
    });
  }

  GeneratorResettable? _currentGeneratorState() {
    final keys = [textKey, urlKey, vcardKey, wifiKey];
    if (_selectedIndex < 0 || _selectedIndex >= keys.length) return null;
    final state = keys[_selectedIndex].currentState;
    if (state == null) return null;
    return state as GeneratorResettable;
  }

  bool _hasUnsavedChanges() {
    return _currentGeneratorState()?.hasUnsavedChanges ?? false;
  }

  void _onTabChanged(int index) {
    if (index == _selectedIndex) return;

    if (_hasUnsavedChanges()) {
      _showUnsavedChangesDialog(index);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showUnsavedChangesDialog(int newIndex) {
    final generatorState = _currentGeneratorState();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.error,
          size: 40,
        ),
        title: Text('Unsaved Changes'),
        content: Text(
          'You have unsaved QR code changes. Would you like to save them to history before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              generatorState?.reset();
              Navigator.pop(context);
              setState(() => _selectedIndex = newIndex);
            },
            child: Text("Don't Save", style: TextStyle(color: AppTheme.error)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (generatorState != null) {
                await generatorState.saveToHistory();
              }
              if (context.mounted) {
                Navigator.pop(context);
                setState(() => _selectedIndex = newIndex);
              }
            },
            icon: Icon(Icons.save_outlined, size: 18),
            label: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch({bool compact = false}) {
    final isDark = widget.isDarkMode;
    return GestureDetector(
      onTap: widget.onToggleTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: compact ? 56 : 64,
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryPurpleDark.withValues(alpha: 0.3)
              : AppTheme.primaryPurpleLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.primaryPurpleLight.withValues(alpha: 0.4)
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              left: isDark ? 30 : 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppTheme.primaryPurpleLight
                      : AppTheme.primaryPurple,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark
                                  ? AppTheme.primaryPurpleLight
                                  : AppTheme.primaryPurple)
                              .withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(turns: animation, child: child);
                  },
                  child: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny,
                    key: ValueKey(isDark),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTabChanged,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logos/logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'zQR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.text_fields_outlined),
                  selectedIcon: Icon(Icons.text_fields),
                  label: Text('Text'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.link_outlined),
                  selectedIcon: Icon(Icons.link),
                  label: Text('URL'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: Text('vCard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.wifi_outlined),
                  selectedIcon: Icon(Icons.wifi),
                  label: Text('Wi-Fi'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.upload_file_outlined),
                  selectedIcon: Icon(Icons.upload_file),
                  label: Text('Upload'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        'Zdyaksa Labs',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop)
                  AppBar(
                    title: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/logos/logo.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'zQR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: _buildThemeSwitch(),
                      ),
                    ],
                  ),
                Expanded(
                  child: isDesktop
                      ? Stack(
                          children: [
                            IndexedStack(
                              index: _selectedIndex,
                              children: _screens,
                            ),
                            Positioned(
                              top: 24,
                              right: 24,
                              child: _buildThemeSwitch(),
                            ),
                          ],
                        )
                      : IndexedStack(index: _selectedIndex, children: _screens),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabChanged,
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.text_fields_outlined),
                      selectedIcon: Icon(Icons.text_fields),
                      label: 'Text',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.link_outlined),
                      selectedIcon: Icon(Icons.link),
                      label: 'URL',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.badge_outlined),
                      selectedIcon: Icon(Icons.badge),
                      label: 'vCard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.wifi_outlined),
                      selectedIcon: Icon(Icons.wifi),
                      label: 'Wi-Fi',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.upload_file_outlined),
                      selectedIcon: Icon(Icons.upload_file),
                      label: 'Upload',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: 'History',
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: Text(
                    'Zdyaksa Labs 2026',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

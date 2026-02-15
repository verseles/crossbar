import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';
import 'dialogs/widget_config_dialog.dart';
import 'tabs/marketplace_tab.dart';
import 'tabs/plugins_tab.dart';
import 'tabs/settings_tab.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

  /// Convert ThemeModeOption to Flutter's ThemeMode.
  /// On Linux, Flutter doesn't propagate system brightness changes from GNOME,
  /// so when a brightness is detected externally (via gsettings), we use it
  /// directly instead of relying on ThemeMode.system.
  ThemeMode _getThemeMode(SettingsService settings) {
    switch (settings.themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        final detected = settings.detectedSystemBrightness;
        if (detected != null) {
          return detected == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
        }
        return ThemeMode.system;
    }
  }

  /// Build dark theme, optionally using pure black for AMOLED screens
  ThemeData _buildDarkTheme(SettingsService settings) {
    final base = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    if (settings.amoledBlack) {
      return ThemeData(
        colorScheme: base.copyWith(
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      );
    }

    return ThemeData(colorScheme: base, useMaterial3: true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final settings = SettingsService();
        return MaterialApp(
          title: 'Crossbar',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: settings.language == 'system' ? null : Locale(settings.language),
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return const Locale('en');
          },
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: _buildDarkTheme(settings),
          themeMode: _getThemeMode(settings),
          onGenerateRoute: (routeSettings) {
            final uri = Uri.parse(routeSettings.name ?? '/');
            
            // Handle widget config route: /widget/config?id=X&size=Y
            if (uri.path == '/widget/config') {
              final widgetId = int.tryParse(uri.queryParameters['id'] ?? '') ?? 0;
              final widgetSize = uri.queryParameters['size'] ?? 'small';
              
              return MaterialPageRoute(
                builder: (context) => _WidgetConfigScreen(
                  widgetId: widgetId,
                  widgetSize: widgetSize,
                ),
              );
            }
            
            // Default route
            return MaterialPageRoute(
              builder: (context) => const MainScreen(),
            );
          },
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _tabs = const [
    PluginsTab(),
    SettingsTab(),
    MarketplaceTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Restore last active tab
    final saved = SettingsService().lastTabIndex;
    _currentIndex = (saved >= 0 && saved < 3) ? saved : 0;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    SettingsService().lastTabIndex = index;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Mobile Layout (Android/iOS) - sempre usa bottom navigation
    if (Platform.isAndroid || Platform.isIOS) {
      return _buildCompactLayout(l10n);
    }

    // Desktop Layout - responsivo baseado na largura
    return LayoutBuilder(
      builder: (context, constraints) {
        // Usa layout compacto (bottom nav) quando a largura for menor que 600px
        if (constraints.maxWidth < 600) {
          return _buildCompactLayout(l10n);
        }
        // Layout expandido (side rail) para janelas maiores
        return _buildExpandedLayout(l10n);
      },
    );
  }

  /// Layout compacto com NavigationBar inferior (mobile e desktop estreito)
  Widget _buildCompactLayout(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/icon.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(l10n.appTitle),
          ],
        ),
        centerTitle: true,
        notificationPredicate: (notification) => notification.depth == 1,
        scrolledUnderElevation: 4.0,
        shadowColor: Theme.of(context).shadowColor,
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.extension_outlined),
            selectedIcon: const Icon(Icons.extension),
            label: l10n.pluginsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store),
            label: l10n.marketplaceTab,
          ),
        ],
      ),
    );
  }

  /// Layout expandido com NavigationRail lateral (desktop largo)
  Widget _buildExpandedLayout(AppLocalizations l10n) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabChanged,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/icon.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.extension_outlined),
                selectedIcon: const Icon(Icons.extension),
                label: Text(l10n.pluginsTab),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.settingsTab),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.store_outlined),
                selectedIcon: const Icon(Icons.store),
                label: Text(l10n.marketplaceTab),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),
        ],
      ),
    );
  }
}

/// Screen for widget configuration - shows dialog immediately
///
/// IMPORTANT: Uses MethodChannel to get widget parameters from native side
/// instead of relying on URL parameters from getInitialRoute().
/// This ensures correct parameters even if FlutterEngine has stale state.
class _WidgetConfigScreen extends StatefulWidget {
  const _WidgetConfigScreen({
    required this.widgetId,
    required this.widgetSize,
  });

  final int widgetId;
  final String widgetSize;

  @override
  State<_WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<_WidgetConfigScreen> {
  static const _configChannel = MethodChannel('com.verseles.crossbar/widget_config');

  int? _actualWidgetId;
  String? _actualWidgetSize;
  bool _paramsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load params from native side, then show dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadParamsAndShowDialog();
    });
  }

  Future<void> _loadParamsAndShowDialog() async {
    // Try to get params from MethodChannel (most reliable source)
    try {
      if (Platform.isAndroid) {
        final params = await _configChannel.invokeMethod<Map<Object?, Object?>>('getWidgetConfigParams');
        if (params != null && mounted) {
          _actualWidgetId = params['widgetId'] as int?;
          _actualWidgetSize = params['size'] as String?;
        }
      }
    } catch (e) {
      // Fall back to URL parameters if MethodChannel fails
      debugPrint('WidgetConfigScreen: MethodChannel failed, using URL params: $e');
    }

    // Use URL params as fallback
    _actualWidgetId ??= widget.widgetId;
    _actualWidgetSize ??= widget.widgetSize;

    if (mounted) {
      setState(() => _paramsLoaded = true);
      await _showConfigDialog();
    }
  }

  Future<void> _showConfigDialog() async {
    await WidgetConfigDialog.show(
      context: context,
      widgetId: _actualWidgetId ?? widget.widgetId,
      widgetSize: _actualWidgetSize ?? widget.widgetSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen while dialog is shown
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)?.widgetConfiguration ?? 'Widget Configuration'),
            if (_paramsLoaded) ...[
              const SizedBox(height: 8),
              Text(
                'Widget: $_actualWidgetId (${_actualWidgetSize ?? "unknown"})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

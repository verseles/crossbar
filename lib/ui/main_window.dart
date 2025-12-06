import 'dart:io';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';
import 'tabs/marketplace_tab.dart';
import 'tabs/plugins_tab.dart';
import 'tabs/settings_tab.dart';

class MainWindow extends StatelessWidget {
  const MainWindow({super.key});

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
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
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
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    PluginsTab(),
    SettingsTab(),
    MarketplaceTab(),
  ];

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
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
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
            child: _tabs[_currentIndex],
          ),
        ],
      ),
    );
  }
}

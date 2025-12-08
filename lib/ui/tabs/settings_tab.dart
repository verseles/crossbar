// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final List<Map<String, String>> _staticLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'bn', 'name': 'বাংলা'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'hi', 'name': 'हिन्दी'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
    {'code': 'pt', 'name': 'Português (Brasil)'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'zh', 'name': '中文'},
  ];

  List<Map<String, String>> _getLanguages(AppLocalizations l10n) {
    return [
      {'code': 'system', 'name': '${l10n.system} (Auto)'},
      ..._staticLanguages,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final settings = SettingsService();
        final languages = _getLanguages(l10n);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsTab),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: l10n.appearance,
                icon: Icons.palette,
                children: [
                  SwitchListTile(
                    title: Text(l10n.darkTheme),
                    subtitle: Text(l10n.useDarkTheme),
                    value: settings.darkMode,
                    onChanged: (value) {
                      settings.darkMode = value;
                    },
                  ),
                  ListTile(
                    title: Text(l10n.language),
                    subtitle: Text(languages.firstWhere(
                      (l) => l['code'] == settings.language,
                      orElse: () => languages.first,
                    )['name']!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(l10n),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.behavior,
                icon: Icons.tune,
                children: [
                  SwitchListTile(
                    title: Text(l10n.startOnBoot),
                    subtitle: Text(l10n.launchOnLogin),
                    value: settings.startWithSystem,
                    onChanged: (value) {
                      settings.startWithSystem = value;
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.minimizeToTray),
                    subtitle: Text(l10n.keepInTray),
                    value: settings.showInTray,
                    onChanged: (value) {
                      settings.showInTray = value;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.systemTray,
                icon: Icons.apps,
                children: [
                  ListTile(
                    title: Text(l10n.displayMode),
                    subtitle: Text(_getTrayModeLabel(settings.trayDisplayMode, l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTrayModeDialog(settings, l10n),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.pluginsTab,
                icon: Icons.extension,
                children: [
                  ListTile(
                    title: Text(l10n.pluginsDirectory),
                    subtitle: const Text('~/.crossbar/plugins'),
                    trailing: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () {
                        // TODO: Open folder
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(l10n.defaultRefreshInterval),
                    subtitle: Text(l10n.fiveMinutes),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Show interval picker
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.about,
                icon: Icons.info,
                children: [
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '...';
                      final buildNumber = snapshot.data?.buildNumber ?? '';
                      return ListTile(
                        title: Text(l10n.version),
                        subtitle: Text('$version${buildNumber.isNotEmpty ? '+$buildNumber' : ''}'),
                      );
                    },
                  ),
                  ListTile(
                    title: Text(l10n.license),
                    subtitle: const Text('AGPLv3'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLicenseDialog,
                  ),
                  ListTile(
                    title: const Text('GitHub'),
                    subtitle: const Text('verseles/crossbar'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      final uri = Uri.parse('https://github.com/verseles/crossbar');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  void _showLanguageDialog(AppLocalizations l10n) {
    final settings = SettingsService();
    final languages = _getLanguages(l10n);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              return RadioListTile<String>(
                title: Text(lang['name']!),
                value: lang['code']!,
                groupValue: settings.language,
                onChanged: (value) {
                  settings.language = value!;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.license),
        content: SingleChildScrollView(
          child: Text(
            l10n.licenseText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  String _getTrayModeLabel(TrayDisplayMode mode, AppLocalizations l10n) {
    switch (mode) {
      case TrayDisplayMode.unified:
        return l10n.unifiedSingleIconWithMenu;
      case TrayDisplayMode.separate:
        return l10n.separateOneIconPerPlugin;
      case TrayDisplayMode.smartCollapse:
        return l10n.smartCollapse;
      case TrayDisplayMode.smartOverflow:
        return l10n.smartOverflow;
    }
  }

  void _showTrayModeDialog(SettingsService settings, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trayDisplayMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unified - Available
            RadioListTile<TrayDisplayMode>(
              title: Text(l10n.unified),
              subtitle: Text(l10n.singleTrayIconWithMenu),
              value: TrayDisplayMode.unified,
              groupValue: settings.trayDisplayMode,
              onChanged: (value) {
                settings.trayDisplayMode = value!;
                Navigator.pop(context);
              },
            ),
            // Separate - Coming Soon (Linux only in future)
            RadioListTile<TrayDisplayMode>(
              title: Row(
                children: [
                  Text(l10n.separate),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.comingSoon,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(l10n.oneTrayIconPerPlugin),
              value: TrayDisplayMode.separate,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
            // Smart Collapse - Coming Soon
            RadioListTile<TrayDisplayMode>(
              title: Row(
                children: [
                  Text(l10n.smartCollapse),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.comingSoon,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(l10n.autoCollapseWhenManyPlugins),
              value: TrayDisplayMode.smartCollapse,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
            // Smart Overflow - Coming Soon
            RadioListTile<TrayDisplayMode>(
              title: Row(
                children: [
                  Text(l10n.smartOverflow),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.comingSoon,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(l10n.showFirstNIconsRestInOverflow),
              value: TrayDisplayMode.smartOverflow,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

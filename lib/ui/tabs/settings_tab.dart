import 'package:flutter/material.dart';
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
                title: 'System Tray',
                icon: Icons.apps,
                children: [
                  ListTile(
                    title: const Text('Display Mode'),
                    subtitle: Text(_getTrayModeLabel(settings.trayDisplayMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTrayModeDialog(settings),
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
                    subtitle: const Text('5 minutes'),
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
                  ListTile(
                    title: Text(l10n.version),
                    subtitle: const Text('1.0.0'),
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
                    onTap: () {
                      // TODO: Open GitHub
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('License'),
        content: const SingleChildScrollView(
          child: Text(
            'Crossbar - Universal Plugin System\n\n'
            'Copyright (C) 2025\n\n'
            'This program is free software: you can redistribute it and/or modify '
            'it under the terms of the GNU Affero General Public License as published '
            'by the Free Software Foundation, either version 3 of the License, or '
            '(at your option) any later version.\n\n'
            'This program is distributed in the hope that it will be useful, '
            'but WITHOUT ANY WARRANTY; without even the implied warranty of '
            'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
            'GNU Affero General Public License for more details.\n\n'
            'You should have received a copy of the GNU Affero General Public License '
            'along with this program. If not, see <https://www.gnu.org/licenses/>.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getTrayModeLabel(TrayDisplayMode mode) {
    switch (mode) {
      case TrayDisplayMode.unified:
        return 'Unified (single icon with menu)';
      case TrayDisplayMode.separate:
        return 'Separate (one icon per plugin)';
      case TrayDisplayMode.smartCollapse:
        return 'Smart Collapse';
      case TrayDisplayMode.smartOverflow:
        return 'Smart Overflow';
    }
  }

  void _showTrayModeDialog(SettingsService settings) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tray Display Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unified - Available
            RadioListTile<TrayDisplayMode>(
              title: const Text('Unified'),
              subtitle: const Text('Single tray icon with menu for all plugins'),
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
                  const Text('Separate'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('One tray icon per plugin (Linux only)'),
              value: TrayDisplayMode.separate,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
            // Smart Collapse - Coming Soon
            RadioListTile<TrayDisplayMode>(
              title: Row(
                children: [
                  const Text('Smart Collapse'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('Auto-collapse when too many plugins'),
              value: TrayDisplayMode.smartCollapse,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
            // Smart Overflow - Coming Soon
            RadioListTile<TrayDisplayMode>(
              title: Row(
                children: [
                  const Text('Smart Overflow'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: const Text('Show first N icons, rest in overflow menu'),
              value: TrayDisplayMode.smartOverflow,
              groupValue: settings.trayDisplayMode,
              onChanged: null, // Disabled
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

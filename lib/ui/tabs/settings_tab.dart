import 'package:flutter/material.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _startWithSystem = false;
  bool _showInTray = true;
  bool _darkMode = false;
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'pt_BR', 'name': 'Portugu\u00eas (Brasil)'},
    {'code': 'es', 'name': 'Espa\u00f1ol'},
    {'code': 'fr', 'name': 'Fran\u00e7ais'},
    {'code': 'zh', 'name': '\u4e2d\u6587'},
    {'code': 'hi', 'name': '\u0939\u093f\u0902\u0926\u0940'},
    {'code': 'ar', 'name': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629'},
    {'code': 'bn', 'name': '\u09ac\u09be\u0982\u09b2\u09be'},
    {'code': 'ru', 'name': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439'},
    {'code': 'ja', 'name': '\u65e5\u672c\u8a9e'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(_languages.firstWhere(
                  (l) => l['code'] == _selectedLanguage,
                  orElse: () => {'name': 'English'},
                )['name']!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Behavior',
            icon: Icons.tune,
            children: [
              SwitchListTile(
                title: const Text('Start with system'),
                subtitle: const Text('Launch Crossbar on login'),
                value: _startWithSystem,
                onChanged: (value) {
                  setState(() {
                    _startWithSystem = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show in system tray'),
                subtitle: const Text('Keep icon in tray when minimized'),
                value: _showInTray,
                onChanged: (value) {
                  setState(() {
                    _showInTray = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Plugins',
            icon: Icons.extension,
            children: [
              ListTile(
                title: const Text('Plugins Directory'),
                subtitle: const Text('~/.crossbar/plugins'),
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () {
                    // TODO: Open folder
                  },
                ),
              ),
              ListTile(
                title: const Text('Default Refresh Interval'),
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
            title: 'About',
            icon: Icons.info,
            children: [
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('License'),
                subtitle: const Text('AGPLv3'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLicenseDialog();
                },
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

  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              return RadioListTile<String>(
                title: Text(lang['name']!),
                value: lang['code']!,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
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
}

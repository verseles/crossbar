import re

with open('lib/ui/tabs/settings_tab.dart', 'r') as f:
    content = f.read()

# Replace the old method implementation with nothing to remove duplicate
content = re.sub(r"  void _showIntervalPickerDialog\(SettingsService settings, AppLocalizations l10n\) \{[\s\S]*?    \];\n\n    showAnimatedDialog<void>\([\s\S]*?    \);\n  \}\n\n", "", content)

# Also remove the duplicate _formatInterval just in case
content = re.sub(r"  String _formatInterval\(int seconds, AppLocalizations l10n\) \{[\s\S]*?    return '\$\{seconds ~\/ 86400\} d';\n  \}\n\n", "", content)

# But we need exactly one copy. So let's re-add it.

dialog_method = """  void _showIntervalPickerDialog(SettingsService settings, AppLocalizations l10n) {
    final options = [
      {'value': 60, 'label': '1 min'},
      {'value': 300, 'label': l10n.fiveMinutes},
      {'value': 900, 'label': '15 min'},
      {'value': 1800, 'label': '30 min'},
      {'value': 3600, 'label': '1 hr'},
      {'value': 7200, 'label': '2 hr'},
      {'value': 14400, 'label': '4 hr'},
      {'value': 21600, 'label': '6 hr'},
      {'value': 43200, 'label': '12 hr'},
      {'value': 86400, 'label': '24 hr'},
    ];

    showAnimatedDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.defaultRefreshInterval),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final value = option['value'] as int;
              final label = option['label'] as String;
              return RadioListTile<int>(
                title: Text(label),
                value: value,
                groupValue: settings.defaultRefreshInterval,
                onChanged: (selectedValue) {
                  if (selectedValue != null) {
                    settings.defaultRefreshInterval = selectedValue;
                    Navigator.pop(context);
                  }
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

  String _formatInterval(int seconds, AppLocalizations l10n) {
    if (seconds == 300) return l10n.fiveMinutes;
    if (seconds < 60) return '$seconds s';
    if (seconds < 3600) return '${seconds ~/ 60} m';
    if (seconds < 86400) return '${seconds ~/ 3600} h';
    return '${seconds ~/ 86400} d';
  }

"""

content = re.sub(r"(  void _showLicenseDialog\(\) \{)", dialog_method + "\\1", content)

with open('lib/ui/tabs/settings_tab.dart', 'w') as f:
    f.write(content)

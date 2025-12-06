import 'package:flutter/material.dart';

import '../../services/sample_plugins_service.dart';

/// Dialog to browse and install sample/example plugins.
class SamplePluginsDialog extends StatefulWidget {
  const SamplePluginsDialog({super.key});

  /// Shows the dialog and returns the list of installed plugins
  static Future<List<SamplePlugin>?> show(BuildContext context) {
    return showDialog<List<SamplePlugin>>(
      context: context,
      builder: (_) => const SamplePluginsDialog(),
    );
  }

  @override
  State<SamplePluginsDialog> createState() => _SamplePluginsDialogState();
}

class _SamplePluginsDialogState extends State<SamplePluginsDialog> {
  final SamplePluginsService _service = SamplePluginsService();
  final Set<String> _selectedPlugins = {};
  final Map<String, bool> _installedStatus = {};
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _loadInstalledStatus();
  }

  Future<void> _loadInstalledStatus() async {
    for (final plugin in SamplePluginsService.samplePlugins) {
      _installedStatus[plugin.id] = await _service.isInstalled(plugin.id);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<SamplePlugin> get _filteredPlugins {
    if (_selectedCategory == null) {
      return SamplePluginsService.samplePlugins;
    }
    return SamplePluginsService.samplePlugins
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  Future<void> _installSelected() async {
    if (_selectedPlugins.isEmpty) return;

    setState(() {
      _isInstalling = true;
    });

    final toInstall = SamplePluginsService.samplePlugins
        .where((p) => _selectedPlugins.contains(p.id))
        .toList();

    await _service.installMultiple(toInstall);

    if (mounted) {
      Navigator.of(context).pop(toInstall);
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'system':
        return '🖥️ System';
      case 'time':
        return '⏰ Time & Clocks';
      case 'network':
        return '🌐 Network & Web';
      case 'development':
        return '💻 Development';
      case 'productivity':
        return '📋 Productivity';
      case 'fun':
        return '🎮 Fun';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 600;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 700 : screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.extension,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Plugins',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Pre-built plugins to get you started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Category filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ..._service.categories.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getCategoryDisplayName(cat)),
                          selected: _selectedCategory == cat,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Plugin list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredPlugins.length,
                      itemBuilder: (context, index) {
                        final plugin = _filteredPlugins[index];
                        final isInstalled =
                            _installedStatus[plugin.id] ?? false;
                        final isSelected = _selectedPlugins.contains(plugin.id);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5)
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              child: Text(
                                plugin.languageIcon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(plugin.name)),
                                if (isInstalled)
                                  Chip(
                                    label: const Text('Installed'),
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onTertiary,
                                    ),
                                    backgroundColor:
                                        theme.colorScheme.tertiary,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plugin.description),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: [
                                    _InfoChip(
                                      label: plugin.language,
                                      icon: Icons.code,
                                    ),
                                    _InfoChip(
                                      label: plugin.id
                                          .split('.')
                                          .where((s) =>
                                              RegExp(r'^\d+[smh]$').hasMatch(s))
                                          .firstOrNull ??
                                          '5m',
                                      icon: Icons.timer,
                                    ),
                                    if (plugin.schemaAssetPath != null)
                                      const _InfoChip(
                                        label: 'Configurable',
                                        icon: Icons.settings,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isInstalled
                                ? null
                                : Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedPlugins.add(plugin.id);
                                        } else {
                                          _selectedPlugins.remove(plugin.id);
                                        }
                                      });
                                    },
                                  ),
                            onTap: isInstalled
                                ? null
                                : () {
                                    setState(() {
                                      if (_selectedPlugins.contains(plugin.id)) {
                                        _selectedPlugins.remove(plugin.id);
                                      } else {
                                        _selectedPlugins.add(plugin.id);
                                      }
                                    });
                                  },
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // Footer with actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_selectedPlugins.isNotEmpty)
                    Text(
                      '${_selectedPlugins.length} selected',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selectedPlugins.isEmpty || _isInstalling
                        ? null
                        : _installSelected,
                    icon: _isInstalling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isInstalling
                        ? 'Installing...'
                        : 'Install ${_selectedPlugins.length > 0 ? "(${_selectedPlugins.length})" : ""}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

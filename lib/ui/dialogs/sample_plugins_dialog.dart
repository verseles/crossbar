import 'package:flutter/material.dart';

import '../../services/sample_plugins_service.dart';

/// Dialog to browse and install sample/example plugins.
class SamplePluginsDialog extends StatefulWidget {
  const SamplePluginsDialog({super.key});

  /// Shows the dialog and returns the list of installed variant filenames
  static Future<List<String>?> show(BuildContext context) {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => const SamplePluginsDialog(),
    );
  }

  @override
  State<SamplePluginsDialog> createState() => _SamplePluginsDialogState();
}

class _SamplePluginsDialogState extends State<SamplePluginsDialog> {
  final SamplePluginsService _service = SamplePluginsService();
  final Set<String> _selectedPlugins = {}; // plugin.id
  final Map<String, bool> _installedStatus = {}; // variant.filename -> installed
  PluginCategory? _selectedCategory;
  PluginLanguage? _selectedLanguage;
  bool _isLoading = true;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _loadInstalledStatus();
  }

  Future<void> _loadInstalledStatus() async {
    for (final plugin in SamplePluginsService.allPlugins) {
      for (final variant in plugin.variants) {
        _installedStatus[variant.filename] = await _service.isInstalled(variant.filename);
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<PluginMetadata> get _filteredPlugins {
    var plugins = SamplePluginsService.allPlugins;
    
    // Filter by category
    if (_selectedCategory != null) {
      plugins = plugins.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filter by language
    if (_selectedLanguage != null) {
      plugins = plugins.where((p) => p.hasLanguage(_selectedLanguage!)).toList();
    }
    
    return plugins;
  }

  bool _isPluginInstalled(PluginMetadata plugin) {
    // A plugin is considered installed if any variant is installed
    return plugin.variants.any((v) => _installedStatus[v.filename] ?? false);
  }

  Future<void> _installSelected() async {
    if (_selectedPlugins.isEmpty) return;

    setState(() {
      _isInstalling = true;
    });

    final installedFilenames = <String>[];

    for (final pluginId in _selectedPlugins) {
      final plugin = SamplePluginsService.allPlugins.firstWhere((p) => p.id == pluginId);
      
      // Install preferred language variant, or default
      final variant = _selectedLanguage != null 
          ? plugin.getVariant(_selectedLanguage!) ?? plugin.defaultVariant
          : plugin.defaultVariant;
      
      await _service.installVariant(variant);
      installedFilenames.add(variant.filename);
    }

    if (mounted) {
      Navigator.of(context).pop(installedFilenames);
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
          maxWidth: isWide ? 750 : screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),

            // Filters
            _buildFilters(theme),

            const Divider(height: 1),

            // Plugin list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPluginList(theme),
            ),

            const Divider(height: 1),

            // Footer with actions
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
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
                  '${SamplePluginsService.universalPlugins.length} universal + '
                  '${SamplePluginsService.legacyPlugins.length} additional plugins',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories'),
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
                      label: Text('${cat.icon} ${cat.displayName}'),
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
          const SizedBox(height: 8),
          // Language filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Languages'),
                  selected: _selectedLanguage == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedLanguage = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...PluginLanguage.values.map(
                  (lang) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${lang.icon} ${lang.displayName}'),
                      selected: _selectedLanguage == lang,
                      onSelected: (_) {
                        setState(() {
                          _selectedLanguage = lang;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginList(ThemeData theme) {
    final plugins = _filteredPlugins;
    
    if (plugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No plugins match your filters',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        final isInstalled = _isPluginInstalled(plugin);
        final isSelected = _selectedPlugins.contains(plugin.id);

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                plugin.categoryIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(plugin.name)),
                if (plugin.mobileCompatible)
                  Tooltip(
                    message: 'Mobile compatible',
                    child: Icon(
                      Icons.smartphone,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 4),
                if (isInstalled)
                  Chip(
                    label: const Text('Installed'),
                    labelStyle: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onTertiary,
                    ),
                    backgroundColor: theme.colorScheme.tertiary,
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
                  runSpacing: 4,
                  children: [
                    // Show available languages
                    ...plugin.availableLanguages.map(
                      (lang) => _InfoChip(
                        label: lang.icon,
                        tooltip: lang.displayName,
                      ),
                    ),
                    // Show interval from default variant
                    _InfoChip(
                      label: _extractInterval(plugin.defaultVariant.filename),
                      icon: Icons.timer,
                    ),
                    if (plugin.configRequired)
                      const _InfoChip(
                        label: 'Config',
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
    );
  }

  String _extractInterval(String filename) {
    final match = RegExp(r'\.(\d+[smh])\.').firstMatch(filename);
    return match?.group(1) ?? '5m';
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_selectedPlugins.isNotEmpty) ...[
            Text(
              '${_selectedPlugins.length} selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedLanguage != null) ...[
              const SizedBox(width: 8),
              Text(
                '(${_selectedLanguage!.displayName})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
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
                : 'Install ${_selectedPlugins.isNotEmpty ? "(${_selectedPlugins.length})" : ""}'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.icon,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
          ],
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
    
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

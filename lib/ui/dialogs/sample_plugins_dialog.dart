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
  final Map<String, bool> _installedStatus = {}; // variant.filename -> installed
  final Map<String, PluginLanguage> _selectedLanguages = {}; // plugin.id -> language
  final Set<String> _installingPlugins = {}; // plugin.id being installed
  final List<String> _installedFilenames = []; // track what we installed
  PluginCategory? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledStatus();
  }

  Future<void> _loadInstalledStatus() async {
    for (final plugin in SamplePluginsService.allPlugins) {
      // Set default language to bash (or first available)
      _selectedLanguages[plugin.id] = plugin.hasLanguage(PluginLanguage.bash)
          ? PluginLanguage.bash
          : plugin.variants.first.language;
      
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
    
    return plugins;
  }

  bool _isPluginInstalled(PluginMetadata plugin) {
    // A plugin is considered installed if any variant is installed
    return plugin.variants.any((v) => _installedStatus[v.filename] ?? false);
  }

  Future<void> _installPlugin(PluginMetadata plugin) async {
    final language = _selectedLanguages[plugin.id] ?? plugin.defaultVariant.language;
    final variant = plugin.getVariant(language) ?? plugin.defaultVariant;
    
    setState(() {
      _installingPlugins.add(plugin.id);
    });
    
    try {
      await _service.installVariant(variant);
      _installedStatus[variant.filename] = true;
      _installedFilenames.add(variant.filename);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installed ${plugin.name} (${language.displayName})'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${plugin.name}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _installingPlugins.remove(plugin.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWide = screenSize.width > 600;
    final isSmallScreen = screenSize.width < 500;

    // Use full screen on small screens (mobile-like)
    if (isSmallScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sample Plugins'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(_installedFilenames.isNotEmpty ? _installedFilenames : null),
          ),
        ),
        body: Column(
          children: [
            // Category filter
            _buildCategoryFilter(theme),
            const Divider(height: 1),
            // Plugin list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPluginList(theme),
            ),
            const Divider(height: 1),
            // Footer
            _buildFooter(theme),
          ],
        ),
      );
    }

    // Dialog for larger screens
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 800 : screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),

            // Category filter only
            _buildCategoryFilter(theme),

            const Divider(height: 1),

            // Plugin list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPluginList(theme),
            ),

            const Divider(height: 1),

            // Footer
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
            onPressed: () => Navigator.of(context).pop(_installedFilenames.isNotEmpty ? _installedFilenames : null),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return Padding(
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
        final isInstalling = _installingPlugins.contains(plugin.id);
        final selectedLang = _selectedLanguages[plugin.id] ?? plugin.defaultVariant.language;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Text(
                        plugin.categoryIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plugin.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              if (plugin.mobileCompatible) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Mobile compatible',
                                  child: Icon(
                                    Icons.smartphone,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                              if (isInstalled) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Installed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            plugin.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action row: Language selector + Install button
                Row(
                  children: [
                    // Language dropdown
                    if (plugin.variants.length > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PluginLanguage>(
                            value: selectedLang,
                            isDense: true,
                            items: plugin.availableLanguages.map((lang) {
                              return DropdownMenuItem(
                                value: lang,
                                child: Text(
                                  '${lang.icon} ${lang.displayName}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: isInstalled ? null : (lang) {
                              if (lang != null) {
                                setState(() {
                                  _selectedLanguages[plugin.id] = lang;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      // Single language - just show a chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${selectedLang.icon} ${selectedLang.displayName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Interval chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 12, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            _extractInterval(plugin.defaultVariant.filename),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (plugin.configRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, size: 12, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              'Config',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Install button
                    if (isInstalling)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!isInstalled)
                      FilledButton.tonal(
                        onPressed: () => _installPlugin(plugin),
                        child: const Text('Install'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractInterval(String filename) {
    final match = RegExp(r'\.(\d+[smhd])\.').firstMatch(filename);
    return match?.group(1) ?? '5m';
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_installedFilenames.isNotEmpty)
            Text(
              '${_installedFilenames.length} installed this session',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_installedFilenames.isNotEmpty ? _installedFilenames : null),
            child: Text(_installedFilenames.isNotEmpty ? 'Done' : 'Close'),
          ),
        ],
      ),
    );
  }
}

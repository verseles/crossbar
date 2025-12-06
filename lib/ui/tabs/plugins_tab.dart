import 'package:flutter/material.dart';

import '../../core/plugin_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plugin.dart';
import '../../models/plugin_output.dart';
import '../../services/plugin_config_service.dart';
import '../../services/tray_service.dart';
import '../dialogs/plugin_config_dialog.dart';
import '../dialogs/sample_plugins_dialog.dart';

/// Redesigned Plugins Tab with:
/// - Search & filtering
/// - Sorting (enabled first, alphabetical)
/// - Grouping options (language, configurable)
/// - Expandable plugin cards with live output preview
class PluginsTab extends StatefulWidget {
  const PluginsTab({super.key});

  @override
  State<PluginsTab> createState() => _PluginsTabState();
}

enum PluginSortOrder { enabledFirst, alphabetical, lastRun, interval }
enum PluginGroupBy { none, language, configurable }

class _PluginsTabState extends State<PluginsTab> {
  final PluginManager _pluginManager = PluginManager();
  final PluginConfigService _configService = PluginConfigService();
  
  bool _isLoading = true;
  String _searchQuery = '';
  PluginSortOrder _sortOrder = PluginSortOrder.enabledFirst;
  PluginGroupBy _groupBy = PluginGroupBy.none;
  String? _expandedPluginId;
  final Map<String, PluginOutput?> _pluginOutputs = {};
  final Map<String, bool> _runningPlugins = {};

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    await _pluginManager.discoverPlugins();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPlugins() async {
    setState(() {
      _isLoading = true;
    });
    _pluginManager.clear();
    _pluginOutputs.clear();
    await _loadPlugins();
  }

  List<Plugin> get _filteredAndSortedPlugins {
    var plugins = _pluginManager.plugins.toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      plugins = plugins.where((p) {
        return p.id.toLowerCase().contains(query) ||
               p.interpreter.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply sorting
    plugins.sort((a, b) {
      switch (_sortOrder) {
        case PluginSortOrder.enabledFirst:
          if (a.enabled != b.enabled) {
            return a.enabled ? -1 : 1;
          }
          return a.id.toLowerCase().compareTo(b.id.toLowerCase());
        case PluginSortOrder.alphabetical:
          return a.id.toLowerCase().compareTo(b.id.toLowerCase());
        case PluginSortOrder.lastRun:
          final aRun = a.lastRun ?? DateTime(1970);
          final bRun = b.lastRun ?? DateTime(1970);
          return bRun.compareTo(aRun);
        case PluginSortOrder.interval:
          return a.refreshInterval.compareTo(b.refreshInterval);
      }
    });
    
    return plugins;
  }

  Map<String, List<Plugin>> get _groupedPlugins {
    final plugins = _filteredAndSortedPlugins;
    
    if (_groupBy == PluginGroupBy.none) {
      return {'All': plugins};
    }
    
    final groups = <String, List<Plugin>>{};
    
    for (final plugin in plugins) {
      String groupKey;
      switch (_groupBy) {
        case PluginGroupBy.language:
          groupKey = _getLanguageDisplayName(plugin.interpreter);
        case PluginGroupBy.configurable:
          groupKey = plugin.hasConfig ? 'Configurable' : 'Standard';
        case PluginGroupBy.none:
          groupKey = 'All';
      }
      groups.putIfAbsent(groupKey, () => []).add(plugin);
    }
    
    return groups;
  }

  String _getLanguageDisplayName(String interpreter) {
    switch (interpreter) {
      case 'bash':
      case 'sh':
        return '🐚 Bash';
      case 'python3':
      case 'python':
        return '🐍 Python';
      case 'node':
        return '📦 Node.js';
      case 'dart':
        return '🎯 Dart';
      case 'go':
        return '🐹 Go';
      case 'rust':
        return '🦀 Rust';
      default:
        return '📄 $interpreter';
    }
  }

  String _getLanguageIcon(String interpreter) {
    switch (interpreter) {
      case 'bash':
      case 'sh':
        return '🐚';
      case 'python3':
      case 'python':
        return '🐍';
      case 'node':
        return '📦';
      case 'dart':
        return '🎯';
      case 'go':
        return '🐹';
      case 'rust':
        return '🦀';
      default:
        return '📄';
    }
  }

  Future<void> _runPlugin(Plugin plugin) async {
    setState(() {
      _runningPlugins[plugin.id] = true;
    });
    
    try {
      final output = await _pluginManager.runPlugin(plugin.id);
      if (mounted) {
        setState(() {
          _pluginOutputs[plugin.id] = output;
          _runningPlugins[plugin.id] = false;
        });
        
        // Update tray if available
        if (output != null) {
          TrayService().updatePluginOutput(plugin.id, output);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _runningPlugins[plugin.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(theme, l10n),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pluginManager.plugins.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildPluginList(theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPluginDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPlugin),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search plugins...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort dropdown
                PopupMenuButton<PluginSortOrder>(
                  initialValue: _sortOrder,
                  onSelected: (value) => setState(() => _sortOrder = value),
                  child: Chip(
                    avatar: const Icon(Icons.sort, size: 18),
                    label: Text(_getSortOrderLabel()),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: PluginSortOrder.enabledFirst,
                      child: Text('Enabled First'),
                    ),
                    const PopupMenuItem(
                      value: PluginSortOrder.alphabetical,
                      child: Text('Alphabetical'),
                    ),
                    const PopupMenuItem(
                      value: PluginSortOrder.lastRun,
                      child: Text('Last Run'),
                    ),
                    const PopupMenuItem(
                      value: PluginSortOrder.interval,
                      child: Text('Interval'),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Group by dropdown
                PopupMenuButton<PluginGroupBy>(
                  initialValue: _groupBy,
                  onSelected: (value) => setState(() => _groupBy = value),
                  child: Chip(
                    avatar: const Icon(Icons.folder_outlined, size: 18),
                    label: Text(_getGroupByLabel()),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: PluginGroupBy.none,
                      child: Text('No Grouping'),
                    ),
                    const PopupMenuItem(
                      value: PluginGroupBy.language,
                      child: Text('By Language'),
                    ),
                    const PopupMenuItem(
                      value: PluginGroupBy.configurable,
                      child: Text('By Configurable'),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Quick filters
                FilterChip(
                  label: const Text('Enabled'),
                  selected: _sortOrder == PluginSortOrder.enabledFirst,
                  onSelected: (_) => setState(() {
                    _sortOrder = PluginSortOrder.enabledFirst;
                  }),
                ),
                
                const SizedBox(width: 8),
                
                // Refresh button
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  onPressed: _isLoading ? null : _refreshPlugins,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOrderLabel() {
    switch (_sortOrder) {
      case PluginSortOrder.enabledFirst:
        return 'Enabled First';
      case PluginSortOrder.alphabetical:
        return 'A-Z';
      case PluginSortOrder.lastRun:
        return 'Last Run';
      case PluginSortOrder.interval:
        return 'Interval';
    }
  }

  String _getGroupByLabel() {
    switch (_groupBy) {
      case PluginGroupBy.none:
        return 'No Groups';
      case PluginGroupBy.language:
        return 'By Language';
      case PluginGroupBy.configurable:
        return 'Configurable';
    }
  }

  Widget _buildPluginList(ThemeData theme) {
    final groups = _groupedPlugins;
    
    if (_filteredAndSortedPlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No plugins match "$_searchQuery"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final groupName = groups.keys.elementAt(groupIndex);
        final groupPlugins = groups[groupName]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header (only if grouping is enabled)
            if (_groupBy != PluginGroupBy.none) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      groupName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${groupPlugins.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Plugin cards
            ...groupPlugins.map((plugin) => _buildExpandablePluginCard(
              context,
              plugin,
              theme,
            )),
          ],
        );
      },
    );
  }

  Widget _buildExpandablePluginCard(
    BuildContext context,
    Plugin plugin,
    ThemeData theme,
  ) {
    final isExpanded = _expandedPluginId == plugin.id;
    final output = _pluginOutputs[plugin.id];
    final isRunning = _runningPlugins[plugin.id] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main card content (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedPluginId = isExpanded ? null : plugin.id;
              });
              // Auto-run plugin when expanded if no output yet
              if (!isExpanded && output == null && plugin.enabled) {
                _runPlugin(plugin);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Language icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: plugin.enabled
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getLanguageIcon(plugin.interpreter),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Plugin info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatPluginName(plugin.id),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (plugin.hasConfig)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.settings,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildInfoChip(
                              theme,
                              _formatInterval(plugin.refreshInterval),
                              Icons.timer_outlined,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              theme,
                              plugin.interpreter,
                              Icons.code,
                            ),
                            if (plugin.lastRun != null) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                theme,
                                _formatTimeAgo(plugin.lastRun!),
                                Icons.history,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Toggle switch
                  Switch(
                    value: plugin.enabled,
                    onChanged: (_) async {
                      await _pluginManager.togglePlugin(plugin.id);
                      setState(() {});
                    },
                  ),
                  
                  // Expand indicator
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (isExpanded)
            _buildExpandedContent(context, plugin, theme, output, isRunning),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildExpandedContent(
    BuildContext context,
    Plugin plugin,
    ThemeData theme,
    PluginOutput? output,
    bool isRunning,
  ) {
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Output Preview Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.terminal,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Output',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Run button
                    FilledButton.tonalIcon(
                      onPressed: isRunning ? null : () => _runPlugin(plugin),
                      icon: isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow, size: 18),
                      label: Text(isRunning ? 'Running...' : 'Run Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Output display
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: _buildOutputContent(theme, output, isRunning),
                ),
              ],
            ),
          ),
          
          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(theme, 'Path', plugin.path),
                _buildDetailRow(
                  theme,
                  'Interval',
                  _formatInterval(plugin.refreshInterval),
                ),
                _buildDetailRow(theme, 'Interpreter', plugin.interpreter),
                if (plugin.lastRun != null)
                  _buildDetailRow(
                    theme,
                    'Last Run',
                    _formatDateTime(plugin.lastRun!),
                  ),
                if (plugin.lastError != null)
                  _buildDetailRow(
                    theme,
                    'Last Error',
                    plugin.lastError!,
                    isError: true,
                  ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (plugin.hasConfig)
                  OutlinedButton.icon(
                    onPressed: () => _showConfigDialog(context, plugin),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Configure'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _pluginManager.togglePlugin(plugin.id);
                    setState(() {});
                  },
                  icon: Icon(
                    plugin.enabled ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(plugin.enabled ? 'Disable' : 'Enable'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputContent(
    ThemeData theme,
    PluginOutput? output,
    bool isRunning,
  ) {
    if (isRunning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Executing plugin...',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    if (output == null) {
      return Center(
        child: Text(
          'Click "Run Now" to see output',
          style: TextStyle(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    if (output.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 18),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            output.errorMessage ?? 'Unknown error',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.red[300],
            ),
          ),
        ],
      );
    }
    
    // Successful output - show icon and text
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (output.icon.isNotEmpty) ...[
          Text(
            output.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                output.text ?? '--',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: output.color != null
                      ? Color(output.color!)
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (output.trayTooltip != null) ...[
                const SizedBox(height: 4),
                Text(
                  output.trayTooltip!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (output.menu.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...output.menu.take(5).map((item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• ${item.text ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )),
                if (output.menu.length > 5)
                  Text(
                    '... and ${output.menu.length - 5} more',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noPluginsFound,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noPluginsDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddPluginDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addPlugin),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfigDialog(BuildContext context, Plugin plugin) async {
    if (plugin.config == null) return;

    final currentValues = await _configService.loadValues(
      plugin.id,
      schema: plugin.config,
    );

    if (!mounted) return;

    final newValues = await PluginConfigDialog.show(
      context: context,
      plugin: plugin,
      config: plugin.config!,
      initialValues: currentValues,
    );

    if (newValues != null) {
      await _configService.saveValues(
        plugin.id,
        newValues,
        schema: plugin.config,
      );

      // Re-run plugin immediately
      _runPlugin(plugin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAddPluginDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPlugin),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sample Plugins option (primary)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    final installed = await SamplePluginsDialog.show(context);
                    if (installed != null && installed.isNotEmpty && mounted) {
                      await _refreshPlugins();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${installed.length} plugin(s) installed successfully!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.extension,
                            color: theme.colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sample Plugins',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose from 20+ ready-to-use plugins',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                ],
              ),

              const SizedBox(height: 16),

              // Manual creation instructions
              Text(
                'Create your own plugin:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              Text(
                '1. Create a script in one of these languages:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLanguageChip(l10n.bash, '.sh'),
                  _buildLanguageChip(l10n.python, '.py'),
                  _buildLanguageChip(l10n.node, '.js'),
                  _buildLanguageChip(l10n.dart, '.dart'),
                  _buildLanguageChip(l10n.go, '.go'),
                  _buildLanguageChip(l10n.rust, '.rs'),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                '2. Name it with refresh interval:',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'cpu.10s.sh  # runs every 10 seconds\n'
                  'weather.5m.py  # runs every 5 minutes\n'
                  'backup.1h.sh  # runs every hour',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                '3. Place it in ~/.crossbar/plugins/',
                style: theme.textTheme.bodySmall,
              ),
            ],
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

  Widget _buildLanguageChip(String label, String extension) {
    return Chip(
      label: Text('$label ($extension)'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _formatPluginName(String pluginId) {
    // Convert "cpu.10s.sh" to "CPU"
    // or "my-plugin.5m.py" to "My Plugin"
    final name = pluginId.split('.').first;
    return name
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  String _formatInterval(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

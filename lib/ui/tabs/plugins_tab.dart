import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:crossbar_core/crossbar_core.dart';
import '../../core/plugin_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../services/plugin_config_service.dart';
import '../../services/refresh_service.dart';
import '../../services/scheduler_service.dart';
import '../../services/tray_service.dart';
import '../dialogs/plugin_config_dialog.dart';
import '../dialogs/sample_plugins_dialog.dart';

/// Redesigned Plugins Tab with:
/// - Search & filtering
/// - Sorting (enabled first, alphabetical)
/// - Grouping options (language, configurable)
/// - Expandable plugin cards with live output preview
/// - Synchronized with RefreshService (single source of truth)
class PluginsTab extends StatefulWidget {
  const PluginsTab({super.key});

  @override
  State<PluginsTab> createState() => _PluginsTabState();
}

enum PluginSortOrder { enabledFirst, alphabetical, lastRun, interval }
enum PluginGroupBy { none, language, configurable }

class _PluginsTabState extends State<PluginsTab> {
  final RefreshService _refreshService = RefreshService();
  final PluginConfigService _configService = PluginConfigService();
  final SchedulerService _schedulerService = SchedulerService();

  bool _isLoading = true;
  String _searchQuery = '';
  PluginSortOrder _sortOrder = PluginSortOrder.enabledFirst;
  PluginGroupBy _groupBy = PluginGroupBy.none;
  String? _expandedPluginId;
  final Map<String, bool> _runningPlugins = {};
  String? _pendingDeletePluginId;
  DateTime? _pendingDeleteTime;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    // Listen for refresh updates from any source (scheduler, IPC, etc.)
    _refreshService.addOutputListener(_onPluginOutput);
    _refreshService.addListChangedListener(_onPluginListChanged);
  }

  @override
  void dispose() {
    _refreshService.removeOutputListener(_onPluginOutput);
    _refreshService.removeListChangedListener(_onPluginListChanged);
    super.dispose();
  }

  /// Called when any plugin output is updated (from any source)
  void _onPluginOutput(String pluginId, PluginOutput output) {
    if (mounted) {
      setState(() {
        // Output is already cached in RefreshService, just trigger rebuild
      });
    }
  }

  /// Called when plugin list changes (enable/disable/add/remove)
  void _onPluginListChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPlugins() async {
    await _refreshService.discoverPlugins();
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
    PluginManager().clear();
    await _loadPlugins();
  }

  List<Plugin> get _filteredAndSortedPlugins {
    var plugins = _refreshService.plugins.toList();

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
      // Use RefreshService - this will notify all listeners including Tray
      await _refreshService.runPlugin(plugin.id);
      if (mounted) {
        setState(() {
          _runningPlugins[plugin.id] = false;
        });
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
                : _refreshService.plugins.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildPluginList(theme, l10n),
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
              hintText: l10n.searchPlugins,
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
                    label: Text(_getSortOrderLabel(l10n)),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: PluginSortOrder.enabledFirst,
                      child: Text(l10n.enabledFirst),
                    ),
                    PopupMenuItem(
                      value: PluginSortOrder.alphabetical,
                      child: Text(l10n.alphabetical),
                    ),
                    PopupMenuItem(
                      value: PluginSortOrder.lastRun,
                      child: Text(l10n.lastRun),
                    ),
                    PopupMenuItem(
                      value: PluginSortOrder.interval,
                      child: Text(l10n.interval),
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
                    label: Text(_getGroupByLabel(l10n)),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: PluginGroupBy.none,
                      child: Text(l10n.noGrouping),
                    ),
                    PopupMenuItem(
                      value: PluginGroupBy.language,
                      child: Text(l10n.byLanguage),
                    ),
                    PopupMenuItem(
                      value: PluginGroupBy.configurable,
                      child: Text(l10n.byConfigurable),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                // Quick filters
                FilterChip(
                  label: Text(l10n.enabled),
                  selected: _sortOrder == PluginSortOrder.enabledFirst,
                  onSelected: (_) => setState(() {
                    _sortOrder = PluginSortOrder.enabledFirst;
                  }),
                ),

                const SizedBox(width: 8),

                // Refresh button
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.refresh),
                  onPressed: _isLoading ? null : _refreshPlugins,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOrderLabel(AppLocalizations l10n) {
    switch (_sortOrder) {
      case PluginSortOrder.enabledFirst:
        return l10n.enabledFirst;
      case PluginSortOrder.alphabetical:
        return 'A-Z';
      case PluginSortOrder.lastRun:
        return l10n.lastRun;
      case PluginSortOrder.interval:
        return l10n.interval;
    }
  }

  String _getGroupByLabel(AppLocalizations l10n) {
    switch (_groupBy) {
      case PluginGroupBy.none:
        return l10n.noGroups;
      case PluginGroupBy.language:
        return l10n.byLanguage;
      case PluginGroupBy.configurable:
        return l10n.configurable;
    }
  }

  Widget _buildPluginList(ThemeData theme, AppLocalizations l10n) {
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
              l10n.noPluginsMatch(_searchQuery),
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
              l10n,
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
    AppLocalizations l10n,
  ) {
    final isExpanded = _expandedPluginId == plugin.id;
    // Use RefreshService as single source of truth for output
    final output = _refreshService.getLastOutput(plugin.id);
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
                            if (plugin.variants.length > 1) ...[
                              const SizedBox(width: 8),
                              _buildLanguageDropdown(theme, plugin),
                            ],
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
                    onChanged: (_) => _handleTogglePlugin(plugin),
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
            _buildExpandedContent(context, plugin, theme, output, isRunning, l10n),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(ThemeData theme, Plugin plugin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      height: 20,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<PluginVariant>(
        value: plugin.variants.firstWhere((v) => v.path == plugin.path),
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, size: 14, color: theme.colorScheme.primary),
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        onChanged: (variant) {
          if (variant != null) {
            _refreshService.switchPluginVariant(plugin.id, variant);
          }
        },
        items: plugin.variants.map((v) {
          return DropdownMenuItem(
            value: v,
            child: Text(v.interpreter.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }

  /// Handle plugin toggle with proper synchronization
  Future<void> _handleTogglePlugin(Plugin plugin) async {
    // Use RefreshService for toggle - this ensures scheduler is notified
    await _refreshService.togglePlugin(plugin.id);

    // Reschedule timer
    _schedulerService.reschedulePlugin(plugin.id);

    // Refresh tray menu
    await TrayService().refreshMenu();

    if (mounted) {
      setState(() {});
    }
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
    AppLocalizations l10n,
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
                      l10n.liveOutput,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Copy button
                    if (output != null)
                      IconButton(
                        onPressed: () => _copyOutput(output),
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: l10n.copyOutput,
                      ),
                    const SizedBox(width: 4),
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
                      label: Text(isRunning ? l10n.running : l10n.runNow),
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
                _buildDetailRow(theme, l10n.path, plugin.path),
                _buildDetailRow(
                  theme,
                  l10n.interval,
                  _formatInterval(plugin.refreshInterval),
                ),
                _buildDetailRow(theme, l10n.interpreter, plugin.interpreter),
                if (plugin.lastRun != null)
                  _buildDetailRow(
                    theme,
                    l10n.lastRun,
                    _formatDateTime(plugin.lastRun!),
                  ),
                if (plugin.lastError != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          theme,
                          l10n.lastError,
                          plugin.lastError!,
                          isError: true,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successMessage = l10n.errorCopiedToClipboard;
                          await FlutterClipboard.copy(plugin.lastError!);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(successMessage)),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy error',
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
                    label: Text(l10n.configure),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _handleTogglePlugin(plugin),
                  icon: Icon(
                    plugin.enabled ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(plugin.enabled ? l10n.disable : l10n.enable),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editPlugin(plugin),
                  icon: const Icon(Icons.edit, size: 18),
                    label: Text(l10n.edit),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleDeleteClick(context, plugin),
                  icon: Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                    label: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

    // Capture context-dependent objects before async gap
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final currentValues = await _configService.loadValues(
      plugin.id,
      schema: plugin.config,
    );

    if (!context.mounted) return;

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

      // Re-run plugin immediately via RefreshService
      if (!mounted) return;
      await _runPlugin(plugin);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.configurationSaved),
            duration: const Duration(seconds: 2),
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
                    // Always refresh to pick up any installed plugins
                    if (!context.mounted) return;
                    await _refreshPlugins();
                    await TrayService().refreshMenu();
                    if (!context.mounted) return;
                    if (installed != null && installed.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.pluginsInstalledSuccess(installed.length),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
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
                                l10n.samplePlugins,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.chooseFromPlugins,
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
                      l10n.or,
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
                l10n.createYourOwnPlugin,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              Text(
                l10n.createScriptStep,
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
                l10n.nameWithIntervalStep,
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
                l10n.placeInPluginsStep,
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

  /// Opens the plugin file in the system's default editor
  Future<void> _editPlugin(Plugin plugin) async {
    final file = File(plugin.path);
    // ignore: avoid_slow_async_io
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pluginFileNotFound)),
        );
      }
      return;
    }

    // Use xdg-open on Linux, open on macOS, start on Windows
    final String command;
    final List<String> args;

    if (Platform.isLinux) {
      command = 'xdg-open';
      args = [plugin.path];
    } else if (Platform.isMacOS) {
      command = 'open';
      args = ['-e', plugin.path]; // -e opens in TextEdit
    } else if (Platform.isWindows) {
      command = 'notepad';
      args = [plugin.path];
    } else {
      // Fallback: try to launch as file:// URI
      final uri = Uri.file(plugin.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    try {
      await Process.run(command, args);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenEditor(e.toString()))),
        );
      }
    }
  }

  /// Handle delete button click - requires double-click to confirm
  void _handleDeleteClick(BuildContext context, Plugin plugin) {
    final now = DateTime.now();

    // Check if this is a "second click" within 3 seconds
    if (_pendingDeletePluginId == plugin.id &&
        _pendingDeleteTime != null &&
        now.difference(_pendingDeleteTime!).inSeconds < 3) {
      // Second click - delete the plugin
      _pendingDeletePluginId = null;
      _pendingDeleteTime = null;
      _deletePlugin(context, plugin);
    } else {
      // First click - show toast and wait for confirmation
      _pendingDeletePluginId = plugin.id;
      _pendingDeleteTime = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.clickDeleteAgain(_formatPluginName(plugin.id))),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Actually delete the plugin
  Future<void> _deletePlugin(BuildContext context, Plugin plugin) async {
    // Capture context-dependent objects before async gap
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pluginName = _formatPluginName(plugin.id);

    try {
      final file = File(plugin.path);
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        await file.delete();
      }

      // Also delete schema file if exists
      final schemaFile = File('${plugin.path}.schema.json');
      // ignore: avoid_slow_async_io
      if (await schemaFile.exists()) {
        await schemaFile.delete();
      }

      // Clear plugin output from cache
      _refreshService.clearOutput(plugin.id);

      // Refresh plugin list and tray
      await _refreshPlugins();
      await TrayService().refreshMenu();

      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.deletedPlugin(pluginName))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToDeletePlugin(e.toString()))),
        );
      }
    }
  }

  /// Copies the plugin output to clipboard
  Future<void> _copyOutput(PluginOutput output) async {
    // Capture context-dependent objects before async gap
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final buffer = StringBuffer();

    if (output.icon.isNotEmpty) {
      buffer.write('${output.icon} ');
    }
    buffer.writeln(output.text ?? '');

    if (output.trayTooltip != null) {
      buffer.writeln(output.trayTooltip!);
    }

    for (final item in output.menu) {
      if (item.text != null) {
        buffer.writeln('• ${item.text}');
      }
    }

    if (output.errorMessage != null) {
      buffer.writeln('Error: ${output.errorMessage}');
    }

    await FlutterClipboard.copy(buffer.toString());

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.outputCopiedToClipboard)),
      );
    }
  }
}

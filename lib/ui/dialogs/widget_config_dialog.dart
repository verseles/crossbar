import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/plugin_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plugin.dart';

/// Dialog for configuring which plugins to display in a widget.
/// 
/// - Small/Medium widgets: single plugin selection (radio behavior)
/// - Large widgets: multi-plugin selection with scrolling
class WidgetConfigDialog extends StatefulWidget {
  const WidgetConfigDialog({
    required this.widgetId,
    required this.widgetSize,
    super.key,
  });

  final int widgetId;
  final String widgetSize;

  /// Shows the dialog and returns the selected plugin IDs, or null if cancelled.
  static Future<List<String>?> show({
    required BuildContext context,
    required int widgetId,
    required String widgetSize,
  }) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WidgetConfigDialog(
        widgetId: widgetId,
        widgetSize: widgetSize,
      ),
    );
  }

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  static const _configChannel = MethodChannel('com.verseles.crossbar/widget_config');
  
  final Set<String> _selectedPlugins = {};
  List<Plugin> _availablePlugins = [];
  bool _isLoading = true;

  bool get _isLarge => widget.widgetSize == 'large';

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    final pluginManager = PluginManager();
    
    // Ensure plugins are discovered
    if (pluginManager.plugins.isEmpty) {
      await pluginManager.discoverPlugins();
    }
    
    setState(() {
      _availablePlugins = pluginManager.plugins.where((p) => p.enabled).toList();
      _isLoading = false;
    });
  }

  void _togglePlugin(String pluginId) {
    setState(() {
      if (_selectedPlugins.contains(pluginId)) {
        _selectedPlugins.remove(pluginId);
      } else {
        if (_isLarge) {
          // Large: multi-select
          _selectedPlugins.add(pluginId);
        } else {
          // Small/Medium: single select (replace)
          _selectedPlugins.clear();
          _selectedPlugins.add(pluginId);
        }
      }
    });
  }

  Future<void> _saveConfig() async {
    if (_selectedPlugins.isEmpty) return;

    try {
      if (Platform.isAndroid) {
        await _configChannel.invokeMethod('saveWidgetConfig', {
          'widgetId': widget.widgetId,
          'pluginIds': _selectedPlugins.toList(),
        });
      }
      
      if (mounted) {
        Navigator.of(context).pop(_selectedPlugins.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving config: $e')),
        );
      }
    }
  }

  Future<void> _cancelConfig() async {
    try {
      if (Platform.isAndroid) {
        await _configChannel.invokeMethod('cancelWidgetConfig');
      }
    } catch (_) {
      // Ignore errors on cancel
    }
    
    if (mounted) {
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, l10n),
            const Divider(height: 1),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availablePlugins.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : _buildPluginList(theme),
            ),
            const Divider(height: 1),
            _buildActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    final title = _isLarge
        ? l10n.selectPlugins
        : l10n.selectOnePlugin;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.widgets_outlined,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.widgetConfiguration,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension_off,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPluginsAvailable,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPluginList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _availablePlugins.length,
      itemBuilder: (context, index) {
        final plugin = _availablePlugins[index];
        final isSelected = _selectedPlugins.contains(plugin.id);
        
        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => _togglePlugin(plugin.id),
          title: Text(_formatPluginName(plugin.id)),
          subtitle: Text(
            '${plugin.interpreter} • ${_formatInterval(plugin.refreshInterval)}',
            style: theme.textTheme.bodySmall,
          ),
          secondary: Icon(
            isSelected ? Icons.extension : Icons.extension_outlined,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          controlAffinity: ListTileControlAffinity.trailing,
        );
      },
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _cancelConfig,
            child: Text(l10n.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _selectedPlugins.isNotEmpty ? _saveConfig : null,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  String _formatPluginName(String pluginId) {
    return pluginId
        .replaceAll(RegExp(r'\.\d+[smh]\..*$'), '')
        .replaceFirstMapped(RegExp('^.'), (m) => m.group(0)!.toUpperCase());
  }

  String _formatInterval(Duration duration) {
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }
}

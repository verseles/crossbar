import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/plugin_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plugin.dart';

/// Dialog for configuring which plugins to display in a home screen widget.
///
/// Shows a list of available plugins with checkboxes.
/// The number of selectable plugins depends on widget size:
/// - Small/Medium: 1 plugin only
/// - Large: up to 4 plugins
class WidgetConfigDialog extends StatefulWidget {
  const WidgetConfigDialog({
    required this.widgetId,
    required this.widgetSize,
    super.key,
  });

  final int widgetId;
  final String widgetSize;

  static const _channel = MethodChannel('com.verseles.crossbar/widget_config');

  /// Show the widget configuration dialog.
  /// Returns true if configuration was saved, false if cancelled.
  static Future<bool> show(
    BuildContext context,
    int widgetId,
    String widgetSize,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WidgetConfigDialog(
        widgetId: widgetId,
        widgetSize: widgetSize,
      ),
    );
    return result ?? false;
  }

  @override
  State<WidgetConfigDialog> createState() => _WidgetConfigDialogState();
}

class _WidgetConfigDialogState extends State<WidgetConfigDialog> {
  final PluginManager _pluginManager = PluginManager();
  final Set<String> _selectedPlugins = {};
  List<Plugin> _plugins = [];
  bool _loading = true;

  int get _maxPlugins {
    switch (widget.widgetSize.toLowerCase()) {
      case 'large':
        return 4;
      case 'medium':
      case 'small':
      default:
        return 1;
    }
  }

  String get _widgetSizeLabel {
    switch (widget.widgetSize.toLowerCase()) {
      case 'large':
        return 'Large (2x2)';
      case 'medium':
        return 'Medium (2x1)';
      case 'small':
      default:
        return 'Small (1x1)';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    try {
      await _pluginManager.discoverPlugins();

      // Load existing selection for this widget if any
      final existing = await HomeWidget.getWidgetData<String>(
        'widget_${widget.widgetId}_plugins',
      );
      if (existing != null) {
        try {
          final List<dynamic> savedPlugins = jsonDecode(existing);
          _selectedPlugins.addAll(savedPlugins.map((e) => e.toString()));
        } catch (_) {
          // Ignore invalid saved data
        }
      }

      if (!mounted) return;
      
      setState(() {
        _plugins = _pluginManager.plugins.where((p) => p.enabled).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        _loading = false;
      });
    } catch (e) {
      // If loading fails, still show the dialog but with empty list
      if (!mounted) return;
      setState(() {
        _plugins = [];
        _loading = false;
      });
    }
  }

  Future<void> _saveAndClose() async {
    if (_selectedPlugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.selectAtLeastOnePlugin ??
              'Select at least one plugin'),
        ),
      );
      return;
    }

    // Save selected plugins for this widget instance
    await HomeWidget.saveWidgetData<String>(
      'widget_${widget.widgetId}_plugins',
      jsonEncode(_selectedPlugins.toList()),
    );

    // Trigger widget updates for all widget types
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        name: 'CrossbarWidgetSmall',
        androidName: 'CrossbarWidgetSmall',
      );
      await HomeWidget.updateWidget(
        name: 'CrossbarWidgetMedium',
        androidName: 'CrossbarWidgetMedium',
      );
      await HomeWidget.updateWidget(
        name: 'CrossbarWidgetLarge',
        androidName: 'CrossbarWidgetLarge',
      );
    }

    // Notify Android that configuration is complete
    try {
      await WidgetConfigDialog._channel.invokeMethod('configurationComplete');
    } catch (e) {
      // If channel fails, just close the dialog normally
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _cancel() async {
    // Notify Android that configuration was cancelled
    try {
      await WidgetConfigDialog._channel.invokeMethod('configurationCancelled');
    } catch (e) {
      // If channel fails, just close the dialog normally
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.widgets_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.configureWidget ?? 'Configure Widget',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Widget info chip
                  Chip(
                    avatar: const Icon(Icons.aspect_ratio, size: 18),
                    label: Text(_widgetSizeLabel),
                  ),
                  const SizedBox(height: 12),

                  // Selection hint
                  Text(
                    _maxPlugins == 1
                        ? (l10n?.selectOnePlugin ?? 'Select a plugin to display:')
                        : (l10n?.selectUpToPlugins(_maxPlugins) ??
                            'Select up to $_maxPlugins plugins:'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  // Plugin list
                  Expanded(
                    child: _plugins.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.extension_off,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n?.noEnabledPlugins ??
                                      'No enabled plugins found.\nEnable some plugins first.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _plugins.length,
                            itemBuilder: (context, index) {
                              final plugin = _plugins[index];
                              final isSelected =
                                  _selectedPlugins.contains(plugin.id);
                              final canSelect = isSelected ||
                                  _selectedPlugins.length < _maxPlugins;

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: canSelect
                                    ? (value) {
                                        setState(() {
                                          if (value ?? false) {
                                            // For single selection, clear others
                                            if (_maxPlugins == 1) {
                                              _selectedPlugins.clear();
                                            }
                                            _selectedPlugins.add(plugin.id);
                                          } else {
                                            _selectedPlugins.remove(plugin.id);
                                          }
                                        });
                                      }
                                    : null,
                                title: Text(
                                  _formatPluginName(plugin.id),
                                  style: TextStyle(
                                    color: canSelect ? null : theme.disabledColor,
                                  ),
                                ),
                                subtitle: Text(
                                  plugin.id,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: canSelect
                                        ? theme.hintColor
                                        : theme.disabledColor,
                                  ),
                                ),
                                secondary: Text(
                                  _getLanguageIcon(plugin.interpreter),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),

                  // Selection counter
                  if (_selectedPlugins.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      '${l10n?.selected ?? 'Selected'}: ${_selectedPlugins.length}/$_maxPlugins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _selectedPlugins.isEmpty ? null : _saveAndClose,
          child: Text(l10n?.save ?? 'Save'),
        ),
      ],
    );
  }

  String _formatPluginName(String pluginId) {
    return pluginId.split('.').first.replaceFirstMapped(
          RegExp('^[a-z]'),
          (match) => match.group(0)!.toUpperCase(),
        );
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
      case 'lua':
        return '🌙';
      case 'yaml':
        return '📋';
      default:
        return '📄';
    }
  }
}

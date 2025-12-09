import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/plugin_manager.dart';
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

  /// Show the widget configuration dialog.
  /// Returns true if configuration was saved, false if cancelled.
  static Future<bool> show(BuildContext context, int widgetId, String widgetSize) async {
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

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    await _pluginManager.discoverPlugins();
    
    // Load existing selection for this widget
    final existing = await HomeWidget.getWidgetData<String>('widget_${widget.widgetId}_plugins');
    if (existing != null) {
      try {
        final List<dynamic> savedPlugins = jsonDecode(existing);
        _selectedPlugins.addAll(savedPlugins.map((e) => e.toString()));
      } catch (_) {}
    }

    setState(() {
      _plugins = _pluginManager.plugins
          .where((p) => p.enabled)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      _loading = false;
    });
  }

  Future<void> _saveAndClose() async {
    if (_selectedPlugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one plugin')),
      );
      return;
    }

    // Save selected plugins for this widget instance
    await HomeWidget.saveWidgetData<String>(
      'widget_${widget.widgetId}_plugins',
      jsonEncode(_selectedPlugins.toList()),
    );

    // Trigger widget update
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

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.widgets_outlined),
          const SizedBox(width: 8),
          Text('Configure ${widget.widgetSize.toUpperCase()} Widget'),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select ${_maxPlugins == 1 ? "a plugin" : "up to $_maxPlugins plugins"} to display:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _plugins.isEmpty
                        ? const Center(
                            child: Text('No enabled plugins found.\nEnable some plugins first.'),
                          )
                        : ListView.builder(
                            itemCount: _plugins.length,
                            itemBuilder: (context, index) {
                              final plugin = _plugins[index];
                              final isSelected = _selectedPlugins.contains(plugin.id);
                              final canSelect = isSelected || _selectedPlugins.length < _maxPlugins;

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: canSelect
                                    ? (value) {
                                        setState(() {
                                          if (value == true) {
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
                                  plugin.id.split('.').first,
                                  style: TextStyle(
                                    color: canSelect ? null : theme.disabledColor,
                                  ),
                                ),
                                subtitle: Text(
                                  plugin.id,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: canSelect ? theme.hintColor : theme.disabledColor,
                                  ),
                                ),
                                dense: true,
                              );
                            },
                          ),
                  ),
                  if (_selectedPlugins.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Selected: ${_selectedPlugins.length}/$_maxPlugins',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedPlugins.isEmpty ? null : _saveAndClose,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

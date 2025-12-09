import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/plugin_manager.dart';
import '../../services/widget_service.dart';

class WidgetConfigurationDialog extends StatefulWidget {
  const WidgetConfigurationDialog({
    super.key,
    required this.appWidgetId,
    required this.widgetType,
  });

  final int appWidgetId;
  final String widgetType;

  @override
  State<WidgetConfigurationDialog> createState() => _WidgetConfigurationDialogState();
}

class _WidgetConfigurationDialogState extends State<WidgetConfigurationDialog> {
  final _pluginManager = PluginManager();
  final _widgetService = WidgetService();

  List<String> _availablePlugins = [];
  final List<String> _selectedPlugins = [];
  bool _isLoading = true;

  bool get _isMultiSelect => widget.widgetType == 'large';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load available plugins
    await _pluginManager.discoverPlugins();
    // Only show enabled plugins? Or all? Usually enabled ones.
    // Assuming discoverPlugins populates the list.
    // We should filter for enabled ones if possible, but for now show all discovered.

    // Load existing config if any
    final existingConfig = await _widgetService.getWidgetConfiguration(widget.appWidgetId.toString());

    if (mounted) {
      setState(() {
        _availablePlugins = _pluginManager.plugins.keys.toList()..sort();
        _selectedPlugins.addAll(existingConfig);
        // Ensure valid selection
        _selectedPlugins.removeWhere((id) => !_availablePlugins.contains(id));
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedPlugins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one plugin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _widgetService.saveWidgetConfiguration(
        widget.appWidgetId.toString(),
        _selectedPlugins,
      );

      // Notify native side to finish configuration
      const channel = MethodChannel('com.verseles.crossbar/system');
      await channel.invokeMethod('finishWidgetConfiguration', {
        'appWidgetId': widget.appWidgetId,
      });

      // The native call will finish the activity, but we should pop locally just in case
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving configuration: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Widget'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // If user cancels, we might need to close the activity?
            // Usually widgets expect a result. If we just close, widget is not added.
            SystemNavigator.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveConfiguration,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availablePlugins.isEmpty
              ? const Center(child: Text('No plugins available'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _isMultiSelect
                            ? 'Select plugins to display (scrollable)'
                            : 'Select a plugin to display',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availablePlugins.length,
                        itemBuilder: (context, index) {
                          final pluginId = _availablePlugins[index];
                          final isSelected = _selectedPlugins.contains(pluginId);

                          return CheckboxListTile(
                            title: Text(pluginId),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!_isMultiSelect) {
                                    _selectedPlugins.clear();
                                  }
                                  _selectedPlugins.add(pluginId);
                                } else {
                                  _selectedPlugins.remove(pluginId);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            secondary: _isMultiSelect
                              ? null
                              : Radio<String>(
                                  value: pluginId,
                                  groupValue: _selectedPlugins.isNotEmpty ? _selectedPlugins.first : null,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPlugins.clear();
                                        _selectedPlugins.add(value);
                                      });
                                    }
                                  },
                                ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

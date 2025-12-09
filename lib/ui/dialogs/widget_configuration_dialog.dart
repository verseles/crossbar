import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/services/widget_service.dart';
import 'package:flutter/material.dart';

class WidgetConfigurationDialog extends StatefulWidget {
  final int widgetId;
  final String widgetSize; // 'small', 'medium', 'large'

  const WidgetConfigurationDialog({
    super.key,
    required this.widgetId,
    required this.widgetSize,
  });

  @override
  State<WidgetConfigurationDialog> createState() =>
      _WidgetConfigurationDialogState();
}

class _WidgetConfigurationDialogState extends State<WidgetConfigurationDialog> {
  final Set<String> _selectedPluginIds = {};
  List<Plugin> _plugins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    final plugins = await PluginManager().getPlugins();
    setState(() {
      _plugins = plugins.where((p) => p.enabled).toList();
      _isLoading = false;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (widget.widgetSize == 'large') {
        if (_selectedPluginIds.contains(id)) {
          _selectedPluginIds.remove(id);
        } else {
          _selectedPluginIds.add(id);
        }
      } else {
        // Single selection for small/medium
        _selectedPluginIds.clear();
        _selectedPluginIds.add(id);
      }
    });
  }

  void _onSave() {
    WidgetService()
        .finishConfiguration(widget.widgetId, _selectedPluginIds.toList());
    Navigator.of(context).pop();
  }

  void _onCancel() {
    WidgetService().cancelConfiguration(widget.widgetId);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button without explicit cancel
      child: Scaffold(
        appBar: AppBar(
          title: Text('Configure Widget (${widget.widgetSize})'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _onCancel,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedPluginIds.isNotEmpty ? _onSave : null,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _plugins.isEmpty
                ? const Center(child: Text('No enabled plugins found.'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          widget.widgetSize == 'large'
                              ? 'Select plugins to display:'
                              : 'Select a plugin to display:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _plugins.length,
                          itemBuilder: (context, index) {
                            final plugin = _plugins[index];
                            final isSelected =
                                _selectedPluginIds.contains(plugin.id);
                            return ListTile(
                              title: Text(plugin.id),
                              subtitle: Text(plugin.path), // Show path or name
                              trailing: widget.widgetSize == 'large'
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (_) =>
                                          _toggleSelection(plugin.id),
                                    )
                                  : Radio<String>(
                                      value: plugin.id,
                                      groupValue:
                                          _selectedPluginIds.firstOrNull,
                                      onChanged: (val) {
                                        if (val != null) _toggleSelection(val);
                                      },
                                    ),
                              onTap: () => _toggleSelection(plugin.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

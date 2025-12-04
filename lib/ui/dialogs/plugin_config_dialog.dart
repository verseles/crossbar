import 'package:flutter/material.dart';

import '../../models/plugin.dart';
import '../../models/plugin_config.dart';
import '../widgets/config_fields/config_field.dart';

class PluginConfigDialog extends StatefulWidget {

  const PluginConfigDialog({
    super.key,
    required this.plugin,
    required this.config,
    this.initialValues = const {},
  });
  final Plugin plugin;
  final PluginConfig config;
  final Map<String, String> initialValues;

  static Future<Map<String, String>?> show({
    required BuildContext context,
    required Plugin plugin,
    required PluginConfig config,
    Map<String, String> initialValues = const {},
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => PluginConfigDialog(
        plugin: plugin,
        config: config,
        initialValues: initialValues,
      ),
    );
  }

  @override
  State<PluginConfigDialog> createState() => _PluginConfigDialogState();
}

class _PluginConfigDialogState extends State<PluginConfigDialog> {
  late Map<String, String> _values;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.initialValues);

    // Apply default values for missing settings
    for (final setting in widget.config.settings) {
      if (!_values.containsKey(setting.key) && setting.defaultValue != null) {
        _values[setting.key] = setting.defaultValue!;
      }
    }
  }

  bool get _isValid {
    for (final setting in widget.config.settings) {
      if (setting.required) {
        final value = _values[setting.key];
        if (value == null || value.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: _buildForm(context),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (widget.config.icon.isNotEmpty) ...[
            Text(
              widget.config.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.name.isNotEmpty
                      ? widget.config.name
                      : widget.plugin.id,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (widget.config.description.isNotEmpty)
                  Text(
                    widget.config.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    if (widget.config.settings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No configuration required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ConfigFormBuilder(
      settings: widget.config.settings,
      values: _values,
      onFieldChanged: (entry) {
        setState(() {
          _values[entry.key] = entry.value;
        });
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isValid ? () => Navigator.of(context).pop(_values) : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class PluginInfoDialog extends StatelessWidget {

  const PluginInfoDialog({
    super.key,
    required this.plugin,
    this.onConfigure,
    this.onToggle,
    this.onRun,
    this.onDelete,
  });
  final Plugin plugin;
  final VoidCallback? onConfigure;
  final VoidCallback? onToggle;
  final VoidCallback? onRun;
  final VoidCallback? onDelete;

  static Future<void> show({
    required BuildContext context,
    required Plugin plugin,
    VoidCallback? onConfigure,
    VoidCallback? onToggle,
    VoidCallback? onRun,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => PluginInfoDialog(
        plugin: plugin,
        onConfigure: onConfigure,
        onToggle: onToggle,
        onRun: onRun,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildDetails(context),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          plugin.enabled ? Icons.extension : Icons.extension_off,
          size: 48,
          color: plugin.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plugin.id,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${plugin.interpreter} • ${_formatInterval(plugin.refreshInterval)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: plugin.enabled,
          onChanged: (_) {
            Navigator.pop(context);
            onToggle?.call();
          },
        ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailItem(label: 'Path', value: plugin.path),
        _DetailItem(label: 'Interpreter', value: plugin.interpreter),
        _DetailItem(
          label: 'Refresh Interval',
          value: _formatInterval(plugin.refreshInterval),
        ),
        if (plugin.lastRun != null)
          _DetailItem(
            label: 'Last Run',
            value: _formatDateTime(plugin.lastRun!),
          ),
        if (plugin.lastError != null)
          _DetailItem(
            label: 'Last Error',
            value: plugin.lastError!,
            isError: true,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onRun != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRun!();
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Now'),
          ),
        if (onConfigure != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onConfigure!();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Configure'),
          ),
        if (onDelete != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            label: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

class _DetailItem extends StatelessWidget {

  const _DetailItem({
    required this.label,
    required this.value,
    this.isError = false,
  });
  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

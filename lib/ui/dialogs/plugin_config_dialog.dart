import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../widgets/config_fields/config_field.dart';

class PluginConfigDialog extends StatefulWidget {
  const PluginConfigDialog({
    required this.plugin,
    required this.config,
    required this.fullscreen,
    super.key,
    this.initialValues = const {},
  });
  final Plugin plugin;
  final PluginConfig config;
  final bool fullscreen;
  final Map<String, String> initialValues;

  static Future<Map<String, String>?> show({
    required BuildContext context,
    required Plugin plugin,
    required PluginConfig config,
    Map<String, String> initialValues = const {},
  }) {
    final platform = Theme.of(context).platform;
    final isMobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => PluginConfigDialog(
        plugin: plugin,
        config: config,
        fullscreen: isMobile,
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
      final value = _values[setting.key];
      final error = validateSettingValue(setting, value);
      if (error != null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: widget.fullscreen ? EdgeInsets.zero : null,
      child: widget.fullscreen
          ? SafeArea(child: _buildBody(context, fullscreen: true))
          : Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: _buildBody(context, fullscreen: false),
            ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool fullscreen}) {
    final content = Column(
      mainAxisSize: fullscreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _buildHeader(context),
        const Divider(height: 1),
        if (fullscreen)
          Expanded(child: _buildFormScroller(context))
        else
          Flexible(child: _buildFormScroller(context)),
        const Divider(height: 1),
        _buildActions(context),
      ],
    );

    if (!fullscreen) {
      return content;
    }

    return SizedBox.expand(child: content);
  }

  Widget _buildFormScroller(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: _buildForm(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (widget.config.icon.isNotEmpty) ...[
            Text(widget.config.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resolveDialogTitle(),
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
    final titleField = _buildTitleField(context);

    if (widget.config.settings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleField,
          const SizedBox(height: 24),
          Center(
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
                  AppLocalizations.of(context)!.noConfigurationRequired,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleField,
        const SizedBox(height: 24),
        ConfigFormBuilder(
          settings: widget.config.settings,
          values: _values,
          onFieldChanged: (entry) {
            setState(() {
              _values[entry.key] = entry.value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      initialValue: _values[PluginConfig.customTitleKey] ?? '',
      decoration: InputDecoration(
        labelText: 'Display Title (optional)',
        hintText: widget.plugin.displayName,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _values[PluginConfig.customTitleKey] = value;
        });
      },
    );
  }

  String _resolveDialogTitle() {
    final custom = _values[PluginConfig.customTitleKey]?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    if (widget.config.name.isNotEmpty) {
      return widget.config.name;
    }
    return widget.plugin.displayName;
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isValid
                ? () => Navigator.of(context).pop(_values)
                : null,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}

class PluginInfoDialog extends StatelessWidget {
  const PluginInfoDialog({
    required this.plugin,
    super.key,
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
                plugin.displayName,
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
            label: Text(AppLocalizations.of(context)!.runNow),
          ),
        if (onConfigure != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onConfigure!();
            },
            icon: const Icon(Icons.settings),
            label: Text(AppLocalizations.of(context)!.configure),
          ),
        if (onDelete != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              AppLocalizations.of(context)!.remove,
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

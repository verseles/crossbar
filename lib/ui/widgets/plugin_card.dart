import 'package:flutter/material.dart';

import '../../models/plugin.dart';
import '../../models/plugin_output.dart';

class PluginCard extends StatelessWidget {

  const PluginCard({
    super.key,
    required this.plugin,
    this.output,
    this.onTap,
    this.onToggle,
    this.onRefresh,
  });
  final Plugin plugin;
  final PluginOutput? output;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = output?.hasError ?? false;
    final isDisabled = !plugin.enabled;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: hasError
          ? colorScheme.errorContainer.withAlpha(50)
          : isDisabled
              ? colorScheme.surfaceContainerHighest.withAlpha(50)
              : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTitle(context),
                  ),
                  _buildActions(context),
                ],
              ),
              if (output != null && output!.text != null) ...[
                const SizedBox(height: 8),
                _buildOutput(context),
              ],
              if (hasError && output?.errorMessage != null) ...[
                const SizedBox(height: 8),
                _buildError(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final hasOutput = output != null && output!.icon.isNotEmpty;

    if (hasOutput) {
      return Text(
        output!.icon,
        style: const TextStyle(fontSize: 24),
      );
    }

    return Icon(
      plugin.enabled ? Icons.extension : Icons.extension_off,
      size: 24,
      color: plugin.enabled
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plugin.id,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${plugin.interpreter} • ${_formatInterval(plugin.refreshInterval)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: plugin.enabled ? onRefresh : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Refresh',
          ),
        if (onToggle != null)
          Switch(
            value: plugin.enabled,
            onChanged: (_) => onToggle?.call(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }

  Widget _buildOutput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        output!.text!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: output!.color,
              fontWeight: FontWeight.w500,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            output!.errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
}

class PluginTile extends StatelessWidget {

  const PluginTile({
    super.key,
    required this.plugin,
    this.output,
    this.onTap,
  });
  final Plugin plugin;
  final PluginOutput? output;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasOutput = output != null;
    final hasError = output?.hasError ?? false;

    return ListTile(
      leading: hasOutput && output!.icon.isNotEmpty
          ? Text(output!.icon, style: const TextStyle(fontSize: 20))
          : Icon(
              plugin.enabled ? Icons.extension : Icons.extension_off,
              color: plugin.enabled ? Colors.green : Colors.grey,
            ),
      title: Text(plugin.id),
      subtitle: hasOutput && output!.text != null
          ? Text(
              output!.text!,
              style: TextStyle(
                color: hasError ? Colors.red : output!.color,
              ),
            )
          : Text('${plugin.interpreter} • ${_formatInterval(plugin.refreshInterval)}'),
      trailing: hasError
          ? const Icon(Icons.error, color: Colors.red)
          : plugin.enabled
              ? const Icon(Icons.chevron_right)
              : const Icon(Icons.pause, color: Colors.grey),
      onTap: onTap,
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
}

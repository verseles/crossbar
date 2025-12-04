import 'package:flutter/material.dart';

import '../../core/plugin_manager.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plugin.dart';

class PluginsTab extends StatefulWidget {
  const PluginsTab({super.key});

  @override
  State<PluginsTab> createState() => _PluginsTabState();
}

class _PluginsTabState extends State<PluginsTab> {
  final PluginManager _pluginManager = PluginManager();
  bool _isLoading = true;

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
    await _loadPlugins();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pluginsTab),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshPlugins,
            tooltip: l10n.refreshAll,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddPluginDialog(context);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addPlugin),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plugins = _pluginManager.plugins;

    if (plugins.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return _PluginCard(
          plugin: plugin,
          onToggle: () async {
            await _pluginManager.togglePlugin(plugin.id);
            if (mounted) {
              await _refreshPlugins();
            }
          },
          onTap: () {
            _showPluginDetails(context, plugin);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
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
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              _showAddPluginDialog(context);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.addPlugin),
          ),
        ],
      ),
    );
  }

  void _showAddPluginDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPlugin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To add a plugin:'),
            const SizedBox(height: 16),
            const Text('1. Create a script in one of these languages:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LanguageChip(label: l10n.bash, extension: '.sh'),
                _LanguageChip(label: l10n.python, extension: '.py'),
                _LanguageChip(label: l10n.node, extension: '.js'),
                _LanguageChip(label: l10n.dart, extension: '.dart'),
                _LanguageChip(label: l10n.go, extension: '.go'),
                _LanguageChip(label: l10n.rust, extension: '.rs'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('2. Name it with refresh interval:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'cpu.10s.sh  # runs every 10 seconds\n'
                'weather.5m.py  # runs every 5 minutes\n'
                'backup.1h.sh  # runs every hour',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('3. Place it in ~/.crossbar/plugins/<language>/'),
          ],
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

  void _showPluginDetails(BuildContext context, Plugin plugin) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  plugin.enabled ? Icons.play_circle : Icons.pause_circle,
                  color: plugin.enabled ? Colors.green : Colors.grey,
                  size: 32,
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
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(label: 'Path', value: plugin.path),
            _DetailRow(label: 'Interpreter', value: plugin.interpreter),
            _DetailRow(
              label: l10n.refreshInterval,
              value: _formatInterval(plugin.refreshInterval),
            ),
            if (plugin.lastRun != null)
              _DetailRow(
                label: l10n.lastRun,
                value: _formatDateTime(plugin.lastRun!),
              ),
            if (plugin.lastError != null)
              _DetailRow(
                label: l10n.errorOccurred,
                value: plugin.lastError!,
                isError: true,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _pluginManager.runPlugin(plugin.id);
                    setState(() {});
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.runNow),
                ),
              ],
            ),
          ],
        ),
      ),
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

class _PluginCard extends StatelessWidget {

  const _PluginCard({
    required this.plugin,
    required this.onToggle,
    required this.onTap,
  });
  final Plugin plugin;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          plugin.enabled ? Icons.play_circle : Icons.pause_circle,
          color: plugin.enabled ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(plugin.id),
        subtitle: Text(
          '${plugin.interpreter} • ${_formatInterval(plugin.refreshInterval)}',
        ),
        trailing: Switch(
          value: plugin.enabled,
          onChanged: (_) => onToggle(),
        ),
        onTap: onTap,
      ),
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

class _LanguageChip extends StatelessWidget {

  const _LanguageChip({
    required this.label,
    required this.extension,
  });
  final String label;
  final String extension;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label ($extension)'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _DetailRow extends StatelessWidget {

  const _DetailRow({
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
            width: 100,
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
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

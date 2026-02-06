import 'dart:async';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/logger_service.dart';
import '../../services/widget_log_store.dart';

enum LogTimeRange {
  oneMinute(Duration(minutes: 1), '1m'),
  fiveMinutes(Duration(minutes: 5), '5m'),
  fifteenMinutes(Duration(minutes: 15), '15m'),
  thirtyMinutes(Duration(minutes: 30), '30m'),
  all(null, 'All');

  const LogTimeRange(this.duration, this.label);

  final Duration? duration;
  final String label;
}

class DebugLogsPage extends StatefulWidget {
  const DebugLogsPage({super.key});

  @override
  State<DebugLogsPage> createState() => _DebugLogsPageState();
}

class _DebugLogsPageState extends State<DebugLogsPage> {
  final LoggerService _logger = LoggerService();
  final WidgetLogStore _widgetLogStore = WidgetLogStore();
  final LuaRunner _luaRunner = LuaRunner();
  late StreamSubscription<LogEntry> _logSubscription;

  LogTimeRange _timeRange = LogTimeRange.fiveMinutes;
  LogCategory _category = LogCategory.all;
  List<LogEntry> _logs = [];
  Future<List<String>>? _widgetLogsFuture;
  Future<int?>? _widgetDiscardedFuture;
  Future<WebCacheDiskStats>? _webCacheDiskFuture;
  WebCacheMetrics _webCacheMetrics = LuaRunner().webCacheMetrics;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
    _widgetLogsFuture = _widgetLogStore.loadLines();
    _widgetDiscardedFuture = _widgetLogStore.loadDiscardedCount();
    _webCacheDiskFuture = _luaRunner.webCacheDiskStats;
    _webCacheMetrics = _luaRunner.webCacheMetrics;
    _logSubscription = _logger.logStream.listen((_) => _refreshLogs());
  }

  @override
  void dispose() {
    _logSubscription.cancel();
    super.dispose();
  }

  void _refreshLogs() {
    if (!mounted) return;
    setState(() {
      _logs = _logger.getFilteredLogs(
        timeRange: _timeRange.duration,
        category: _category,
      );
    });
  }

  Future<void> _copyLogs(AppLocalizations l10n) async {
    final export = _logger.formatLogsForExport(
      _logs,
      timeRangeLabel: _timeRange.label,
    );
    await Clipboard.setData(ClipboardData(text: export));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.debugLogsCopied)));
  }

  Future<void> _clearLogs() async {
    await _logger.clearLogs();
    _refreshLogs();
  }

  Future<void> _copyWidgetLogs(AppLocalizations l10n) async {
    final raw = await _widgetLogStore.loadRaw();
    if (raw.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.debugLogsCopied)));
  }

  Future<void> _clearWidgetLogs() async {
    await _widgetLogStore.clear();
    if (!mounted) return;
    setState(() {
      _widgetLogsFuture = _widgetLogStore.loadLines();
      _widgetDiscardedFuture = _widgetLogStore.loadDiscardedCount();
    });
  }

  void _refreshWebCacheStats() {
    if (!mounted) return;
    setState(() {
      _webCacheMetrics = _luaRunner.webCacheMetrics;
      _webCacheDiskFuture = _luaRunner.webCacheDiskStats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugLogsTitle),
        actions: [
          IconButton(
            onPressed: _logs.isEmpty ? null : () => _copyLogs(l10n),
            icon: const Icon(Icons.copy_all),
            tooltip: l10n.debugLogsCopy,
          ),
          IconButton(
            onPressed: _logs.isEmpty ? null : _clearLogs,
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.debugLogsClear,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(l10n),
          const Divider(height: 1),
          Expanded(
            child: _logs.isEmpty ? _buildEmptyState(l10n) : _buildLogList(),
          ),
          if (Platform.isAndroid) _buildWidgetLogsSection(l10n),
          _buildWebCacheSection(l10n),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l10n.debugLogsRange),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<LogTimeRange>(
                  segments: LogTimeRange.values
                      .map(
                        (range) => ButtonSegment(
                          value: range,
                          label: Text(range.label),
                        ),
                      )
                      .toList(),
                  selected: {_timeRange},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _timeRange = selection.first;
                      _logs = _logger.getFilteredLogs(
                        timeRange: _timeRange.duration,
                        category: _category,
                      );
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.debugLogsCategory),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: LogCategory.values.map((category) {
                      final isSelected = _category == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _category = category;
                              _logs = _logger.getFilteredLogs(
                                timeRange: _timeRange.duration,
                                category: _category,
                              );
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.debugLogsEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: _logs.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemBuilder: (context, index) => _LogEntryTile(entry: _logs[index]),
    );
  }

  Widget _buildWidgetLogsSection(AppLocalizations l10n) {
    return ExpansionTile(
      title: Text(l10n.debugLogsWidgetTitle),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _widgetLogsFuture = _widgetLogStore.loadLines();
                  _widgetDiscardedFuture = _widgetLogStore.loadDiscardedCount();
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.refresh),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _copyWidgetLogs(l10n),
              icon: const Icon(Icons.copy_all, size: 18),
              label: Text(l10n.debugLogsCopy),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _clearWidgetLogs,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.debugLogsClear),
            ),
          ],
        ),
        FutureBuilder<List<String>>(
          future: _widgetLogsFuture,
          builder: (context, snapshot) {
            final lines = snapshot.data ?? [];
            if (lines.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.debugLogsWidgetEmpty),
              );
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<int?>(
                    future: _widgetDiscardedFuture,
                    builder: (context, snapshot) {
                      final discarded = snapshot.data ?? 0;
                      if (discarded <= 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          l10n.debugLogsWidgetDiscarded(discarded),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                  SelectableText(
                    lines.join('\n'),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWebCacheSection(AppLocalizations l10n) {
    final metrics = _webCacheMetrics;
    final hitRate = (metrics.hitRate * 100).toStringAsFixed(1);
    final entryLabel =
        '${_luaRunner.webCacheEntryCount}/${_luaRunner.webCacheMaxEntries}';
    final compressionLabel = _luaRunner.webCacheCompressionEnabled
        ? l10n.enabled
        : l10n.disabled;

    return ExpansionTile(
      title: Text(l10n.debugWebCacheTitle),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: _refreshWebCacheStats,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.refresh),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildStatRow(l10n.debugWebCacheEntries, entryLabel),
        _buildStatRow(l10n.debugWebCacheHitRate, '$hitRate%'),
        _buildStatRow(l10n.debugWebCacheHits, metrics.hits.toString()),
        _buildStatRow(l10n.debugWebCacheMisses, metrics.misses.toString()),
        _buildStatRow(
          l10n.debugWebCacheEvictions,
          _luaRunner.webCacheEvictions.toString(),
        ),
        _buildStatRow(l10n.debugWebCacheCompression, compressionLabel),
        _buildStatRow(
          l10n.debugWebCacheBytesSaved,
          _formatBytes(metrics.bytesSaved),
        ),
        FutureBuilder<WebCacheDiskStats>(
          future: _webCacheDiskFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data;
            if (stats == null) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  l10n.debugWebCacheDiskSize,
                  _formatBytes(stats.totalBytes),
                ),
                _buildStatRow(
                  l10n.debugWebCacheFiles,
                  l10n.debugWebCacheFilesCount(
                    stats.fileCount,
                    stats.compressedFiles,
                    stats.uncompressedFiles,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    const gb = 1024 * 1024 * 1024;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(2)} GB';
    }
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    }
    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    }
    return '$bytes B';
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final LogEntry entry;

  Color _levelColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (entry.level) {
      case LogLevel.error:
        return scheme.error;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return scheme.primary;
      case LogLevel.debug:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: entry.level == LogLevel.error
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
            : entry.level == LogLevel.warning
            ? Colors.orange.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.formattedTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.level.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (entry.details != null && entry.details!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                entry.details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

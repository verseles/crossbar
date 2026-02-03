import 'package:crossbar/ui/tabs/plugins_tab.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filterAndSortPlugins filters enabled only', () {
    final plugins = [
      const Plugin(
        id: 'cpu.10s.sh',
        path: '/tmp/cpu.10s.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 10),
        enabled: true,
      ),
      const Plugin(
        id: 'mem.off.10s.sh',
        path: '/tmp/mem.off.10s.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 10),
        enabled: false,
      ),
    ];

    final result = filterAndSortPlugins(
      plugins: plugins,
      searchQuery: '',
      enabledOnly: true,
      sortOrder: PluginSortOrder.alphabetical,
    );

    expect(result.length, 1);
    expect(result.first.id, 'cpu.10s.sh');
  });

  test('filterAndSortPlugins applies search query', () {
    final plugins = [
      const Plugin(
        id: 'cpu.10s.sh',
        path: '/tmp/cpu.10s.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 10),
        enabled: true,
      ),
      const Plugin(
        id: 'mem.10s.sh',
        path: '/tmp/mem.10s.sh',
        interpreter: 'bash',
        refreshInterval: Duration(seconds: 10),
        enabled: true,
      ),
    ];

    final result = filterAndSortPlugins(
      plugins: plugins,
      searchQuery: 'mem',
      enabledOnly: false,
      sortOrder: PluginSortOrder.alphabetical,
    );

    expect(result.length, 1);
    expect(result.first.id, 'mem.10s.sh');
  });
}

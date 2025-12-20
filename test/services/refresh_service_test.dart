import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/refresh_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'refresh_service_test.mocks.dart';

@GenerateMocks([PluginManager])
void main() {
  late RefreshService refreshService;
  late MockPluginManager mockPluginManager;

  setUp(() {
    mockPluginManager = MockPluginManager();
    refreshService = RefreshService();
    // This is a gross way to inject the mock, but it's a singleton.
    // In a real app, I'd use a proper DI container.
    refreshService.pluginManager = mockPluginManager;
  });

  test('refreshAll runs all enabled plugins and updates stream', () async {
    final plugin1 = Plugin(id: 'p1', path: 'p1', interpreter: 'sh', enabled: true, refreshInterval: Duration(seconds: 10));
    final plugin2 = Plugin(id: 'p2', path: 'p2', interpreter: 'sh', enabled: false, refreshInterval: Duration(seconds: 10));
    final plugin3 = Plugin(id: 'p3', path: 'p3', interpreter: 'sh', enabled: true, refreshInterval: Duration(seconds: 10));

    final output1 = PluginOutput(pluginId: 'p1', text: 'out1');
    final output3 = PluginOutput(pluginId: 'p3', text: 'out3');

    when(mockPluginManager.plugins).thenReturn([plugin1, plugin2, plugin3]);
    when(mockPluginManager.runPlugin('p1')).thenAnswer((_) async => output1);
    when(mockPluginManager.runPlugin('p3')).thenAnswer((_) async => output3);

    final future = expectLater(
      refreshService.outputsStream,
      emitsInOrder([
        {'p1': output1},
        {'p1': output1, 'p3': output3},
      ]),
    );

    await refreshService.refreshAll();

    await future;

    expect(refreshService.getOutput('p1'), output1);
    expect(refreshService.getOutput('p3'), output3);
    verify(mockPluginManager.runPlugin('p1')).called(1);
    verify(mockPluginManager.runPlugin('p3')).called(1);
    verifyNever(mockPluginManager.runPlugin('p2'));
  });

  test('refreshPlugin runs a single enabled plugin and updates stream', () async {
    final plugin = Plugin(id: 'p1', path: 'p1', interpreter: 'sh', enabled: true, refreshInterval: Duration(seconds: 10));
    final output = PluginOutput(pluginId: 'p1', text: 'out');

    when(mockPluginManager.getPlugin('p1')).thenReturn(plugin);
    when(mockPluginManager.runPlugin('p1')).thenAnswer((_) async => output);

    final future = expectLater(
      refreshService.outputsStream,
      emits({'p1': output}),
    );

    await refreshService.refreshPlugin('p1');

    await future;

    expect(refreshService.getOutput('p1'), output);
    verify(mockPluginManager.runPlugin('p1')).called(1);
  });
}

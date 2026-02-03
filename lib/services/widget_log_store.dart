import 'dart:io';

import 'package:home_widget/home_widget.dart';

class WidgetLogStore {
  static const String logKey = 'widget_debug_logs';

  Future<List<String>> loadLines() async {
    if (!Platform.isAndroid) return [];

    final raw = await HomeWidget.getWidgetData<String>(logKey);
    if (raw == null || raw.trim().isEmpty) return [];

    return raw
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<String> loadRaw() async {
    if (!Platform.isAndroid) return '';
    return await HomeWidget.getWidgetData<String>(logKey) ?? '';
  }

  Future<void> clear() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<String?>(logKey, null);
  }
}

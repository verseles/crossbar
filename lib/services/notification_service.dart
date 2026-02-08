import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logger_service.dart';

class NotificationService {

  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  /// Callback for refresh requests from notification actions.
  void Function(String pluginId)? onRefreshRequested;

  /// Callback for CLI command requests from notification actions.
  void Function(List<String> args)? onCliCommandRequested;

  /// Callback for showing plugin menu (from "More..." button).
  void Function(String pluginId)? onShowPluginMenu;

  // Regular notification channel
  static const String channelId = 'crossbar_plugins';
  static const String channelName = 'Plugin Notifications';
  static const String channelDescription = 'Notifications from Crossbar plugins';

  static const int _combinedNotificationId = 8000;
  static const int _individualIdBase = 8100;

  // Persistent notification channel (for foreground service)
  static const String persistentChannelId = 'crossbar_service';
  static const String persistentChannelName = 'Crossbar Service';
  static const String persistentChannelDescription = 'Keeps Crossbar running in background';
  static const int persistentNotificationId = 9999;

  bool _persistentNotificationShown = false;

  // Cache of emoji → PNG bytes (avoids re-rendering on each notification)
  static final Map<String, Uint8List> _emojiIconCache = {};

  static Future<Uint8List?> _renderEmojiToBitmap(String emoji) async {
    if (emoji.isEmpty) return null;
    if (_emojiIconCache.containsKey(emoji)) return _emojiIconCache[emoji];

    const size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const ui.Rect.fromLTWH(0, 0, size, size),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: size * 0.7),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(
        (size - painter.width) / 2,
        (size - painter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    _emojiIconCache[emoji] = bytes;
    return bytes;
  }

  static const _systemChannel = MethodChannel('com.verseles.crossbar/system');

  /// Updates the foreground service notification via Kotlin MethodChannel.
  /// Only works on Android where the foreground service owns notification 9999.
  Future<void> _updateForegroundNotification({
    required String title,
    required String body,
    List<String>? lines,
  }) async {
    try {
      await _systemChannel.invokeMethod('updateForegroundNotification', {
        'title': title,
        'body': body,
        if (lines != null) 'lines': lines,
      });
      LoggerService().info(
        'Foreground notification updated: $title'
        '${lines != null ? " (${lines.length} lines)" : ""}',
      );
    } catch (e) {
      LoggerService().error('Foreground notification update failed', e);
    }
    _persistentNotificationShown = true;
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
        defaultIcon: ThemeLinuxIcon('com.verseles.crossbar-symbolic'),
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
        linux: linuxSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channels for Android
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        // Request notification permission for Android 13+ (API 33+)
        await androidPlugin?.requestNotificationsPermission();
                
        // Regular notification channel
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.defaultImportance,
        );
        await androidPlugin?.createNotificationChannel(channel);

        // Persistent notification channel (low importance = silent)
        const persistentChannel = AndroidNotificationChannel(
          persistentChannelId,
          persistentChannelName,
          description: persistentChannelDescription,
          importance: Importance.low,
          showBadge: false,
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin?.createNotificationChannel(persistentChannel);
      }

      _initialized = true;
    } catch (e) {
      // Initialization may fail in test environments - that's okay
      // The service will gracefully handle missing initialization
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    // Handle action button taps (open URL)
    if (actionId != null && actionId.startsWith('open_url:') && payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final url = data[actionId] as String?;
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        // Payload is not JSON - ignore
      }
      return;
    }

    // Handle refresh action
    if (actionId != null && actionId.startsWith('refresh:')) {
      final pluginId = actionId.substring('refresh:'.length);
      onRefreshRequested?.call(pluginId);
      return;
    }

    // Handle CLI command action
    if (actionId != null && actionId.startsWith('cli:') && payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final cmd = data[actionId] as String?;
        if (cmd != null) {
          onCliCommandRequested?.call(cmd.split(RegExp(r'\s+')));
        }
      } catch (_) {
        // Payload is not JSON - ignore
      }
      return;
    }

    // Handle "More" action - show plugin menu or open the app
    if (actionId != null && actionId.startsWith('more:')) {
      final pluginId = actionId.substring('more:'.length);
      onShowPluginMenu?.call(pluginId);
      return;
    }
    if (actionId == 'more') {
      // Combined notification: just bring app to foreground
      return;
    }
  }

  Future<void> showPluginNotification({
    required String pluginId,
    required String title,
    required String body,
    String? icon,
    Map<String, String>? payload,
  }) async {
    if (!_initialized) return;

    final id = _notificationId++;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_stat_crossbar',
    );

    const iosDetails = DarwinNotificationDetails();

    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      id,
      '$icon $title'.trim(),
      body,
      details,
      payload: pluginId,
    );
  }

  Future<void> showErrorNotification({
    required String pluginId,
    required String error,
  }) async {
    await showPluginNotification(
      pluginId: pluginId,
      title: 'Plugin Error',
      body: '$pluginId: $error',
      icon: '',
    );
  }

  Future<void> showPluginOutput({
    required String pluginId,
    required String? icon,
    required String? text,
  }) async {
    if (text == null || text.isEmpty) return;

    await showPluginNotification(
      pluginId: pluginId,
      title: pluginId,
      body: text,
      icon: icon,
    );
  }

  /// Shows a combined InboxStyle notification grouping all active plugins.
  Future<void> showCombinedNotification(
    Map<String, PluginOutput> outputs,
  ) async {
    if (!_initialized || !Platform.isAndroid && !Platform.isIOS) return;
    if (outputs.isEmpty) return;

    final lines = <String>[];
    for (final entry in outputs.entries) {
      final output = entry.value;
      if (output.hasError) continue;
      final icon = output.icon.isNotEmpty ? '${output.icon} ' : '';
      final title = output.title ?? entry.key;
      final fullText = output.text ?? '--';
      final text = fullText.split('\n').first;
      lines.add('$icon$title: $text');
    }

    if (lines.isEmpty) return;

    final summary = '${lines.length} plugin(s) active';

    // Collect first 2 actionable items across all plugins for action buttons
    final actions = <AndroidNotificationAction>[];
    final actionPayload = <String, String>{};
    var actionIndex = 0;
    for (final entry in outputs.entries) {
      if (actionIndex >= 2) break;
      final output = entry.value;
      for (final item in output.menu) {
        if (actionIndex >= 2) break;
        if (item.separator) continue;

        if (item.href != null) {
          final label = item.text ?? entry.key;
          final actionId = 'open_url:$actionIndex';
          actions.add(AndroidNotificationAction(
            actionId,
            label.length > 20 ? '${label.substring(0, 17)}...' : label,
            showsUserInterface: true,
            cancelNotification: false,
          ));
          actionPayload[actionId] = item.href!;
          actionIndex++;
        } else if (item.refresh) {
          final label = item.text ?? 'Refresh';
          actions.add(AndroidNotificationAction(
            'refresh:${entry.key}',
            label.length > 20 ? '${label.substring(0, 17)}...' : label,
            showsUserInterface: false,
            cancelNotification: false,
          ));
          actionIndex++;
        } else if (item.isCrossbarCommand) {
          final label = item.text ?? 'Run';
          final actionId = 'cli:$actionIndex';
          actions.add(AndroidNotificationAction(
            actionId,
            label.length > 20 ? '${label.substring(0, 17)}...' : label,
            showsUserInterface: false,
            cancelNotification: false,
          ));
          actionPayload[actionId] = item.bash!.replaceFirst('crossbar ', '');
          actionIndex++;
        }
      }
    }
    // Add "More" button if there are additional actionable items
    final totalActions = outputs.values
        .expand((o) => o.menu)
        .where((m) => !m.separator && m.isMobileAction)
        .length;
    if (totalActions > 2) {
      actions.add(const AndroidNotificationAction(
        'more',
        'More...',
        showsUserInterface: true,
        cancelNotification: false,
      ));
    }

    final payload = actionPayload.isNotEmpty
        ? jsonEncode(actionPayload)
        : 'combined';

    // Body shown in collapsed view: first lines preview
    final bodyPreview = lines.take(3).join(' · ');

    // Reuse the persistent notification slot so the combined summary
    // replaces "Crossbar Running" instead of creating a second notification.
    final androidDetails = AndroidNotificationDetails(
      persistentChannelId,
      persistentChannelName,
      channelDescription: persistentChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.service,
      icon: '@drawable/ic_stat_crossbar',
      actions: actions,
      styleInformation: InboxStyleInformation(
        lines.take(6).toList(),
        contentTitle: 'Crossbar - ${lines.length} plugins',
        summaryText: summary,
      ),
    );

    const iosDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );

    if (Platform.isAndroid) {
      LoggerService().info(
        'showCombinedNotification: ${lines.length} plugins, '
        'preview=$bodyPreview',
      );
      await _updateForegroundNotification(
        title: 'Crossbar - ${lines.length} plugins',
        body: bodyPreview,
        lines: lines.take(6).toList(),
      );
    } else {
      await _notifications.show(
        persistentNotificationId,
        'Crossbar - ${lines.length} plugins',
        bodyPreview,
        details,
        payload: payload,
      );
    }
  }

  /// Shows an individual notification for a specific plugin.
  Future<void> showIndividualNotification(
    String pluginId,
    PluginOutput output,
  ) async {
    if (!_initialized || !Platform.isAndroid && !Platform.isIOS) return;

    final id = _individualIdBase + pluginId.hashCode.abs() % 900;
    final icon = output.icon.isNotEmpty ? '${output.icon} ' : '';
    final title = output.title ?? pluginId;
    final text = output.text ?? '--';

    // Build expanded text with informational menu items (skip actions)
    final expandedLines = <String>[text];
    for (final item in output.menu.take(6)) {
      if (item.separator || item.isAction) continue;
      final itemText = item.text ?? '';
      if (itemText.isEmpty) continue;
      expandedLines.add(itemText);
    }

    // Extract first 2 actionable menu items as notification buttons
    final actions = <AndroidNotificationAction>[];
    final actionPayload = <String, String>{};
    var actionIndex = 0;
    for (final item in output.menu) {
      if (actionIndex >= 2) break;
      if (item.separator) continue;

      if (item.href != null) {
        final label = item.text ?? 'Open';
        final actionId = 'open_url:$actionIndex';
        actions.add(AndroidNotificationAction(
          actionId,
          label.length > 20 ? '${label.substring(0, 17)}...' : label,
          showsUserInterface: true,
          cancelNotification: false,
        ));
        actionPayload[actionId] = item.href!;
        actionIndex++;
      } else if (item.refresh) {
        final label = item.text ?? 'Refresh';
        actions.add(AndroidNotificationAction(
          'refresh:$pluginId',
          label.length > 20 ? '${label.substring(0, 17)}...' : label,
          showsUserInterface: false,
          cancelNotification: false,
        ));
        actionIndex++;
      } else if (item.isCrossbarCommand) {
        final label = item.text ?? 'Run';
        final actionId = 'cli:$actionIndex';
        actions.add(AndroidNotificationAction(
          actionId,
          label.length > 20 ? '${label.substring(0, 17)}...' : label,
          showsUserInterface: false,
          cancelNotification: false,
        ));
        actionPayload[actionId] = item.bash!.replaceFirst('crossbar ', '');
        actionIndex++;
      }
    }
    // Add "More" button if there are additional actionable items
    final totalActions = output.menu
        .where((m) => !m.separator && m.isMobileAction)
        .length;
    if (totalActions > 2) {
      actions.add(AndroidNotificationAction(
        'more:$pluginId',
        'More...',
        showsUserInterface: true,
        cancelNotification: false,
      ));
    }

    final payload = actionPayload.isNotEmpty
        ? jsonEncode(actionPayload)
        : pluginId;

    // Render emoji as large icon bitmap
    ByteArrayAndroidBitmap? largeIcon;
    if (output.icon.isNotEmpty) {
      try {
        final bytes = await _renderEmojiToBitmap(output.icon);
        if (bytes != null) largeIcon = ByteArrayAndroidBitmap(bytes);
      } catch (e) {
        LoggerService().error('Failed to render emoji icon', e);
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_stat_crossbar',
      largeIcon: largeIcon,
      actions: actions,
      styleInformation: BigTextStyleInformation(
        expandedLines.join('\n'),
        contentTitle: '$icon$title',
        summaryText: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      id,
      '$icon$title',
      text,
      details,
      payload: payload,
    );
  }

  /// Cancel all plugin output notifications (combined + individual).
  Future<void> cancelPluginNotifications() async {
    await _notifications.cancel(_combinedNotificationId);
    // Individual notifications are overwritten by stable IDs, no need to cancel all
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (Platform.isMacOS) {
      final macos = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      return await macos?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  /// Shows a persistent notification for Android foreground service.
  /// This keeps the app running in background and updates widgets.
  Future<void> showPersistentNotification({
    String title = 'Crossbar Running',
    String body = 'Monitoring plugins in background',
    int enabledPlugins = 0,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;

    // Only override body with plugin count when using the default body text
    final actualBody = (body == 'Monitoring plugins in background' && enabledPlugins > 0)
        ? '$enabledPlugins plugin(s) active'
        : body;

    LoggerService().info('showPersistentNotification: $title / $actualBody');
    await _updateForegroundNotification(title: title, body: actualBody);
  }

  /// Updates the persistent notification with new plugin count.
  Future<void> updatePersistentNotification({
    required int enabledPlugins,
    String? lastUpdate,
  }) async {
    if (!_persistentNotificationShown) return;
    
    final body = lastUpdate != null 
        ? '$enabledPlugins plugin(s) • Updated $lastUpdate'
        : '$enabledPlugins plugin(s) active';
    
    await showPersistentNotification(
      body: body,
      enabledPlugins: enabledPlugins,
    );
  }

  /// Hides the persistent notification.
  Future<void> hidePersistentNotification() async {
    if (!Platform.isAndroid) return;
    
    await _notifications.cancel(persistentNotificationId);
    _persistentNotificationShown = false;
  }

  bool get isPersistentNotificationShown => _persistentNotificationShown;

  void dispose() {
    _initialized = false;
  }
}

class PluginNotificationConfig {

  const PluginNotificationConfig({
    this.enabled = false,
    this.onError = true,
    this.onOutput = false,
    this.onThreshold = false,
    this.threshold,
    this.priority = NotificationPriority.normal,
  });

  factory PluginNotificationConfig.fromJson(Map<String, dynamic> json) {
    return PluginNotificationConfig(
      enabled: json['enabled'] as bool? ?? false,
      onError: json['onError'] as bool? ?? true,
      onOutput: json['onOutput'] as bool? ?? false,
      onThreshold: json['onThreshold'] as bool? ?? false,
      threshold: json['threshold'] as double?,
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
    );
  }
  final bool enabled;
  final bool onError;
  final bool onOutput;
  final bool onThreshold;
  final double? threshold;
  final NotificationPriority priority;

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'onError': onError,
      'onOutput': onOutput,
      'onThreshold': onThreshold,
      'threshold': threshold,
      'priority': priority.name,
    };
  }

  PluginNotificationConfig copyWith({
    bool? enabled,
    bool? onError,
    bool? onOutput,
    bool? onThreshold,
    double? threshold,
    NotificationPriority? priority,
  }) {
    return PluginNotificationConfig(
      enabled: enabled ?? this.enabled,
      onError: onError ?? this.onError,
      onOutput: onOutput ?? this.onOutput,
      onThreshold: onThreshold ?? this.onThreshold,
      threshold: threshold ?? this.threshold,
      priority: priority ?? this.priority,
    );
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
}

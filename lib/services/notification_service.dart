import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  static const String channelId = 'crossbar_plugins';
  static const String channelName = 'Plugin Notifications';
  static const String channelDescription = 'Notifications from Crossbar plugins';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.defaultImportance,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle notification tap - could open specific plugin
      // or execute an action
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

  void dispose() {
    _initialized = false;
  }
}

class PluginNotificationConfig {
  final bool enabled;
  final bool onError;
  final bool onOutput;
  final bool onThreshold;
  final double? threshold;
  final NotificationPriority priority;

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

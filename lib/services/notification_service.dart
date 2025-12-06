import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  factory NotificationService() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  // Regular notification channel
  static const String channelId = 'crossbar_plugins';
  static const String channelName = 'Plugin Notifications';
  static const String channelDescription = 'Notifications from Crossbar plugins';

  // Persistent notification channel (for foreground service)
  static const String persistentChannelId = 'crossbar_service';
  static const String persistentChannelName = 'Crossbar Service';
  static const String persistentChannelDescription = 'Keeps Crossbar running in background';
  static const int persistentNotificationId = 9999;

  bool _persistentNotificationShown = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
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

      // Create notification channels for Android
      if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
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

  /// Shows a persistent notification for Android foreground service.
  /// This keeps the app running in background and updates widgets.
  Future<void> showPersistentNotification({
    String title = 'Crossbar Running',
    String body = 'Monitoring plugins in background',
    int enabledPlugins = 0,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;
    
    final actualBody = enabledPlugins > 0 
        ? '$enabledPlugins plugin(s) active' 
        : body;

    const androidDetails = AndroidNotificationDetails(
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
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      persistentNotificationId,
      title,
      actualBody,
      details,
      payload: 'persistent',
    );
    
    _persistentNotificationShown = true;
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

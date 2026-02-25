import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

enum UpdateInstallState { idle, downloading, installing, done, failed }

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.latestVersion,
    this.releaseUrl,
    this.releaseNotes,
    this.apkUrl,
    required this.isNewer,
  });

  final String latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  // Direct APK download URL from GitHub release assets (Android only).
  final String? apkUrl;
  final bool isNewer;
}

/// Singleton service for checking and installing app updates from GitHub releases.
class UpdateService extends ChangeNotifier {
  factory UpdateService() => _instance;

  UpdateService._internal();

  static final UpdateService _instance = UpdateService._internal();

  static const String _repoOwner = 'verseles';
  static const String _repoName = 'crossbar';
  static const Duration _cooldown = Duration(hours: 1);
  static const String _keyDismissedVersion = 'update_dismissed_version';
  static const String _keyCheckOnOpen = 'update_check_on_open';

  DateTime? _lastCheck;
  UpdateCheckResult? _result;
  bool _checkingForUpdate = false;
  // Set to true after a startup check finds a newer version; consumed once by UI.
  bool _pendingStartupToast = false;
  String? _dismissedVersion;
  bool _checkOnOpen = true;

  UpdateInstallState _installState = UpdateInstallState.idle;
  double _installProgress = 0.0;

  // Guard booleans so each install-state snackbar shows only once per cycle.
  bool shownProgressSnackBar = false;
  bool shownDoneSnackBar = false;
  bool shownFailedSnackBar = false;

  UpdateCheckResult? get result => _result;
  bool get checkingForUpdate => _checkingForUpdate;
  bool get pendingStartupToast => _pendingStartupToast;
  bool get checkOnOpen => _checkOnOpen;
  UpdateInstallState get installState => _installState;
  double get installProgress => _installProgress;

  bool get hasUpdate =>
      _result != null &&
      _result!.isNewer &&
      _result!.latestVersion != _dismissedVersion;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _dismissedVersion = prefs.getString(_keyDismissedVersion);
    _checkOnOpen = prefs.getBool(_keyCheckOnOpen) ?? true;
  }

  Future<void> setCheckOnOpen(bool value) async {
    _checkOnOpen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheckOnOpen, value);
    notifyListeners();
  }

  /// Silent startup check — sets pendingStartupToast if a newer version is found.
  Future<void> performStartupCheck() async {
    if (!_checkOnOpen) return;
    final info = await PackageInfo.fromPlatform();
    final result = await _check(info.version);
    if (result != null &&
        result.isNewer &&
        result.latestVersion != _dismissedVersion) {
      _pendingStartupToast = true;
      notifyListeners();
    }
  }

  /// Called by UI after showing the startup toast — prevents duplicate toasts.
  void acknowledgeStartupToast() {
    _pendingStartupToast = false;
    // No notifyListeners to avoid extra rebuilds.
  }

  /// Manual update check — shows spinner while in progress.
  Future<void> checkForUpdate() async {
    if (_checkingForUpdate) return;
    _checkingForUpdate = true;
    notifyListeners();
    final info = await PackageInfo.fromPlatform();
    await _check(info.version);
    _checkingForUpdate = false;
    notifyListeners();
  }

  Future<UpdateCheckResult?> _check(String currentVersion) async {
    if (_lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < _cooldown) {
      return _result;
    }

    try {
      final current = _parseSemver(currentVersion);
      if (current == null) return null;

      final response = await Dio().get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'Crossbar',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final tagName = data['tag_name'] as String?;
      if (tagName == null) return null;

      final latest = _parseSemver(tagName);
      if (latest == null) return null;

      String? apkUrl;
      final assets = data['assets'];
      if (assets is List) {
        for (final asset in assets) {
          final name = (asset['name'] as String?) ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      _lastCheck = DateTime.now();
      _result = UpdateCheckResult(
        latestVersion: latest.join('.'),
        releaseUrl: data['html_url'] as String?,
        releaseNotes: data['body'] as String?,
        apkUrl: apkUrl,
        isNewer: _isNewer(latest, current),
      );
      notifyListeners();
      return _result;
    } catch (e, st) {
      LoggerService().info('Update check failed: $e');
      LoggerService().error('Update check error', e, st);
      return null;
    }
  }

  List<int>? _parseSemver(String input) {
    var cleaned = input.trim().replaceFirst(RegExp(r'^v'), '');
    final dashIdx = cleaned.indexOf('-');
    if (dashIdx != -1) cleaned = cleaned.substring(0, dashIdx);
    final plusIdx = cleaned.indexOf('+');
    if (plusIdx != -1) cleaned = cleaned.substring(0, plusIdx);
    final parts = cleaned.split('.');
    if (parts.length != 3) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    return nums.cast<int>();
  }

  bool _isNewer(List<int> a, List<int> b) {
    for (int i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  Future<void> dismissUpdate() async {
    if (_result == null) return;
    _dismissedVersion = _result!.latestVersion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDismissedVersion, _dismissedVersion!);
    _installState = UpdateInstallState.idle;
    _installProgress = 0.0;
    notifyListeners();
  }

  /// Initiates platform-specific installation. Resets state first so guards clear.
  Future<void> startInstall() async {
    if (_installState == UpdateInstallState.downloading ||
        _installState == UpdateInstallState.installing) return;
    // Reset to idle so UI guard flags clear before new cycle.
    _installState = UpdateInstallState.idle;
    _installProgress = 0.0;
    notifyListeners();

    final result = _result;
    if (result == null) return;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _installAndroid(result);
    } else {
      await _installDesktop();
    }
  }

  Future<void> _installAndroid(UpdateCheckResult result) async {
    if (result.apkUrl == null) return;
    _installState = UpdateInstallState.downloading;
    _installProgress = 0.0;
    notifyListeners();

    final destPath =
        '${(await getTemporaryDirectory()).path}/crossbar-update.apk';
    try {
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 10),
        ),
      ).download(
        result.apkUrl!,
        destPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _installProgress = received / total;
            notifyListeners();
          }
        },
      );

      _installState = UpdateInstallState.installing;
      notifyListeners();
      await OpenFilex.open(destPath);
    } catch (e, st) {
      LoggerService().error('APK download/install failed', e, st);
      try {
        File(destPath).deleteSync();
      } catch (_) {}
      _installState = UpdateInstallState.failed;
      notifyListeners();
    }
  }

  Future<void> _installDesktop() async {
    _installState = UpdateInstallState.installing;
    notifyListeners();

    try {
      final ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run(
          'powershell',
          ['-c', 'irm install.cat/verseles/crossbar | iex'],
        ).timeout(const Duration(minutes: 5));
      } else {
        result = await Process.run(
          'sh',
          ['-c', 'curl -fsSL install.cat/verseles/crossbar | sh'],
        ).timeout(const Duration(minutes: 5));
      }
      _installState =
          result.exitCode == 0
              ? UpdateInstallState.done
              : UpdateInstallState.failed;
      notifyListeners();
    } catch (e, st) {
      LoggerService().error('Desktop install failed', e, st);
      _installState = UpdateInstallState.failed;
      notifyListeners();
    }
  }
}

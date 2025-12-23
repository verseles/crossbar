import 'dart:io';

/// Detects if StatusNotifierItem (SNI) is available on the system
/// This is needed to decide whether to use SNI backend or fallback to legacy
class SniDetector {
  /// Check if SNI is supported on this system
  static Future<bool> isSupported() async {
    // Check 1: Verify xdg_status_notifier_item package is available
    // (already in pubspec.yaml)

    // Check 2: Verify we're on Linux (SNI is Linux-only)
    if (!Platform.isLinux) {
      return false;
    }

    // Check 3: Verify desktop environment supports SNI
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    if (desktop == null) {
      return false;
    }

    final supportedDEs = [
      'GNOME',
      'KDE',
      'Unity',
      'Pantheon',
      'Budgie',
      'XFCE',
    ];

    final isCompatibleDE = supportedDEs.any(
      (de) => desktop.toUpperCase().contains(de.toUpperCase()),
    );

    if (!isCompatibleDE) {
      return false;
    }

    // Check 4: For GNOME, check if AppIndicator extension is available
    if (desktop.contains('GNOME')) {
      return await _checkGnomeExtension();
    }

    // KDE and other DEs have native SNI support
    return true;
  }

  /// Check if GNOME has AppIndicator extension installed
  static Future<bool> _checkGnomeExtension() async {
    try {
      // Check if gnome-extensions command is available
      final which = await Process.run('which', ['gnome-extensions']);
      if (which.exitCode != 0) {
        // gnome-extensions not available, but SNI might still work
        return true;
      }

      // List enabled extensions
      final result = await Process.run(
        'gnome-extensions',
        ['list', '--enabled'],
      );

      if (result.exitCode != 0) {
        return true; // Assume available if command fails
      }

      final extensions = result.stdout.toString().toLowerCase();

      // Check for common AppIndicator extension UUIDs
      const appIndicatorUuids = [
        'appindicatorsupport@rgcjonas.gmail.com',
        'ubuntu-appindicators@ubuntu.com',
        'kstatusnotifieritem',
      ];

      final hasExtension = appIndicatorUuids.any(
        (uuid) => extensions.contains(uuid.toLowerCase()),
      );

      return hasExtension;
    } catch (e) {
      // If check fails, assume SNI might be available
      return true;
    }
  }

  /// Get a human-readable reason why SNI is/n't supported
  static Future<String> getSupportReason() async {
    if (!Platform.isLinux) {
      return 'SNI is only supported on Linux';
    }

    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    if (desktop == null) {
      return 'No desktop environment detected';
    }

    if (desktop.contains('GNOME')) {
      final hasExtension = await _checkGnomeExtension();
      if (!hasExtension) {
        return 'GNOME detected but AppIndicator extension is not installed. '
               'Please install "AppIndicator and KStatusNotifier Support" '
               'from extensions.gnome.org';
      }
      return 'GNOME with AppIndicator extension detected';
    }

    if (desktop.contains('KDE')) {
      return 'KDE Plasma detected (native SNI support)';
    }

    return '$desktop detected (SNI should work)';
  }
}

import 'dart:io';

/// Utility API for system controls: screenshot, wallpaper, power, notifications, DND.
/// Uses platform-specific implementations:
/// - Linux: gnome-screenshot/scrot, gsettings, systemctl, notify-send
/// - macOS: screencapture, osascript, pmset
/// - Windows: PowerShell, registry
class UtilsApi {
  const UtilsApi();

  // ============================================================
  // SCREENSHOT
  // ============================================================

  /// Take a screenshot and save to path (or default location)
  /// Returns the path where screenshot was saved, or null on failure
  Future<String?> takeScreenshot({String? path, bool toClipboard = false}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final defaultPath = path ?? '${Platform.environment['HOME']}/screenshot_$timestamp.png';

      if (Platform.isLinux) {
        return _takeScreenshotLinux(defaultPath, toClipboard);
      }
      if (Platform.isMacOS) {
        return _takeScreenshotMacOS(defaultPath, toClipboard);
      }
      if (Platform.isWindows) {
        return _takeScreenshotWindows(defaultPath, toClipboard);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _takeScreenshotLinux(String path, bool toClipboard) async {
    // Try gnome-screenshot first, then scrot, then spectacle
    if (toClipboard) {
      // Try gnome-screenshot with clipboard
      try {
        var result = await Process.run('gnome-screenshot', ['-c']);
        if (result.exitCode == 0) return 'clipboard';
      } catch (_) {}

      // Try spectacle (KDE)
      try {
        var result = await Process.run('spectacle', ['-b', '-c']);
        if (result.exitCode == 0) return 'clipboard';
      } catch (_) {}

      // Try scrot with xclip
      try {
        var result = await Process.run('sh', ['-c', 'scrot -o /tmp/screenshot.png && xclip -selection clipboard -t image/png /tmp/screenshot.png']);
        if (result.exitCode == 0) return 'clipboard';
      } catch (_) {}

      return null;
    }

    // Save to file
    try {
      var result = await Process.run('gnome-screenshot', ['-f', path]);
      if (result.exitCode == 0) return path;
    } catch (_) {}

    try {
      var result = await Process.run('spectacle', ['-b', '-n', '-o', path]);
      if (result.exitCode == 0) return path;
    } catch (_) {}

    try {
      var result = await Process.run('scrot', ['-o', path]);
      if (result.exitCode == 0) return path;
    } catch (_) {}

    return null;
  }

  Future<String?> _takeScreenshotMacOS(String path, bool toClipboard) async {
    if (toClipboard) {
      final result = await Process.run('screencapture', ['-c']);
      return result.exitCode == 0 ? 'clipboard' : null;
    }
    final result = await Process.run('screencapture', [path]);
    return result.exitCode == 0 ? path : null;
  }

  Future<String?> _takeScreenshotWindows(String path, bool toClipboard) async {
    if (toClipboard) {
      final result = await Process.run('powershell', [
        '-command',
        'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object { \$bitmap = New-Object System.Drawing.Bitmap(\$_.Bounds.Width, \$_.Bounds.Height); \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap); \$graphics.CopyFromScreen(\$_.Bounds.Location, [System.Drawing.Point]::Empty, \$_.Bounds.Size); [System.Windows.Forms.Clipboard]::SetImage(\$bitmap) }',
      ]);
      return result.exitCode == 0 ? 'clipboard' : null;
    }
    final result = await Process.run('powershell', [
      '-command',
      '''
      Add-Type -AssemblyName System.Windows.Forms
      \$screen = [System.Windows.Forms.Screen]::PrimaryScreen
      \$bitmap = New-Object System.Drawing.Bitmap(\$screen.Bounds.Width, \$screen.Bounds.Height)
      \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
      \$graphics.CopyFromScreen(\$screen.Bounds.Location, [System.Drawing.Point]::Empty, \$screen.Bounds.Size)
      \$bitmap.Save("$path")
      ''',
    ]);
    return result.exitCode == 0 ? path : null;
  }

  // ============================================================
  // WALLPAPER
  // ============================================================

  /// Get current wallpaper path
  Future<String> getWallpaper() async {
    try {
      if (Platform.isLinux) {
        // Try GNOME first
        var result = await Process.run('gsettings', [
          'get',
          'org.gnome.desktop.background',
          'picture-uri',
        ]);
        if (result.exitCode == 0) {
          var path = (result.stdout as String).trim();
          // Remove quotes and file:// prefix
          path = path.replaceAll("'", '').replaceAll('file://', '');
          if (path.isNotEmpty && path != 'none') return path;
        }

        // Try dark mode variant
        result = await Process.run('gsettings', [
          'get',
          'org.gnome.desktop.background',
          'picture-uri-dark',
        ]);
        if (result.exitCode == 0) {
          var path = (result.stdout as String).trim();
          path = path.replaceAll("'", '').replaceAll('file://', '');
          if (path.isNotEmpty && path != 'none') return path;
        }

        // Try Cinnamon
        result = await Process.run('gsettings', [
          'get',
          'org.cinnamon.desktop.background',
          'picture-uri',
        ]);
        if (result.exitCode == 0) {
          var path = (result.stdout as String).trim();
          path = path.replaceAll("'", '').replaceAll('file://', '');
          if (path.isNotEmpty) return path;
        }

        return 'unknown';
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "Finder" to get POSIX path of (get desktop picture as alias)',
        ]);
        return result.exitCode == 0
            ? (result.stdout as String).trim()
            : 'unknown';
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          '(Get-ItemProperty -Path "HKCU:\\Control Panel\\Desktop" -Name Wallpaper).Wallpaper',
        ]);
        return result.exitCode == 0
            ? (result.stdout as String).trim()
            : 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Set wallpaper from path
  Future<bool> setWallpaper(String path) async {
    try {
      // Check if file exists
      if (!await File(path).exists()) {
        return false;
      }

      if (Platform.isLinux) {
        // Try GNOME
        var result = await Process.run('gsettings', [
          'set',
          'org.gnome.desktop.background',
          'picture-uri',
          'file://$path',
        ]);
        if (result.exitCode == 0) {
          // Also set dark mode wallpaper
          await Process.run('gsettings', [
            'set',
            'org.gnome.desktop.background',
            'picture-uri-dark',
            'file://$path',
          ]);
          return true;
        }

        // Try Cinnamon
        result = await Process.run('gsettings', [
          'set',
          'org.cinnamon.desktop.background',
          'picture-uri',
          'file://$path',
        ]);
        if (result.exitCode == 0) return true;

        // Try feh for minimal WMs
        result = await Process.run('feh', ['--bg-scale', path]);
        if (result.exitCode == 0) return true;

        return false;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "Finder" to set desktop picture to POSIX file "$path"',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          '''
          Add-Type @"
          using System;
          using System.Runtime.InteropServices;
          public class Wallpaper {
              [DllImport("user32.dll", CharSet = CharSet.Auto)]
              public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
          }
"@
          [Wallpaper]::SystemParametersInfo(0x0014, 0, "$path", 0x0001 -bor 0x0002)
          ''',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // POWER MANAGEMENT
  // ============================================================

  /// Suspend/sleep the system
  Future<bool> sleep() async {
    try {
      if (Platform.isLinux) {
        // Try systemctl first
        var result = await Process.run('systemctl', ['suspend']);
        if (result.exitCode == 0) return true;

        // Try pm-suspend
        result = await Process.run('pm-suspend', []);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('pmset', ['sleepnow']);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Application]::SetSuspendState("Suspend", \$false, \$false)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Restart the system (requires confirmation parameter for safety)
  Future<bool> restart({bool confirmed = false}) async {
    if (!confirmed) {
      return false; // Safety: require explicit confirmation
    }
    try {
      if (Platform.isLinux) {
        final result = await Process.run('systemctl', ['reboot']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to restart',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('shutdown', ['/r', '/t', '0']);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Shutdown the system (requires confirmation parameter for safety)
  Future<bool> shutdown({bool confirmed = false}) async {
    if (!confirmed) {
      return false; // Safety: require explicit confirmation
    }
    try {
      if (Platform.isLinux) {
        final result = await Process.run('systemctl', ['poweroff']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to shut down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('shutdown', ['/s', '/t', '0']);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  /// Send a desktop notification
  Future<bool> sendNotification({
    required String title,
    required String message,
    String? icon,
    String? sound,
    String? action,
    String priority = 'normal', // low, normal, critical
  }) async {
    try {
      if (Platform.isLinux) {
        final args = <String>[title, message];
        if (icon != null) {
          args.addAll(['-i', icon]);
        }
        if (priority == 'critical') {
          args.addAll(['-u', 'critical']);
        } else if (priority == 'low') {
          args.addAll(['-u', 'low']);
        }
        final result = await Process.run('notify-send', args);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        var script = 'display notification "$message" with title "$title"';
        if (sound != null) {
          script += ' sound name "$sound"';
        }
        final result = await Process.run('osascript', ['-e', script]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          '''
          [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
          \$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
          \$textNodes = \$template.GetElementsByTagName("text")
          \$textNodes.Item(0).AppendChild(\$template.CreateTextNode("$title")) | Out-Null
          \$textNodes.Item(1).AppendChild(\$template.CreateTextNode("$message")) | Out-Null
          \$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Crossbar")
          \$notification = [Windows.UI.Notifications.ToastNotification]::new(\$template)
          \$notifier.Show(\$notification)
          ''',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // DO NOT DISTURB (DND)
  // ============================================================

  /// Get Do Not Disturb status
  Future<bool> getDndStatus() async {
    try {
      if (Platform.isLinux) {
        // GNOME
        final result = await Process.run('gsettings', [
          'get',
          'org.gnome.desktop.notifications',
          'show-banners',
        ]);
        if (result.exitCode == 0) {
          final value = (result.stdout as String).trim();
          // show-banners=false means DND is ON
          return value == 'false';
        }
        return false;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('defaults', [
          '-currentHost',
          'read',
          'com.apple.notificationcenterui',
          'doNotDisturb',
        ]);
        if (result.exitCode == 0) {
          return (result.stdout as String).trim() == '1';
        }
        return false;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          'Get-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings" -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NOC_GLOBAL_SETTING_TOASTS_ENABLED',
        ]);
        if (result.exitCode == 0) {
          // 0 means DND is ON (toasts disabled)
          return (result.stdout as String).trim() == '0';
        }
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Set Do Not Disturb status
  Future<bool> setDnd(bool enabled) async {
    try {
      if (Platform.isLinux) {
        // GNOME - show-banners=false means DND is ON
        final result = await Process.run('gsettings', [
          'set',
          'org.gnome.desktop.notifications',
          'show-banners',
          enabled ? 'false' : 'true',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final value = enabled ? '1' : '0';
        final result = await Process.run('defaults', [
          '-currentHost',
          'write',
          'com.apple.notificationcenterui',
          'doNotDisturb',
          '-bool',
          value,
        ]);
        if (result.exitCode == 0) {
          // Restart notification center to apply
          await Process.run('killall', ['NotificationCenter']);
          return true;
        }
        return false;
      }
      if (Platform.isWindows) {
        final value = enabled ? '0' : '1'; // 0 = DND ON, 1 = DND OFF
        final result = await Process.run('powershell', [
          '-command',
          'Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings" -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value $value',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // OPEN/LAUNCH UTILITIES
  // ============================================================

  /// Open URL in default browser
  Future<bool> openUrl(String url) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [url]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('open', [url]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('start', [url], runInShell: true);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Open file with default application
  Future<bool> openFile(String path) async {
    try {
      if (!await File(path).exists() && !await Directory(path).exists()) {
        return false;
      }
      if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [path]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('open', [path]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('start', ['', path], runInShell: true);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Launch application by name
  Future<bool> openApp(String appName) async {
    try {
      if (Platform.isLinux) {
        // Try direct execution first
        var result = await Process.run('which', [appName]);
        if (result.exitCode == 0) {
          final appPath = (result.stdout as String).trim();
          await Process.start(appPath, [], mode: ProcessStartMode.detached);
          return true;
        }
        // Try gtk-launch for .desktop files
        result = await Process.run('gtk-launch', [appName]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('open', ['-a', appName]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('start', [appName], runInShell: true);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

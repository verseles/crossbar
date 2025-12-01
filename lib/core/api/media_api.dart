import 'dart:convert';
import 'dart:io';

/// Media control API for playback, volume, and brightness controls.
/// Uses platform-specific implementations:
/// - Linux: playerctl (MPRIS D-Bus), PulseAudio, sysfs
/// - macOS: AppleScript, MediaRemote
/// - Windows: PowerShell, MediaPlayer
class MediaApi {
  const MediaApi();

  // ============================================================
  // MEDIA PLAYBACK CONTROLS
  // ============================================================

  /// Resume media playback
  Future<bool> play() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['play']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to key code 16 using control down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB3)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Pause media playback
  Future<bool> pause() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['pause']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to key code 16 using control down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB3)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Toggle play/pause
  Future<bool> playPause() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['play-pause']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to key code 16 using control down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB3)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stop media playback
  Future<bool> stop() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['stop']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "Music" to stop',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB2)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Skip to next track
  Future<bool> next() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['next']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to key code 17 using control down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB0)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Go to previous track
  Future<bool> previous() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('playerctl', ['previous']);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to key code 18 using control down',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]0xB1)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Seek relative position (e.g., "+30", "-10" in seconds)
  Future<bool> seek(String offset) async {
    try {
      // Parse offset string like "+30s", "-10s", "+30", "-10"
      final cleanOffset = offset.replaceAll('s', '');
      final seconds = int.tryParse(cleanOffset) ?? 0;

      if (Platform.isLinux) {
        // playerctl position expects offset in seconds with +/- prefix
        final result = await Process.run('playerctl', [
          'position',
          '${seconds >= 0 ? '+' : ''}$seconds',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          '''
          tell application "Music"
            set player position to (player position + $seconds)
          end tell
          ''',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        // Windows media keys don't support seek directly
        // Would require specific player control
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current playing track info
  Future<Map<String, dynamic>> getPlaying() async {
    try {
      if (Platform.isLinux) {
        return _getLinuxPlaying();
      }
      if (Platform.isMacOS) {
        return _getMacOsPlaying();
      }
      if (Platform.isWindows) {
        return _getWindowsPlaying();
      }
      return {'status': 'unsupported'};
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getLinuxPlaying() async {
    try {
      final statusResult = await Process.run('playerctl', ['status']);
      final status = (statusResult.stdout as String).trim().toLowerCase();

      if (status == 'no players found' || statusResult.exitCode != 0) {
        return {'status': 'stopped', 'playing': false};
      }

      final metadataResult = await Process.run('playerctl', [
        'metadata',
        '--format',
        '{{artist}}|||{{title}}|||{{album}}|||{{duration(position)}}|||{{duration(mpris:length)}}',
      ]);

      final parts = (metadataResult.stdout as String).trim().split('|||');

      return {
        'status': status,
        'playing': status == 'playing',
        'artist': parts.isNotEmpty ? parts[0] : '',
        'title': parts.length > 1 ? parts[1] : '',
        'album': parts.length > 2 ? parts[2] : '',
        'position': parts.length > 3 ? parts[3] : '',
        'duration': parts.length > 4 ? parts[4] : '',
      };
    } catch (e) {
      // playerctl not installed or other error
      return {'status': 'unavailable', 'playing': false};
    }
  }

  Future<Map<String, dynamic>> _getMacOsPlaying() async {
    final result = await Process.run('osascript', [
      '-e',
      '''
      tell application "Music"
        if player state is playing then
          set trackName to name of current track
          set trackArtist to artist of current track
          set trackAlbum to album of current track
          set trackDuration to duration of current track
          set trackPosition to player position
          return "playing|||" & trackArtist & "|||" & trackName & "|||" & trackAlbum & "|||" & trackPosition & "|||" & trackDuration
        else
          return "stopped"
        end if
      end tell
      ''',
    ]);

    final output = (result.stdout as String).trim();
    if (output == 'stopped' || result.exitCode != 0) {
      return {'status': 'stopped', 'playing': false};
    }

    final parts = output.split('|||');
    return {
      'status': parts[0],
      'playing': parts[0] == 'playing',
      'artist': parts.length > 1 ? parts[1] : '',
      'title': parts.length > 2 ? parts[2] : '',
      'album': parts.length > 3 ? parts[3] : '',
      'position': parts.length > 4 ? parts[4] : '',
      'duration': parts.length > 5 ? parts[5] : '',
    };
  }

  Future<Map<String, dynamic>> _getWindowsPlaying() async {
    // Windows doesn't have a universal way to get media info
    // This would require specific player integration
    return {'status': 'unsupported', 'playing': false};
  }

  // ============================================================
  // AUDIO VOLUME CONTROLS
  // ============================================================

  /// Get current volume (0-100)
  Future<int> getVolume() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run(
          'pactl',
          ['get-sink-volume', '@DEFAULT_SINK@'],
        );
        final output = result.stdout as String;
        final match = RegExp(r'(\d+)%').firstMatch(output);
        return match != null ? int.parse(match.group(1)!) : 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'output volume of (get volume settings)',
        ]);
        return int.tryParse((result.stdout as String).trim()) ?? 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'[Audio]::Volume * 100',
        ]);
        return int.tryParse((result.stdout as String).trim()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Set volume (0-100)
  Future<bool> setVolume(int level) async {
    final clampedLevel = level.clamp(0, 100);
    try {
      if (Platform.isLinux) {
        final result = await Process.run('pactl', [
          'set-sink-volume',
          '@DEFAULT_SINK@',
          '$clampedLevel%',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'set volume output volume $clampedLevel',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        // Using nircmd if available, otherwise PowerShell
        final result = await Process.run('powershell', [
          '-command',
          '''
          \$wshShell = New-Object -ComObject WScript.Shell
          for (\$i = 0; \$i -lt 50; \$i++) { \$wshShell.SendKeys([char]174) }
          for (\$i = 0; \$i -lt $clampedLevel / 2; \$i++) { \$wshShell.SendKeys([char]175) }
          ''',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get mute status
  Future<bool> isMuted() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run(
          'pactl',
          ['get-sink-mute', '@DEFAULT_SINK@'],
        );
        return (result.stdout as String).contains('yes');
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'output muted of (get volume settings)',
        ]);
        return (result.stdout as String).trim() == 'true';
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'[Audio]::Mute',
        ]);
        return (result.stdout as String).trim().toLowerCase() == 'true';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Toggle mute
  Future<bool> toggleMute() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('pactl', [
          'set-sink-mute',
          '@DEFAULT_SINK@',
          'toggle',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          '''
          set currentMute to output muted of (get volume settings)
          set volume with output muted (not currentMute)
          ''',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          r'(New-Object -ComObject WScript.Shell).SendKeys([char]173)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Set mute state explicitly
  Future<bool> setMute(bool muted) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('pactl', [
          'set-sink-mute',
          '@DEFAULT_SINK@',
          muted ? '1' : '0',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'set volume with output muted $muted',
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        // Toggle approach if current state differs
        final currentMute = await isMuted();
        if (currentMute != muted) {
          return toggleMute();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current audio output device
  Future<String> getAudioOutput() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('pactl', ['get-default-sink']);
        return (result.stdout as String).trim();
      }
      if (Platform.isMacOS) {
        final result = await Process.run('sh', [
          '-c',
          "system_profiler SPAudioDataType | grep 'Default Output Device' | cut -d':' -f2",
        ]);
        return (result.stdout as String).trim();
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          'Get-AudioDevice -Playback | Select-Object -ExpandProperty Name',
        ]);
        return (result.stdout as String).trim();
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// List available audio output devices
  Future<List<Map<String, String>>> listAudioOutputs() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run(
          'pactl',
          ['list', 'sinks', 'short'],
        );
        final lines = (result.stdout as String).trim().split('\n');
        return lines.where((l) => l.isNotEmpty).map((line) {
          final parts = line.split('\t');
          return {
            'id': parts.isNotEmpty ? parts[0] : '',
            'name': parts.length > 1 ? parts[1] : '',
            'driver': parts.length > 2 ? parts[2] : '',
          };
        }).toList();
      }
      if (Platform.isMacOS) {
        final result = await Process.run('sh', [
          '-c',
          "system_profiler SPAudioDataType | grep -A1 'Output:' | grep 'Name'",
        ]);
        final lines = (result.stdout as String).trim().split('\n');
        return lines.where((l) => l.isNotEmpty).map((line) {
          final name = line.replaceAll('Name:', '').trim();
          return {'id': name, 'name': name};
        }).toList();
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          'Get-AudioDevice -List | Where-Object Type -eq "Playback" | ConvertTo-Json',
        ]);
        try {
          final json = jsonDecode(result.stdout as String);
          if (json is List) {
            return json.map<Map<String, String>>((item) {
              return {
                'id': item['ID']?.toString() ?? '',
                'name': item['Name']?.toString() ?? '',
              };
            }).toList();
          }
        } catch (_) {}
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Set audio output device
  Future<bool> setAudioOutput(String deviceId) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('pactl', [
          'set-default-sink',
          deviceId,
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        // Requires SwitchAudioSource or similar tool
        final result = await Process.run('SwitchAudioSource', ['-s', deviceId]);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          'Set-AudioDevice -ID "$deviceId"',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // SCREEN BRIGHTNESS CONTROLS
  // ============================================================

  /// Get current screen brightness (0-100)
  Future<int> getBrightness() async {
    try {
      if (Platform.isLinux) {
        // Try brightnessctl first
        var result = await Process.run('brightnessctl', ['get']);
        if (result.exitCode == 0) {
          final current = int.tryParse((result.stdout as String).trim()) ?? 0;
          result = await Process.run('brightnessctl', ['max']);
          final max = int.tryParse((result.stdout as String).trim()) ?? 100;
          return (current * 100 / max).round();
        }

        // Fallback to sysfs
        result = await Process.run('sh', [
          '-c',
          'cat /sys/class/backlight/*/brightness /sys/class/backlight/*/max_brightness 2>/dev/null | head -2',
        ]);
        final lines = (result.stdout as String).trim().split('\n');
        if (lines.length >= 2) {
          final current = int.tryParse(lines[0]) ?? 0;
          final max = int.tryParse(lines[1]) ?? 100;
          return (current * 100 / max).round();
        }
        return 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('brightness', ['-l']);
        final output = result.stdout as String;
        final match =
            RegExp(r'display 0: brightness ([\d.]+)').firstMatch(output);
        if (match != null) {
          return (double.parse(match.group(1)!) * 100).round();
        }
        return 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness).CurrentBrightness',
        ]);
        return int.tryParse((result.stdout as String).trim()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Set screen brightness (0-100)
  Future<bool> setBrightness(int level) async {
    final clampedLevel = level.clamp(0, 100);
    try {
      if (Platform.isLinux) {
        // Try brightnessctl first
        var result =
            await Process.run('brightnessctl', ['set', '$clampedLevel%']);
        if (result.exitCode == 0) return true;

        // Fallback to xrandr (requires output name)
        final brightness = clampedLevel / 100.0;
        result = await Process.run('sh', [
          '-c',
          "xrandr --output \$(xrandr | grep ' connected' | head -1 | cut -d' ' -f1) --brightness $brightness",
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final brightness = clampedLevel / 100.0;
        final result = await Process.run('brightness', ['$brightness']);
        return result.exitCode == 0;
      }
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-command',
          '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $clampedLevel)',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

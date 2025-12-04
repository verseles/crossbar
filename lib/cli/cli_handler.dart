import 'dart:io';

import 'commands/audio_command.dart';
import 'commands/base_command.dart';
import 'commands/bluetooth_command.dart';
import 'commands/clipboard_command.dart';
import 'commands/dnd_command.dart';
import 'commands/filesystem_commands.dart';
import 'commands/media_command.dart';
import 'commands/network_command.dart';
import 'commands/plugin_commands.dart';
import 'commands/power_command.dart';
import 'commands/screen_command.dart';
import 'commands/system_info_commands.dart';
import 'commands/utility_commands.dart';
import 'commands/vpn_command.dart';
import 'commands/wallpaper_command.dart';
import 'commands/wifi_command.dart';

const String version = '1.1.0';

final Map<String, CliCommand> _commands = {};

void _registerCommands() {
  if (_commands.isNotEmpty) return;

  // Audio & Media
  _register(AudioCommand());
  _register(MediaCommand());

  // System & Hardware
  _register(ScreenCommand());
  _register(PowerCommand());
  _register(WallpaperCommand());
  _register(DndCommand());

  // Network
  _register(NetworkCommand());
  _register(WifiCommand());
  _register(BluetoothCommand());
  _register(VpnCommand());

  // Utilities
  _register(ClipboardCommand());
  _register(FileCommand());
  _register(DirCommand());
  _register(ExecCommand());
  _register(NotifyCommand());
  _register(OpenCommand());

  // Misc
  _register(TimeCommand());
  _register(DateCommand());
  _register(HashCommand());
  _register(UuidCommand());
  _register(RandomCommand());
  _register(Base64Command());

  // System Info
  _register(CpuCommand());
  _register(MemoryCommand());
  _register(BatteryCommand());
  _register(UptimeCommand());
  _register(DiskCommand());
  _register(OsCommand());
  _register(KernelCommand());
  _register(ArchCommand());
  _register(HostnameCommand());
  _register(UsernameCommand());
  _register(HomeCommand());
  _register(TempCommand());
  _register(EnvCommand());
  _register(LocaleCommand());
  _register(TimezoneCommand());

  // Plugin
  _register(InitCommand());
  _register(InstallCommand());
  _register(RunPluginCommand());
}

void _register(CliCommand command) {
  _commands[command.name] = command;
}

/// Handles CLI command execution
/// Returns exit code (0 for success, non-zero for error)
Future<int> handleCliCommand(List<String> args) async {
  _registerCommands();

  if (args.isEmpty) {
    _printUsage();
    return 1;
  }

  final commandName = args[0];

  if (commandName == '--version' || commandName == '-v') {
    print('Crossbar version $version');
    return 0;
  }

  if (commandName == '--help' || commandName == '-h' || commandName == 'help') {
    _printUsage();
    return 0;
  }

  // Handle double-dash prefix removal (allow both crossbar cpu and crossbar --cpu)
  final cleanName = commandName.startsWith('--') ? commandName.substring(2) : commandName;

  final command = _commands[cleanName];
  if (command != null) {
    try {
      return await command.execute(args.sublist(1));
    } catch (e) {
      stderr.writeln('Error executing $cleanName: $e');
      return 1;
    }
  } else {
    stderr.writeln('Error: Unknown command: $commandName');
    _printUsage();
    return 1;
  }
}

void _printUsage() {
  print('''
Crossbar - Universal Plugin System
Version: $version

Usage: crossbar [command] [subcommand] [value]

System Info (Simple Getters):
  cpu                CPU usage percentage
  memory             RAM usage (used/total)
  battery            Battery level and status
  uptime             System uptime
  os                 Operating system
  hostname           System hostname
  username           Current username
  kernel             Kernel version
  arch               System architecture

Audio Controls (audio):
  audio volume [0-100]      Get volume or Set volume
  audio mute                Toggle mute
  audio output [device]     Get output or Set device
  audio output --list       List output devices

Media Controls (media):
  media play                Resume playback
  media pause               Pause playback
  media toggle              Toggle play/pause
  media stop                Stop playback
  media next                Next track
  media prev                Previous track
  media seek <offset>       Seek (e.g., +30s, -10s)
  media playing             Current track info

Screen & Display (screen):
  screen brightness [0-100] Get or Set brightness
  screen size               Get screen resolution

Wallpaper:
  wallpaper [path]          Get current path or Set wallpaper

Do Not Disturb (dnd):
  dnd [on|off|toggle]       Get status or Set status

Power Management (power):
  power sleep               Suspend system
  power restart --confirm   Restart system
  power shutdown --confirm  Shutdown system

Network & Connectivity:
  net status                Connection status
  net ip [--public]         Local or Public IP
  net ping <host>           Ping latency

  wifi [on|off|toggle]      Get WiFi status or Set on/off
  wifi ssid                 Get connected SSID

  bluetooth [on|off|toggle] Get status or Set on/off
  bluetooth devices         List paired devices

  vpn status                VPN connection status

Files & Directories:
  file exists <path>        Check if file/dir exists
  file read <path>          Read file contents
  file size <path>          Get file size
  dir list [path]           List directory contents

Utilities:
  clipboard [text]          Get content or Set text
  exec <command>            Execute shell command
  notify <title> <msg>      Send notification
  open url <url>            Open URL
  open file <path>          Open file
  open app <name>           Launch application

  time                      Current time
  date                      Current date
  hash <text>               Hash text
  uuid                      Generate UUID
  random [min] [max]        Random number
  base64 encode <text>      Base64 encode
  base64 decode <text>      Base64 decode

Plugin Management:
  init --lang <lang> ...    Create a new plugin
  install <url>             Install plugin from GitHub

Options:
  --json                    Output in JSON format
  --xml                     Output in XML format
  --version, -v             Show version
  --help, -h                Show this help
''');
}

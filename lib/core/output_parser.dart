import 'dart:convert';

import '../models/plugin_output.dart';

class OutputParser {
  static bool isJson(String output) {
    final trimmed = output.trim();
    return trimmed.startsWith('{') && trimmed.endsWith('}');
  }

  static PluginOutput parse(String output, String pluginId) {
    try {
      final trimmedOutput = output.trim();
      if (trimmedOutput.isEmpty) {
        return PluginOutput.empty(pluginId);
      }

      if (isJson(trimmedOutput)) {
        return _parseJson(trimmedOutput, pluginId);
      } else {
        return _parseBitBar(trimmedOutput, pluginId);
      }
    } catch (e) {
      return PluginOutput.error(pluginId, 'Failed to parse output: $e');
    }
  }

  static PluginOutput _parseJson(String jsonString, String pluginId) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    return PluginOutput(
      pluginId: pluginId,
      icon: data['icon'] as String? ?? '',
      text: data['text'] as String?,
      color: data['color'] != null
          ? _parseColor(data['color'] as String)
          : null,
      trayTooltip: data['tray_tooltip'] as String?,
      menu: _parseMenuItems(data['menu'] as List<dynamic>? ?? []),
    );
  }

  static PluginOutput _parseBitBar(String text, String pluginId) {
    final lines = text.split('\n').where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return PluginOutput(pluginId: pluginId, icon: '', text: '');
    }

    final firstLine = lines.first;
    var icon = '';
    String? displayText;
    String? colorStr;

    if (firstLine.contains('|')) {
      final parts = firstLine.split('|');
      final mainText = parts[0].trim();

      final parsed = _parseIconAndText(mainText);
      icon = parsed.icon;
      displayText = parsed.text;

      for (var i = 1; i < parts.length; i++) {
        final attr = parts[i].trim();
        if (attr.startsWith('color=')) {
          colorStr = attr.substring(6);
        }
      }
    } else {
      final parsed = _parseIconAndText(firstLine);
      icon = parsed.icon;
      displayText = parsed.text;
    }

    final menu = <MenuItem>[];
    var inMenu = false;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim() == '---') {
        inMenu = true;
        continue;
      }

      if (!inMenu) continue;

      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.contains('|')) {
        final parts = trimmedLine.split('|');
        final itemText = parts[0].trim();
        String? bash;
        String? href;
        String? itemColor;

        for (var k = 1; k < parts.length; k++) {
          final attr = parts[k].trim();
          if (attr.startsWith('bash=')) {
            bash = attr.substring(5);
          } else if (attr.startsWith('href=')) {
            href = attr.substring(5);
          } else if (attr.startsWith('color=')) {
            itemColor = attr.substring(6);
          }
        }

        menu.add(MenuItem(
          text: itemText,
          bash: bash,
          href: href,
          color: itemColor,
        ));
      } else {
        menu.add(MenuItem(text: trimmedLine));
      }
    }

    return PluginOutput(
      pluginId: pluginId,
      icon: icon,
      text: displayText,
      color: colorStr != null ? _parseColor(colorStr) : null,
      menu: menu,
    );
  }

  static ({String icon, String? text}) _parseIconAndText(String input) {
    if (input.isEmpty) {
      return (icon: '', text: null);
    }

    final runes = input.runes.toList();
    if (runes.isEmpty) {
      return (icon: '', text: null);
    }

    final firstCodePoint = runes.first;

    if (_isEmoji(firstCodePoint) || firstCodePoint > 127) {
      final firstChar = String.fromCharCode(firstCodePoint);
      final remaining = input.substring(firstChar.length).trim();
      return (
        icon: firstChar,
        text: remaining.isNotEmpty ? remaining : null,
      );
    }

    return (icon: '', text: input);
  }

  static bool _isEmoji(int codePoint) {
    return (codePoint >= 0x1F600 && codePoint <= 0x1F64F) ||
        (codePoint >= 0x1F300 && codePoint <= 0x1F5FF) ||
        (codePoint >= 0x1F680 && codePoint <= 0x1F6FF) ||
        (codePoint >= 0x1F700 && codePoint <= 0x1F77F) ||
        (codePoint >= 0x1F780 && codePoint <= 0x1F7FF) ||
        (codePoint >= 0x1F800 && codePoint <= 0x1F8FF) ||
        (codePoint >= 0x1F900 && codePoint <= 0x1F9FF) ||
        (codePoint >= 0x1FA00 && codePoint <= 0x1FA6F) ||
        (codePoint >= 0x1FA70 && codePoint <= 0x1FAFF) ||
        (codePoint >= 0x2600 && codePoint <= 0x26FF) ||
        (codePoint >= 0x2700 && codePoint <= 0x27BF) ||
        (codePoint >= 0x231A && codePoint <= 0x231B) ||
        (codePoint >= 0x23E9 && codePoint <= 0x23F3) ||
        (codePoint >= 0x23F8 && codePoint <= 0x23FA) ||
        codePoint == 0x2614 ||
        codePoint == 0x2615 ||
        codePoint == 0x2648 ||
        codePoint == 0x267F ||
        codePoint == 0x2693 ||
        codePoint == 0x26A1 ||
        codePoint == 0x26AA ||
        codePoint == 0x26AB ||
        codePoint == 0x26BD ||
        codePoint == 0x26BE ||
        codePoint == 0x26C4 ||
        codePoint == 0x26C5 ||
        codePoint == 0x26CE ||
        codePoint == 0x26D4 ||
        codePoint == 0x26EA ||
        codePoint == 0x26F2 ||
        codePoint == 0x26F3 ||
        codePoint == 0x26F5 ||
        codePoint == 0x26FA ||
        codePoint == 0x26FD ||
        codePoint == 0x2702 ||
        codePoint == 0x2705 ||
        codePoint == 0x2708 ||
        codePoint == 0x2709 ||
        codePoint == 0x270A ||
        codePoint == 0x270B ||
        codePoint == 0x270C ||
        codePoint == 0x270D ||
        codePoint == 0x270F ||
        codePoint == 0x2712 ||
        codePoint == 0x2714 ||
        codePoint == 0x2716 ||
        codePoint == 0x271D ||
        codePoint == 0x2721 ||
        codePoint == 0x2728 ||
        codePoint == 0x2733 ||
        codePoint == 0x2734 ||
        codePoint == 0x2744 ||
        codePoint == 0x2747 ||
        codePoint == 0x274C ||
        codePoint == 0x274E ||
        codePoint == 0x2753 ||
        codePoint == 0x2754 ||
        codePoint == 0x2755 ||
        codePoint == 0x2757 ||
        codePoint == 0x2763 ||
        codePoint == 0x2764 ||
        codePoint == 0x2795 ||
        codePoint == 0x2796 ||
        codePoint == 0x2797 ||
        codePoint == 0x27A1 ||
        codePoint == 0x27B0 ||
        codePoint == 0x27BF;
  }

  static List<MenuItem> _parseMenuItems(List<dynamic> items) {
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      if (map['separator'] == true) {
        return MenuItem.separator();
      }
      return MenuItem(
        text: map['text'] as String?,
        bash: map['bash'] as String?,
        href: map['href'] as String?,
        submenu: map['submenu'] != null
            ? _parseMenuItems(map['submenu'] as List<dynamic>)
            : null,
        color: map['color'] as String?,
      );
    }).toList();
  }

  static int? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    final colors = <String, int>{
      'red': 0xFFFF0000,
      'green': 0xFF00FF00,
      'blue': 0xFF0000FF,
      'yellow': 0xFFFFFF00,
      'orange': 0xFFFFA500,
      'purple': 0xFF800080,
      'pink': 0xFFFFC0CB,
      'cyan': 0xFF00FFFF,
      'white': 0xFFFFFFFF,
      'black': 0xFF000000,
      'grey': 0xFF808080,
      'gray': 0xFF808080,
    };

    final lowerColor = colorString.toLowerCase();
    if (colors.containsKey(lowerColor)) {
      return colors[lowerColor];
    }

    if (colorString.startsWith('#')) {
      try {
        var hex = colorString.substring(1);
        if (hex.length == 3) {
          hex = hex.split('').map((c) => '$c$c').join();
        }
        if (hex.length == 6) {
          hex = 'FF$hex';
        }
        return int.parse(hex, radix: 16);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}

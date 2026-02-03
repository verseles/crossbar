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
      color:
          data['color'] != null ? _parseColor(data['color'] as String) : null,
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
      final parsedLine = _splitBitbarLine(firstLine);
      final mainText = parsedLine.text.trim();

      final parsed = _parseIconAndText(mainText);
      icon = parsed.icon;
      displayText = parsed.text;

      colorStr = parsedLine.attributes['color'];
    } else {
      final parsed = _parseIconAndText(firstLine);
      icon = parsed.icon;
      displayText = parsed.text;
    }

    final menu = <MenuItem>[];
    var inMenu = false;

    // Stack to track parent items at each depth level
    // Index 0 = root menu, Index 1 = first submenu level, etc.
    final parentStack = <List<MenuItem>>[menu];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];

      // Check for separator (exactly ---) - but not submenu indicator (--)
      if (line.trim() == '---') {
        if (!inMenu) {
          // First --- marks the start of the menu section
          inMenu = true;
        } else {
          // Subsequent --- add visual separators to current level
          parentStack.last.add(MenuItem.separator());
        }
        continue;
      }

      if (!inMenu) continue;

      // Parse indent level and get actual content
      final indentInfo = _parseIndentedLine(line);
      final depth = indentInfo.depth;
      final content = indentInfo.content;

      if (content.isEmpty) continue;

      // Parse menu item from content
      final item = _parseMenuItemFromLine(content);

      // Adjust parent stack to correct depth
      // depth 0 = root menu, depth 1 = submenu of last root item, etc.
      while (parentStack.length > depth + 1) {
        parentStack.removeLast();
      }

      // If we need to go deeper, ensure parent has submenu
      while (parentStack.length < depth + 1) {
        final lastList = parentStack.last;
        if (lastList.isNotEmpty) {
          final lastItem = lastList.last;
          // Initialize submenu if needed
          if (lastItem.submenu == null) {
            // Create a new item with submenu
            final newItem = lastItem.copyWith(submenu: <MenuItem>[]);
            lastList[lastList.length - 1] = newItem;
            parentStack.add(newItem.submenu!);
          } else {
            parentStack.add(lastItem.submenu!);
          }
        } else {
          // Cannot add child to empty parent, add to root
          break;
        }
      }

      // Add item to current level
      parentStack.last.add(item);
    }

    return PluginOutput(
      pluginId: pluginId,
      icon: icon,
      text: displayText,
      color: colorStr != null ? _parseColor(colorStr) : null,
      menu: menu,
    );
  }

  /// Parses BitBar-style indented line (-- prefix indicates submenu level)
  /// Returns the depth level and the actual content without the prefix.
  static ({int depth, String content}) _parseIndentedLine(String line) {
    var depth = 0;
    var current = line;

    // Count leading -- pairs (each -- is one level)
    while (current.startsWith('--')) {
      depth++;
      current = current.substring(2);
    }

    return (depth: depth, content: current.trim());
  }

  /// Parses a single menu item line (already stripped of -- prefix)
  static MenuItem _parseMenuItemFromLine(String line) {
    if (!line.contains('|')) {
      return MenuItem(text: line);
    }

    final parsedLine = _splitBitbarLine(line);
    final itemText = parsedLine.text.trim();

    return MenuItem(
      text: itemText,
      bash: parsedLine.attributes['bash'],
      href: parsedLine.attributes['href'],
      color: parsedLine.attributes['color'],
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

  static ({String text, Map<String, String> attributes}) _splitBitbarLine(
    String line,
  ) {
    final pipeIndex = line.indexOf('|');
    if (pipeIndex == -1) {
      return (text: line, attributes: const {});
    }

    final textPart = line.substring(0, pipeIndex).trimRight();
    final attributesPart = line.substring(pipeIndex + 1).trim();
    final attributes = _parseAttributes(attributesPart);

    return (text: textPart, attributes: attributes);
  }

  static Map<String, String> _parseAttributes(String input) {
    if (input.isEmpty) return {};

    final normalized = input.replaceAll('|', ' ');
    final tokens = _tokenizeAttributes(normalized);
    final attributes = <String, String>{};

    String? currentKey;

    for (final token in tokens) {
      final equalsIndex = token.indexOf('=');
      if (equalsIndex > 0) {
        final key = token.substring(0, equalsIndex);
        var value = token.substring(equalsIndex + 1);
        value = _stripQuotes(value);
        attributes[key] = value;
        currentKey = key;
      } else if (currentKey != null) {
        final existing = attributes[currentKey] ?? '';
        attributes[currentKey!] = existing.isEmpty ? token : '$existing $token';
      }
    }

    return attributes;
  }

  static List<String> _tokenizeAttributes(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    String? quote;
    var escaping = false;

    void flush() {
      if (buffer.isNotEmpty) {
        tokens.add(buffer.toString());
        buffer.clear();
      }
    }

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (escaping) {
        buffer.write(ch);
        escaping = false;
        continue;
      }

      if (ch == '\\') {
        escaping = true;
        continue;
      }

      if (quote != null) {
        if (ch == quote) {
          quote = null;
        } else {
          buffer.write(ch);
        }
        continue;
      }

      if (ch == '"' || ch == '\'') {
        quote = ch;
        continue;
      }

      if (ch.trim().isEmpty) {
        flush();
        continue;
      }

      buffer.write(ch);
    }

    flush();
    return tokens;
  }

  static String _stripQuotes(String value) {
    if (value.length < 2) return value;
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}

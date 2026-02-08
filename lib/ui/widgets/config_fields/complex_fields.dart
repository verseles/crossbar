import 'dart:convert';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'config_field.dart';

/// Image picker with preview — stores absolute path.
class ImageConfigField extends ConfigField {
  const ImageConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _ImageField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _ImageField extends StatefulWidget {
  const _ImageField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends State<_ImageField> {
  late String _path;

  @override
  void initState() {
    super.initState();
    _path = widget.value ?? widget.setting.defaultValue ?? '';
  }

  Future<void> _pickImage() async {
    final accepts = (widget.setting.accept ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('.') ? e.substring(1) : e)
        .toList();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: accepts.isEmpty ? FileType.image : FileType.custom,
      allowedExtensions: accepts.isEmpty ? null : accepts,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _path = result.files.single.path!);
      widget.onChanged(_path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.setting.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.setting.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (_path.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Text(
                _path.split('/').last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: Text(_path.isEmpty ? 'Choose Image' : 'Change Image'),
        ),
        if (widget.setting.help != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.setting.help!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dynamic key-value pair editor — stores value as JSON object string.
class KeyValueConfigField extends ConfigField {
  const KeyValueConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _KeyValueField(
      setting: setting,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _KeyValueField extends StatefulWidget {
  const _KeyValueField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_KeyValueField> createState() => _KeyValueFieldState();
}

class _KeyValueFieldState extends State<_KeyValueField> {
  late List<MapEntry<String, String>> _pairs;

  @override
  void initState() {
    super.initState();
    _pairs = _parsePairs(widget.value ?? widget.setting.defaultValue ?? '');
  }

  List<MapEntry<String, String>> _parsePairs(String raw) {
    if (raw.isEmpty) return [const MapEntry('', '')];
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map.isEmpty) return [const MapEntry('', '')];
      return map.entries
          .map((e) => MapEntry(e.key, e.value.toString()))
          .toList();
    } catch (_) {
      return [const MapEntry('', '')];
    }
  }

  void _emit() {
    final map = <String, String>{};
    for (final pair in _pairs) {
      if (pair.key.isNotEmpty) {
        map[pair.key] = pair.value;
      }
    }
    widget.onChanged(jsonEncode(map));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.setting.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.setting.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ..._pairs.asMap().entries.map((entry) {
          final idx = entry.key;
          final pair = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: pair.key,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (k) {
                      _pairs[idx] = MapEntry(k, _pairs[idx].value);
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: pair.value,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _pairs[idx] = MapEntry(_pairs[idx].key, v);
                      _emit();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: _pairs.length > 1
                      ? () {
                          setState(() => _pairs.removeAt(idx));
                          _emit();
                        }
                      : null,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() => _pairs.add(const MapEntry('', '')));
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Pair'),
        ),
        if (widget.setting.help != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.setting.help!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// JSON editor with validation — monospace multiline TextFormField.
class JsonConfigField extends ConfigField {
  const JsonConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      minLines: setting.rows ?? 4,
      maxLines: setting.rows ?? 10,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder ?? '{"key": "value"}',
        helperText: setting.help,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: onChanged,
      validator: (v) {
        final base = validateSettingValue(setting, v);
        if (base != null) return base;
        if (v != null && v.trim().isNotEmpty) {
          try {
            jsonDecode(v);
          } catch (_) {
            return 'JSON inválido';
          }
        }
        return null;
      },
    );
  }
}

/// Code editor — monospace multiline TextFormField.
/// [Setting.format] indicates the language (for future syntax highlighting).
class CodeConfigField extends ConfigField {
  const CodeConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      minLines: setting.rows ?? 6,
      maxLines: setting.rows ?? 20,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder,
        helperText:
            setting.help ?? (setting.format != null ? 'Language: ${setting.format}' : null),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: onChanged,
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

/// Emoji icon picker — grid popup of common emojis.
class IconConfigField extends ConfigField {
  const IconConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _IconField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _IconField extends StatefulWidget {
  const _IconField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_IconField> createState() => _IconFieldState();
}

class _IconFieldState extends State<_IconField> {
  late String _icon;

  static const _commonEmojis = [
    // Faces
    '😀', '😎', '🤔', '😴', '🤖', '👻', '💀', '🎃',
    // Symbols
    '⚡', '🔥', '💧', '❄️', '☀️', '🌙', '⭐', '🌈',
    // Objects
    '💻', '📱', '🔧', '⚙️', '📊', '📈', '📉', '🗂️',
    // Status
    '✅', '❌', '⚠️', '🔴', '🟡', '🟢', '🔵', '⬜',
    // Nature
    '🌍', '🌲', '🌊', '🏔️', '🌸', '🍀', '🌻', '🍄',
    // Transport
    '🚀', '✈️', '🚗', '🚢', '🏠', '🏢', '🏭', '🏗️',
    // Time
    '⏰', '📅', '⏱️', '🕐', '⌛', '📆', '🗓️', '⏳',
    // Misc
    '🎵', '🎨', '📝', '📌', '🔑', '🔒', '💡', '🔔',
    // Actions
    '👍', '👎', '👆', '👇', '✋', '👋', '🤝', '💪',
    // Food
    '☕', '🍕', '🎂', '🍎', '🥤', '🍺', '🧊', '🌶️',
  ];

  @override
  void initState() {
    super.initState();
    _icon = widget.value ?? widget.setting.defaultValue ?? '';
  }

  Future<void> _showPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(widget.setting.label.isNotEmpty
              ? widget.setting.label
              : 'Choose Icon'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: _commonEmojis.length,
              itemBuilder: (_, i) {
                return InkWell(
                  onTap: () => Navigator.pop(ctx, _commonEmojis[i]),
                  child: Center(
                    child: Text(
                      _commonEmojis[i],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() => _icon = selected);
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.setting.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.setting.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        InkWell(
          onTap: _showPicker,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _icon.isEmpty ? '?' : _icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (widget.setting.help != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.setting.help!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

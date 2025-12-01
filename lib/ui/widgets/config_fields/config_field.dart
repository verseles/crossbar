import 'package:flutter/material.dart';

import '../../../models/plugin_config.dart';

abstract class ConfigField extends StatelessWidget {
  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  const ConfigField({
    super.key,
    required this.setting,
    this.value,
    required this.onChanged,
  });

  factory ConfigField.fromSetting({
    Key? key,
    required Setting setting,
    String? value,
    required ValueChanged<String> onChanged,
  }) {
    switch (setting.type) {
      case 'text':
        return TextConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'password':
        return PasswordConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'number':
        return NumberConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'select':
        return SelectConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'checkbox':
        return CheckboxConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'color':
        return ColorConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'file':
        return FileConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      default:
        return TextConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
    }
  }
}

class TextConfigField extends ConfigField {
  const TextConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder,
        helperText: setting.help,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class PasswordConfigField extends ConfigField {
  const PasswordConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PasswordField(
      initialValue: value ?? setting.defaultValue,
      label: setting.label,
      placeholder: setting.placeholder,
      help: setting.help,
      onChanged: onChanged,
    );
  }
}

class _PasswordField extends StatefulWidget {
  final String? initialValue;
  final String label;
  final String? placeholder;
  final String? help;
  final ValueChanged<String> onChanged;

  const _PasswordField({
    this.initialValue,
    required this.label,
    this.placeholder,
    this.help,
    required this.onChanged,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: widget.initialValue,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        helperText: widget.help,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class NumberConfigField extends ConfigField {
  const NumberConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder,
        helperText: setting.help,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class SelectConfigField extends ConfigField {
  const SelectConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = setting.options ?? {};
    final entries = options.entries.toList();

    return DropdownButtonFormField<String>(
      value: value ?? setting.defaultValue,
      decoration: InputDecoration(
        labelText: setting.label,
        helperText: setting.help,
        border: const OutlineInputBorder(),
      ),
      items: entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value.toString()),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}

class CheckboxConfigField extends ConfigField {
  const CheckboxConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = (value ?? setting.defaultValue ?? 'false') == 'true';

    return CheckboxListTile(
      title: Text(setting.label),
      subtitle: setting.help != null ? Text(setting.help!) : null,
      value: isChecked,
      onChanged: (newValue) {
        onChanged(newValue == true ? 'true' : 'false');
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class ColorConfigField extends ConfigField {
  const ColorConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorValue = value ?? setting.defaultValue ?? '#000000';
    final color = _parseColor(colorValue);

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: colorValue,
            decoration: InputDecoration(
              labelText: setting.label,
              helperText: setting.help,
              border: const OutlineInputBorder(),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      var hexColor = hex.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
}

class FileConfigField extends ConfigField {
  const FileConfigField({
    super.key,
    required super.setting,
    super.value,
    required super.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: value ?? setting.defaultValue,
            readOnly: true,
            decoration: InputDecoration(
              labelText: setting.label,
              helperText: setting.help,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement file picker
          },
          icon: const Icon(Icons.folder_open),
          label: const Text('Browse'),
        ),
      ],
    );
  }
}

class ConfigFormBuilder extends StatelessWidget {
  final List<Setting> settings;
  final Map<String, String> values;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;
  final int columns;

  const ConfigFormBuilder({
    super.key,
    required this.settings,
    required this.values,
    required this.onFieldChanged,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = constraints.maxWidth > 600 ? columns : 1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: settings.map((setting) {
            final width = setting.width;
            final fieldWidth = width != null
                ? constraints.maxWidth * (width / 100)
                : (constraints.maxWidth - 16 * (effectiveColumns - 1)) /
                    effectiveColumns;

            return SizedBox(
              width: fieldWidth.clamp(200.0, constraints.maxWidth),
              child: ConfigField.fromSetting(
                setting: setting,
                value: values[setting.key],
                onChanged: (newValue) {
                  onFieldChanged(MapEntry(setting.key, newValue));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

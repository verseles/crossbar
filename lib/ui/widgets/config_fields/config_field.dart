import 'dart:convert';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'complex_fields.dart';
import 'container_fields.dart';
import 'layout_fields.dart';
import 'selection_fields.dart';

abstract class ConfigField extends StatelessWidget {
  const ConfigField({
    required this.setting,
    required this.onChanged,
    super.key,
    this.value,
  });

  factory ConfigField.fromSetting({
    required Setting setting,
    required ValueChanged<String> onChanged,
    Key? key,
    String? value,
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
      case 'path':
        return PathConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'url':
        return UrlConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'textarea':
        return TextAreaConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'slider':
        return SliderConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'date':
        return DateConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'time':
        return TimeConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'datetime':
        return DateTimeConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      // Layout types
      case 'hidden':
        return HiddenConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'switch':
        return SwitchConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'separator':
        return SeparatorConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'divider':
        return DividerConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'section':
        return SectionConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'info':
        return InfoConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      // Selection types
      case 'radio':
        return RadioConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'range':
        return RangeConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'multiselect':
        return MultiselectConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'tags':
        return TagsConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      // Complex types
      case 'image':
        return ImageConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'keyvalue':
        return KeyValueConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'json':
        return JsonConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'code':
        return CodeConfigField(
          key: key,
          setting: setting,
          value: value,
          onChanged: onChanged,
        );
      case 'icon':
        return IconConfigField(
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

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;
}

/// Types that render no data and should be skipped in validation and defaults.
const layoutOnlyTypes = {'separator', 'divider', 'section', 'info'};

/// Types that should span full width in the form builder.
const fullWidthTypes = {
  'separator',
  'divider',
  'section',
  'info',
  'collapsible',
  'tabs',
};

String? validateSettingValue(Setting setting, String? rawValue) {
  // Layout-only types never produce validation errors.
  if (layoutOnlyTypes.contains(setting.type)) return null;

  // Container types have no direct value.
  if (setting.type == 'collapsible' || setting.type == 'tabs') return null;

  final value = (rawValue ?? '').trim();

  if (setting.required && value.isEmpty) {
    return 'Campo obrigatório';
  }
  if (value.isEmpty) {
    return null;
  }

  switch (setting.type) {
    case 'number':
    case 'slider':
      final parsed = double.tryParse(value);
      if (parsed == null) {
        return 'Informe um número válido';
      }
      if (setting.min != null && parsed < setting.min!) {
        return 'Valor mínimo: ${_formatNumber(setting.min!)}';
      }
      if (setting.max != null && parsed > setting.max!) {
        return 'Valor máximo: ${_formatNumber(setting.max!)}';
      }
      break;
    case 'url':
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return 'URL inválida';
      }
      break;
    case 'date':
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        return 'Formato esperado: YYYY-MM-DD';
      }
      if (DateTime.tryParse(value) == null) {
        return 'Data inválida';
      }
      break;
    case 'time':
      if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
        return 'Formato esperado: HH:mm';
      }
      final parsed = _parseTime(value);
      if (parsed == null) {
        return 'Hora inválida';
      }
      break;
    case 'datetime':
      if (!RegExp(r'([+-]\d{2}:\d{2}|Z)$').hasMatch(value)) {
        return 'Use timezone explícita (ex: +00:00)';
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        return 'Datetime inválido';
      }
      break;
    case 'range':
      final parts = value.split(',');
      if (parts.length != 2) {
        return 'Formato esperado: min,max';
      }
      final start = double.tryParse(parts[0].trim());
      final end = double.tryParse(parts[1].trim());
      if (start == null || end == null) {
        return 'Valores numéricos inválidos';
      }
      if (start > end) {
        return 'Mínimo deve ser menor que máximo';
      }
      if (setting.min != null && start < setting.min!) {
        return 'Valor mínimo: ${_formatNumber(setting.min!)}';
      }
      if (setting.max != null && end > setting.max!) {
        return 'Valor máximo: ${_formatNumber(setting.max!)}';
      }
      break;
    case 'json':
      try {
        jsonDecode(value);
      } catch (_) {
        return 'JSON inválido';
      }
      break;
    default:
      break;
  }

  if (setting.pattern != null && setting.pattern!.isNotEmpty) {
    final regex = RegExp(setting.pattern!);
    if (!regex.hasMatch(value)) {
      return 'Formato inválido';
    }
  }

  return null;
}

class TextConfigField extends ConfigField {
  const TextConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
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
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class UrlConfigField extends ConfigField {
  const UrlConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder ?? 'https://example.com',
        helperText: setting.help,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class PasswordConfigField extends ConfigField {
  const PasswordConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _PasswordField(
      initialValue: value ?? setting.defaultValue,
      label: setting.label,
      placeholder: setting.placeholder,
      help: setting.help,
      onChanged: onChanged,
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.label,
    required this.onChanged,
    required this.validator,
    this.initialValue,
    this.placeholder,
    this.help,
  });

  final String? initialValue;
  final String label;
  final String? placeholder;
  final String? help;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

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
      validator: widget.validator,
    );
  }
}

class NumberConfigField extends ConfigField {
  const NumberConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]')),
      ],
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder,
        helperText: setting.help,
        border: const OutlineInputBorder(),
        suffixText: setting.unit,
      ),
      onChanged: onChanged,
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class SelectConfigField extends ConfigField {
  const SelectConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final options = setting.options ?? [];
    final initialValue = value ?? setting.defaultValue;

    if (options.isEmpty) {
      return TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: setting.label,
          helperText: setting.help ?? 'Sem opções configuradas',
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: options.any((o) => o.value == initialValue)
          ? initialValue
          : null,
      decoration: InputDecoration(
        labelText: setting.label,
        helperText: setting.help,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      validator: (selected) {
        if (setting.required && (selected == null || selected.isEmpty)) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }
}

class CheckboxConfigField extends ConfigField {
  const CheckboxConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = (value ?? setting.defaultValue ?? 'false') == 'true';

    return CheckboxListTile(
      title: Text(setting.label),
      subtitle: setting.help != null ? Text(setting.help!) : null,
      value: isChecked,
      onChanged: (newValue) {
        onChanged((newValue ?? false) ? 'true' : 'false');
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class ColorConfigField extends ConfigField {
  const ColorConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorValue = value ?? setting.defaultValue ?? '#000000';
    final color = _parseColor(colorValue);

    return TextFormField(
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
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class TextAreaConfigField extends ConfigField {
  const TextAreaConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value ?? setting.defaultValue,
      minLines: setting.rows ?? 3,
      maxLines: setting.rows ?? 6,
      decoration: InputDecoration(
        labelText: setting.label,
        hintText: setting.placeholder,
        helperText: setting.help,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: onChanged,
      validator: (v) => validateSettingValue(setting, v),
    );
  }
}

class FileConfigField extends ConfigField {
  const FileConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _PathLikeField(
      setting: setting,
      value: value,
      onChanged: onChanged,
      allowDirectory: false,
      readOnly: true,
      browseLabel: 'Arquivo',
    );
  }
}

class PathConfigField extends ConfigField {
  const PathConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _PathLikeField(
      setting: setting,
      value: value,
      onChanged: onChanged,
      allowDirectory: true,
      readOnly: false,
      browseLabel: 'Caminho',
    );
  }
}

class _PathLikeField extends StatefulWidget {
  const _PathLikeField({
    required this.setting,
    required this.onChanged,
    required this.allowDirectory,
    required this.readOnly,
    required this.browseLabel,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool allowDirectory;
  final bool readOnly;
  final String browseLabel;

  @override
  State<_PathLikeField> createState() => _PathLikeFieldState();
}

class _PathLikeFieldState extends State<_PathLikeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value ?? widget.setting.defaultValue ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PathLikeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value ?? widget.setting.defaultValue ?? '';
    if (_controller.text != nextValue &&
        oldWidget.value != widget.value &&
        (widget.value ?? '').isNotEmpty) {
      _controller.text = nextValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final accepts = (widget.setting.accept ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('.') ? e.substring(1) : e)
        .toList();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: accepts.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: accepts.isEmpty ? null : accepts,
    );

    if (result != null && result.files.single.path != null) {
      final selected = result.files.single.path!;
      _controller.text = selected;
      widget.onChanged(selected);
    }
  }

  Future<void> _pickDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null && directory.isNotEmpty) {
      _controller.text = directory;
      widget.onChanged(directory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            labelText: widget.setting.label,
            helperText: widget.setting.help,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onChanged,
          validator: (v) => validateSettingValue(widget.setting, v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(widget.browseLabel),
            ),
            if (widget.allowDirectory)
              OutlinedButton.icon(
                onPressed: _pickDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('Pasta'),
              ),
          ],
        ),
      ],
    );
  }
}

class SliderConfigField extends ConfigField {
  const SliderConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _SliderField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _SliderField extends StatefulWidget {
  const _SliderField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_SliderField> createState() => _SliderFieldState();
}

class _SliderFieldState extends State<_SliderField> {
  late double _value;
  late double _min;
  late double _max;
  late double _step;

  @override
  void initState() {
    super.initState();
    _min = widget.setting.min ?? 0;
    _max = widget.setting.max ?? 100;
    if (_max <= _min) {
      _max = _min + 1;
    }
    _step = widget.setting.step ?? 1;
    if (_step <= 0) {
      _step = 1;
    }

    final parsed =
        double.tryParse(widget.value ?? '') ??
        double.tryParse(widget.setting.defaultValue ?? '') ??
        _min;
    _value = parsed.clamp(_min, _max);
  }

  @override
  Widget build(BuildContext context) {
    final divisions = ((_max - _min) / _step).round();
    final effectiveDivisions = divisions > 0 && divisions <= 1000
        ? divisions
        : null;
    final display = _formatNumber(_value);
    final unit = widget.setting.unit ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.setting.label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text('$display$unit'),
          ],
        ),
        Slider(
          value: _value,
          min: _min,
          max: _max,
          divisions: effectiveDivisions,
          label: '$display$unit',
          onChanged: (next) {
            setState(() {
              _value = next;
            });
            widget.onChanged(_formatNumber(next));
          },
        ),
        if (widget.setting.help != null)
          Text(
            widget.setting.help!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
      ],
    );
  }
}

class DateConfigField extends ConfigField {
  const DateConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _DateField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _DateField extends StatefulWidget {
  const _DateField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value ?? widget.setting.defaultValue ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_controller.text) ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(selected);
      _controller.text = formatted;
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.setting.label,
        hintText: widget.setting.placeholder ?? 'YYYY-MM-DD',
        helperText: widget.setting.help,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _pickDate,
        ),
      ),
      onTap: _pickDate,
      validator: (v) => validateSettingValue(widget.setting, v),
    );
  }
}

class TimeConfigField extends ConfigField {
  const TimeConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _TimeField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value ?? widget.setting.defaultValue ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initial = _parseTime(_controller.text) ?? TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected != null) {
      final formatted =
          '${selected.hour.toString().padLeft(2, '0')}:'
          '${selected.minute.toString().padLeft(2, '0')}';
      _controller.text = formatted;
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.setting.label,
        hintText: widget.setting.placeholder ?? 'HH:mm',
        helperText: widget.setting.help,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: _pickTime,
        ),
      ),
      onTap: _pickTime,
      validator: (v) => validateSettingValue(widget.setting, v),
    );
  }
}

class DateTimeConfigField extends ConfigField {
  const DateTimeConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _DateTimeField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _DateTimeField extends StatefulWidget {
  const _DateTimeField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<_DateTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value ?? widget.setting.defaultValue ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_controller.text)?.toLocal() ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: parsed.hour, minute: parsed.minute),
    );
    if (selectedTime == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final localDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
      0,
    );
    final formatted = _toRfc3339WithOffset(localDateTime);
    _controller.text = formatted;
    widget.onChanged(formatted);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.setting.label,
        hintText: widget.setting.placeholder ?? 'YYYY-MM-DDTHH:mm:ss+00:00',
        helperText: widget.setting.help,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.event),
          onPressed: _pickDateTime,
        ),
      ),
      onTap: _pickDateTime,
      validator: (v) => validateSettingValue(widget.setting, v),
    );
  }
}

class ConfigFormBuilder extends StatelessWidget {
  const ConfigFormBuilder({
    required this.settings,
    required this.values,
    required this.onFieldChanged,
    super.key,
    this.columns = 2,
  });

  final List<Setting> settings;
  final Map<String, String> values;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = constraints.maxWidth > 600 ? columns : 1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: settings.map((setting) {
            // Container types are rendered directly, not via ConfigField.
            if (setting.type == 'collapsible') {
              return SizedBox(
                width: constraints.maxWidth,
                child: CollapsibleConfigField(
                  setting: setting,
                  values: values,
                  onFieldChanged: onFieldChanged,
                ),
              );
            }
            if (setting.type == 'tabs') {
              return SizedBox(
                width: constraints.maxWidth,
                child: TabsConfigField(
                  setting: setting,
                  values: values,
                  onFieldChanged: onFieldChanged,
                ),
              );
            }

            // Full-width types span the entire row.
            if (fullWidthTypes.contains(setting.type)) {
              return SizedBox(
                width: constraints.maxWidth,
                child: ConfigField.fromSetting(
                  setting: setting,
                  value: values[setting.key],
                  onChanged: (newValue) {
                    onFieldChanged(MapEntry(setting.key, newValue));
                  },
                ),
              );
            }

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

String _formatNumber(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.000001) {
    return rounded.toInt().toString();
  }
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
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

TimeOfDay? _parseTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _toRfc3339WithOffset(DateTime local) {
  final base = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(local);
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final totalMinutes = offset.inMinutes.abs();
  final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final mm = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$base$sign$hh:$mm';
}

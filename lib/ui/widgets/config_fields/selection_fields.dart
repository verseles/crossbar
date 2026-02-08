import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';

import 'config_field.dart';

/// Radio button group — uses [Setting.options].
class RadioConfigField extends ConfigField {
  const RadioConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _RadioField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _RadioField extends StatefulWidget {
  const _RadioField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_RadioField> createState() => _RadioFieldState();
}

class _RadioFieldState extends State<_RadioField> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value ?? widget.setting.defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.setting.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.setting.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.setting.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        RadioGroup<String>(
          groupValue: _selected ?? '',
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() => _selected = newValue);
              widget.onChanged(newValue);
            }
          },
          child: Column(
            children: options.map((option) {
              return RadioListTile<String>(
                title: Text(option.label),
                value: option.value,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
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

/// Range slider with two thumbs — stores value as `"min,max"`.
class RangeConfigField extends ConfigField {
  const RangeConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _RangeField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _RangeField extends StatefulWidget {
  const _RangeField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_RangeField> createState() => _RangeFieldState();
}

class _RangeFieldState extends State<_RangeField> {
  late double _min;
  late double _max;
  late double _step;
  late RangeValues _range;

  @override
  void initState() {
    super.initState();
    _min = widget.setting.min ?? 0;
    _max = widget.setting.max ?? 100;
    if (_max <= _min) _max = _min + 1;
    _step = widget.setting.step ?? 1;
    if (_step <= 0) _step = 1;

    final parts = (widget.value ?? widget.setting.defaultValue ?? '')
        .split(',')
        .map((s) => double.tryParse(s.trim()))
        .toList();

    final start = (parts.isNotEmpty && parts[0] != null)
        ? parts[0]!.clamp(_min, _max)
        : _min;
    final end = (parts.length > 1 && parts[1] != null)
        ? parts[1]!.clamp(_min, _max)
        : _max;

    _range = RangeValues(start, end > start ? end : start);
  }

  @override
  Widget build(BuildContext context) {
    final divisions = ((_max - _min) / _step).round();
    final effectiveDivisions =
        divisions > 0 && divisions <= 1000 ? divisions : null;
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
            Text(
              '${_formatNumber(_range.start)}$unit - ${_formatNumber(_range.end)}$unit',
            ),
          ],
        ),
        RangeSlider(
          values: _range,
          min: _min,
          max: _max,
          divisions: effectiveDivisions,
          labels: RangeLabels(
            '${_formatNumber(_range.start)}$unit',
            '${_formatNumber(_range.end)}$unit',
          ),
          onChanged: (next) {
            setState(() => _range = next);
            widget.onChanged(
              '${_formatNumber(next.start)},${_formatNumber(next.end)}',
            );
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

/// Multi-select using [FilterChip]s — stores value as comma-separated.
class MultiselectConfigField extends ConfigField {
  const MultiselectConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _MultiselectField(
      setting: setting,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _MultiselectField extends StatefulWidget {
  const _MultiselectField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_MultiselectField> createState() => _MultiselectFieldState();
}

class _MultiselectFieldState extends State<_MultiselectField> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final raw = widget.value ?? widget.setting.defaultValue ?? '';
    _selected = raw.isEmpty
        ? <String>{}
        : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.setting.options ?? [];

    return FormField<Set<String>>(
      initialValue: _selected,
      validator: (_) {
        if (widget.setting.required && _selected.isEmpty) {
          return 'Selecione ao menos uma opção';
        }
        return null;
      },
      builder: (state) {
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((option) {
                final selected = _selected.contains(option.value);
                return FilterChip(
                  label: Text(option.label),
                  selected: selected,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selected.add(option.value);
                      } else {
                        _selected.remove(option.value);
                      }
                    });
                    widget.onChanged(_selected.join(','));
                    state.didChange(_selected);
                  },
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
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
      },
    );
  }
}

/// Free-form tags with optional suggestions from [Setting.options].
/// Max tags controlled by [Setting.max].
class TagsConfigField extends ConfigField {
  const TagsConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return _TagsField(setting: setting, value: value, onChanged: onChanged);
  }
}

class _TagsField extends StatefulWidget {
  const _TagsField({
    required this.setting,
    required this.onChanged,
    this.value,
  });

  final Setting setting;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<_TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<_TagsField> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final raw = widget.value ?? widget.setting.defaultValue ?? '';
    _tags = raw.isEmpty
        ? <String>[]
        : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;

    final maxTags = widget.setting.max?.toInt();
    if (maxTags != null && _tags.length >= maxTags) return;

    setState(() => _tags.add(trimmed));
    _controller.clear();
    widget.onChanged(_tags.join(','));
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(_tags.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.setting.options
            ?.map((o) => o.value)
            .where((v) => !_tags.contains(v))
            .toList() ??
        [];
    final maxTags = widget.setting.max?.toInt();
    final atLimit = maxTags != null && _tags.length >= maxTags;

    return FormField<List<String>>(
      initialValue: _tags,
      validator: (_) {
        if (widget.setting.required && _tags.isEmpty) {
          return 'Adicione ao menos uma tag';
        }
        return null;
      },
      builder: (state) {
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ..._tags.map((tag) {
                  return InputChip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  );
                }),
                if (!atLimit)
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add tag...',
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      onSubmitted: _addTag,
                    ),
                  ),
              ],
            ),
            if (suggestions.isNotEmpty && !atLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: suggestions.map((s) {
                    return ActionChip(
                      label: Text(s),
                      onPressed: () => _addTag(s),
                    );
                  }).toList(),
                ),
              ),
            if (maxTags != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_tags.length}/$maxTags',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  state.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
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

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';

import 'config_field.dart';

/// Invisible field that injects [Setting.defaultValue] without rendering UI.
class HiddenConfigField extends ConfigField {
  const HiddenConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Toggle switch — semantically identical to checkbox but uses [SwitchListTile].
class SwitchConfigField extends ConfigField {
  const SwitchConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = (value ?? setting.defaultValue ?? 'false') == 'true';

    return SwitchListTile(
      title: Text(setting.label),
      subtitle: setting.help != null ? Text(setting.help!) : null,
      value: isOn,
      onChanged: (newValue) {
        onChanged(newValue ? 'true' : 'false');
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Simple horizontal divider — no label.
class SeparatorConfigField extends ConfigField {
  const SeparatorConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(),
    );
  }
}

/// Divider with optional text label from [Setting.label].
class DividerConfigField extends ConfigField {
  const DividerConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final label = setting.label;
    if (label.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// Section header with title and optional description.
class SectionConfigField extends ConfigField {
  const SectionConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setting.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (setting.description != null && setting.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                setting.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Info card with icon and color based on [Setting.format]:
/// info (blue), warning (orange), error (red), success (green).
class InfoConfigField extends ConfigField {
  const InfoConfigField({
    required super.setting,
    required super.onChanged,
    super.key,
    super.value,
  });

  @override
  Widget build(BuildContext context) {
    final format = setting.format ?? 'info';
    final (icon, color) = _styleForFormat(format, context);

    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (setting.label.isNotEmpty)
                    Text(
                      setting.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                      ),
                    ),
                  if (setting.description != null &&
                      setting.description!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: setting.label.isNotEmpty ? 4 : 0,
                      ),
                      child: Text(
                        setting.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _styleForFormat(String format, BuildContext context) {
    return switch (format) {
      'warning' => (Icons.warning_amber_rounded, Colors.orange),
      'error' => (Icons.error_outline, Theme.of(context).colorScheme.error),
      'success' => (Icons.check_circle_outline, Colors.green),
      _ => (Icons.info_outline, Colors.blue),
    };
  }
}

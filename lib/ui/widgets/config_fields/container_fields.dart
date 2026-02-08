import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart';

import 'config_field.dart';

/// Collapsible section using [ExpansionTile].
/// Child fields are flattened into the parent values map.
/// Does NOT extend [ConfigField] — treated directly by [ConfigFormBuilder].
class CollapsibleConfigField extends StatelessWidget {
  const CollapsibleConfigField({
    required this.setting,
    required this.values,
    required this.onFieldChanged,
    super.key,
  });

  final Setting setting;
  final Map<String, String> values;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final fields = setting.fields ?? [];

    return ExpansionTile(
      title: Text(setting.label),
      subtitle: setting.description != null && setting.description!.isNotEmpty
          ? Text(
              setting.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            )
          : null,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 16),
      children: [
        ConfigFormBuilder(
          settings: fields,
          values: values,
          onFieldChanged: onFieldChanged,
        ),
      ],
    );
  }
}

/// Tabbed sections using [TabBar] / [TabBarView].
/// Child fields are flattened into the parent values map.
/// Does NOT extend [ConfigField] — treated directly by [ConfigFormBuilder].
class TabsConfigField extends StatefulWidget {
  const TabsConfigField({
    required this.setting,
    required this.values,
    required this.onFieldChanged,
    super.key,
  });

  final Setting setting;
  final Map<String, String> values;
  final ValueChanged<MapEntry<String, String>> onFieldChanged;

  @override
  State<TabsConfigField> createState() => _TabsConfigFieldState();
}

class _TabsConfigFieldState extends State<TabsConfigField>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.setting.tabs?.length ?? 0;
    _tabController = TabController(
      length: tabCount > 0 ? tabCount : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.setting.tabs ?? [];
    if (tabs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.setting.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.setting.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        TabBar(
          controller: _tabController,
          isScrollable: tabs.length > 3,
          tabs: tabs.map((tab) {
            return Tab(text: tab.label);
          }).toList(),
        ),
        SizedBox(
          height: _computeTabHeight(tabs),
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((tab) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16),
                child: ConfigFormBuilder(
                  settings: tab.fields,
                  values: widget.values,
                  onFieldChanged: widget.onFieldChanged,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double _computeTabHeight(List<SettingTab> tabs) {
    // Estimate height: ~80px per field, minimum 200px
    final maxFields = tabs.fold<int>(
      0,
      (max, tab) => tab.fields.length > max ? tab.fields.length : max,
    );
    return (maxFields * 80.0).clamp(200.0, 600.0);
  }
}

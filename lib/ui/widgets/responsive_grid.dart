import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int minItemsPerRow;
  final int maxItemsPerRow;
  final double itemMinWidth;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemsPerRow = 1,
    this.maxItemsPerRow = 4,
    this.itemMinWidth = 200,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemsPerRow = _calculateItemsPerRow(width);
        final itemWidth = (width - (spacing * (itemsPerRow - 1))) / itemsPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  int _calculateItemsPerRow(double width) {
    final possibleItems = (width / itemMinWidth).floor();
    return possibleItems.clamp(minItemsPerRow, maxItemsPerRow);
  }
}

class PluginGrid extends StatelessWidget {
  final List<Widget> plugins;
  final int minColumns;
  final int maxColumns;
  final double minPluginWidth;
  final double spacing;

  const PluginGrid({
    super.key,
    required this.plugins,
    this.minColumns = 1,
    this.maxColumns = 6,
    this.minPluginWidth = 180,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (plugins.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _calculateColumns(width);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 2.5,
          ),
          itemCount: plugins.length,
          itemBuilder: (context, index) => plugins[index],
        );
      },
    );
  }

  int _calculateColumns(double width) {
    final possibleColumns = (width / minPluginWidth).floor();
    return possibleColumns.clamp(minColumns, maxColumns);
  }
}

class AdaptiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget desktop;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const AdaptiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    required this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return mobile ?? tablet ?? desktop;
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return tablet ?? desktop;
        } else {
          return desktop;
        }
      },
    );
  }
}

class FlexibleGridView extends StatelessWidget {
  final List<Widget> children;
  final double minCrossAxisExtent;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const FlexibleGridView({
    super.key,
    required this.children,
    this.minCrossAxisExtent = 200,
    this.mainAxisExtent = 100,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: minCrossAxisExtent * 1.5,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

class BreakpointBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Breakpoint breakpoint) builder;

  const BreakpointBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = Breakpoint.fromWidth(constraints.maxWidth);
        return builder(context, breakpoint);
      },
    );
  }
}

enum Breakpoint {
  xs(0, 576),
  sm(576, 768),
  md(768, 992),
  lg(992, 1200),
  xl(1200, double.infinity);

  final double min;
  final double max;

  const Breakpoint(this.min, this.max);

  static Breakpoint fromWidth(double width) {
    if (width < sm.min) return xs;
    if (width < md.min) return sm;
    if (width < lg.min) return md;
    if (width < xl.min) return lg;
    return xl;
  }

  bool operator <(Breakpoint other) => min < other.min;
  bool operator <=(Breakpoint other) => min <= other.min;
  bool operator >(Breakpoint other) => min > other.min;
  bool operator >=(Breakpoint other) => min >= other.min;
}

import 'package:flutter/material.dart';

import 'animation_constants.dart';

/// Shows a dialog with a smooth scale + fade entrance animation.
///
/// Drop-in replacement for [showDialog] that adds Material 3 style motion:
/// scale 0.92 → 1.0 combined with opacity 0.0 → 1.0.
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = const Color(0x80000000),
  RouteSettings? routeSettings,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: Anim.medium,
    routeSettings: routeSettings,
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Anim.enter,
        reverseCurve: Anim.exit,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

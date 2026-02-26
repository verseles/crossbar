import 'package:flutter/material.dart';

/// Centralized animation constants following Material 3 Motion guidelines.
///
/// Durations are kept short (<400ms) to feel responsive without blocking
/// interaction. Curves use the M3 Easing tokens for consistent feel.
abstract final class Anim {
  // -- Durations --

  /// Ultra-fast transitions: toggles, icon swaps (75ms)
  static const micro = Duration(milliseconds: 75);

  /// Fade in/out, state changes (200ms)
  static const short = Duration(milliseconds: 200);

  /// Expand/collapse, tab transitions (300ms)
  static const medium = Duration(milliseconds: 300);

  /// Delay between consecutive list items in staggered animations
  static const staggerInterval = Duration(milliseconds: 50);

  // -- Curves (Material 3 Easing tokens) --

  /// Standard easing for general-purpose transitions
  static final Curve standard = Easing.standard;

  /// Emphasised decelerate — for elements entering the screen
  static final Curve enter = Easing.emphasizedDecelerate;

  /// Emphasised accelerate — for elements leaving the screen
  static final Curve exit = Easing.emphasizedAccelerate;
}

import 'package:flutter/material.dart' show ThemeExtension;
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_motion.tailor.dart';

/// Animation durations. Gate any token-driven animation on
/// `MediaQuery.disableAnimations` so reduced-motion users get no motion.
///
/// Unlike the other bundles, durations are not eased across a theme transition
/// (a cycle length has no meaningful midpoint), so they switch at once.
///
/// ```dart
/// const m = FossMotion.standard;
/// AnimatedOpacity(duration: m.caretBlink, opacity: o, child: child);
/// ```
@TailorMixin(themeGetter: ThemeGetter.none)
class FossMotion extends ThemeExtension<FossMotion>
    with _$FossMotionTailorMixin {
  /// Creates a motion scale. Prefer [standard] unless retheming.
  const FossMotion({
    required this.skeleton,
    required this.caretBlink,
    required this.spinner,
    required this.overlay,
    required this.drawer,
    required this.toast,
    required this.progress,
  });

  /// Skeleton shimmer cycle.
  @override
  final Duration skeleton;

  /// Text caret blink cycle.
  @override
  final Duration caretBlink;

  /// Loading spinner rotation cycle.
  @override
  final Duration spinner;

  /// Enter and exit of a modal overlay (dialog scrim, fade, and scale).
  @override
  final Duration overlay;

  /// Enter and exit slide of an edge drawer, longer than [overlay] to read as
  /// a panel travelling in from the edge.
  @override
  final Duration drawer;

  /// Enter and exit slide of a transient toast.
  @override
  final Duration toast;

  /// Width transition of a determinate progress fill as its value changes.
  @override
  final Duration progress;

  /// The default motion scale.
  static const standard = FossMotion(
    skeleton: Duration(seconds: 2),
    caretBlink: Duration(seconds: 1),
    spinner: Duration(milliseconds: 1000),
    overlay: Duration(milliseconds: 200),
    drawer: Duration(milliseconds: 450),
    toast: Duration(milliseconds: 500),
    progress: Duration(milliseconds: 500),
  );
}

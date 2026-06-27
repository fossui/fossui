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

  /// The default motion scale.
  static const standard = FossMotion(
    skeleton: Duration(seconds: 2),
    caretBlink: Duration(seconds: 1),
    spinner: Duration(milliseconds: 1000),
  );
}

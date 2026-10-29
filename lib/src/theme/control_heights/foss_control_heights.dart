import 'dart:math' as math;

import 'package:flutter/material.dart' show ThemeExtension;
import 'package:fossui/src/theme/lerp_encoders.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_control_heights.tailor.dart';

/// Minimum heights for size-variant controls (select, date picker, time
/// picker, button, toggle, OTP field) in logical pixels. [standard] is the
/// default scale. Text-entry fields sit one step shorter; see
/// `FossFieldHeights`.
///
/// ```dart
/// const h = FossControlHeights.standard;
/// final trigger = SizedBox(height: h.md); // 36 px
/// ```
@TailorMixin(themeGetter: ThemeGetter.none, encoders: [DoubleLerpEncoder()])
class FossControlHeights extends ThemeExtension<FossControlHeights>
    with _$FossControlHeightsTailorMixin {
  /// Creates a control-height scale. Prefer [standard] unless retheming.
  const FossControlHeights({
    required this.sm,
    required this.md,
    required this.lg,
  });

  /// Derives the full scale from a single [seedHeight] (the `md` step). Steps
  /// offset from it (sm -4, md +0, lg +4), each clamped at 0, so
  /// `fromBase(36)` reproduces [standard].
  ///
  /// ```dart
  /// final h = FossControlHeights.fromBase(44); // taller controls app-wide
  /// ```
  factory FossControlHeights.fromBase(double seedHeight) {
    double step(double delta) => math.max(0, seedHeight + delta);
    return FossControlHeights(sm: step(-4), md: step(0), lg: step(4));
  }

  /// Small control height (32 px): compact forms, dense toolbars.
  @override
  final double sm;

  /// Medium control height (36 px): the default control size.
  @override
  final double md;

  /// Large control height (40 px): primary forms, touch-first layouts.
  @override
  final double lg;

  /// The default control-height scale.
  static const standard = FossControlHeights(sm: 32, md: 36, lg: 40);
}

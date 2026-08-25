import 'dart:math' as math;

import 'package:flutter/material.dart' show ThemeExtension;
import 'package:fossui/src/theme/lerp_encoders.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_radii.tailor.dart';

/// Corner radii in logical pixels. [standard] is the default scale; [full] is a
/// pill sentinel, clamped to half the height at the use site.
///
/// ```dart
/// const r = FossRadii.standard;
/// final corners = BorderRadius.circular(r.lg); // 10 px
/// final pill = BorderRadius.circular(FossRadii.full);
/// ```
@TailorMixin(themeGetter: ThemeGetter.none, encoders: [DoubleLerpEncoder()])
class FossRadii extends ThemeExtension<FossRadii> with _$FossRadiiTailorMixin {
  /// Creates a radius scale. Prefer [standard] unless retheming.
  const FossRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xl2,
  });

  /// Derives the full scale from a single [base] (the `lg` step). Steps offset
  /// from it (sm -4, md -2, lg +0, xl +4, xl2 +6), each clamped at 0, so
  /// `fromBase(10)` reproduces [standard].
  ///
  /// ```dart
  /// final r = FossRadii.fromBase(22); // rounder corners across the app
  /// ```
  factory FossRadii.fromBase(double base) {
    double step(double delta) => math.max(0, base + delta);
    return FossRadii(
      sm: step(-4),
      md: step(-2),
      lg: step(0),
      xl: step(4),
      xl2: step(6),
    );
  }

  /// Small corners (6 px): small controls and inline marks.
  @override
  final double sm;

  /// Medium corners (8 px): buttons, inputs.
  @override
  final double md;

  /// Large corners (10 px): cards.
  @override
  final double lg;

  /// Extra-large corners (14 px): sheets and large surfaces.
  @override
  final double xl;

  /// Double extra-large corners (16 px).
  @override
  final double xl2;

  /// Pill sentinel; clamp to half the height at the use site.
  static const full = 9999.0;

  /// The default radius scale.
  static const standard = FossRadii(sm: 6, md: 8, lg: 10, xl: 14, xl2: 16);
}

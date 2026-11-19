import 'dart:math' as math;

import 'package:flutter/material.dart' show ThemeExtension;
import 'package:fossui/src/theme/lerp_encoders.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_field_heights.tailor.dart';

/// Minimum heights for text-entry fields (text field, number field) in logical
/// pixels. [standard] is the default scale. Fields sit one step shorter than
/// other controls; see `FossControlHeights` for buttons, selects, and pickers.
///
/// ```dart
/// const h = FossFieldHeights.standard;
/// final box = SizedBox(height: h.md); // 34 px
/// ```
@TailorMixin(themeGetter: ThemeGetter.none, encoders: [DoubleLerpEncoder()])
class FossFieldHeights extends ThemeExtension<FossFieldHeights>
    with _$FossFieldHeightsTailorMixin {
  /// Creates a field-height scale. Prefer [standard] unless retheming.
  const FossFieldHeights({
    required this.sm,
    required this.md,
    required this.lg,
  });

  /// Derives the full scale from a single [seedHeight] (the `md` step). Steps
  /// offset from it (sm -4, md +0, lg +4), each clamped at 0, so
  /// `fromBase(34)` reproduces [standard].
  ///
  /// ```dart
  /// final h = FossFieldHeights.fromBase(40); // taller fields across the app
  /// ```
  factory FossFieldHeights.fromBase(double seedHeight) {
    double step(double delta) => math.max(0, seedHeight + delta);
    return FossFieldHeights(sm: step(-4), md: step(0), lg: step(4));
  }

  /// Small field height (30 px): compact forms, dense toolbars.
  @override
  final double sm;

  /// Medium field height (34 px): the default field size.
  @override
  final double md;

  /// Large field height (38 px): primary forms, touch-first layouts.
  @override
  final double lg;

  /// The default field-height scale.
  static const standard = FossFieldHeights(sm: 30, md: 34, lg: 38);
}

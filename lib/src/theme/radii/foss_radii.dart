import 'package:flutter/material.dart' show ThemeExtension;
import 'package:foss_ui/src/theme/lerp_encoders.dart';
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

  /// Small corners (6 px): controls, chips.
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

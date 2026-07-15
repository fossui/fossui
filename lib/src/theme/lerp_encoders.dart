import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

/// Interpolates `double` token values so theme transitions ease the scale
/// instead of snapping at the midpoint, which is the generator's default for
/// `double`. Used by the radius and spacing bundles.
///
/// ```dart
/// @TailorMixin(encoders: [DoubleLerpEncoder()])
/// class FossRadii extends ThemeExtension<FossRadii> { /* double fields */ }
/// ```
class DoubleLerpEncoder extends ThemeEncoder<double> {
  /// Creates the encoder.
  const DoubleLerpEncoder();

  @override
  double lerp(double a, double b, double t) => lerpDouble(a, b, t) ?? b;
}

/// Interpolates a `List<BoxShadow>` so elevation eases on theme transitions
/// instead of snapping. Used by the shadow bundle.
///
/// ```dart
/// @TailorMixin(encoders: [BoxShadowListLerpEncoder()])
/// class FossShadows extends ThemeExtension<FossShadows> { /* shadow lists */ }
/// ```
class BoxShadowListLerpEncoder extends ThemeEncoder<List<BoxShadow>> {
  /// Creates the encoder.
  const BoxShadowListLerpEncoder();

  @override
  List<BoxShadow> lerp(List<BoxShadow> a, List<BoxShadow> b, double t) =>
      BoxShadow.lerpList(a, b, t) ?? [];
}

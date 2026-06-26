import 'dart:ui' show lerpDouble;

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
  double lerp(double a, double b, double t) => lerpDouble(a, b, t)!;
}

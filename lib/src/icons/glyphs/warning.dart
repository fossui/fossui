part of '../foss_glyph.dart';

/// A warning mark: a triangle around an exclamation.
class WarningGlyph extends FossGlyph {
  /// Creates a warning glyph in [color].
  const WarningGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..path(const [(0.5, 0.16), (0.9, 0.82), (0.1, 0.82)], close: true)
    ..line(0.5, 0.42, 0.5, 0.6)
    ..dot(0.5, 0.71);
}

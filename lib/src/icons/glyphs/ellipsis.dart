part of '../foss_glyph.dart';

/// Three dots on the centre line, standing in for omitted items.
class EllipsisGlyph extends FossGlyph {
  /// Creates an ellipsis glyph in [color].
  const EllipsisGlyph(super.color);

  // The dots are filled, so the stroke weight only sets the pen's baseline.
  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..dot(0.21, 0.5)
    ..dot(0.5, 0.5)
    ..dot(0.79, 0.5);
}

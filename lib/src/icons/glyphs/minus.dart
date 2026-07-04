part of '../foss_glyph.dart';

/// A horizontal bar, the indeterminate mark. Authored on a 24-unit grid.
class MinusGlyph extends FossGlyph {
  /// Creates a minus glyph in [color].
  const MinusGlyph(super.color);

  @override
  double get _stroke => 0.125;

  @override
  void _draw(_Pen pen) => pen.line(5.252 / 24, 0.5, 18.748 / 24, 0.5);
}

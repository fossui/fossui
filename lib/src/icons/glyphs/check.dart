part of '../foss_glyph.dart';

/// A check mark, the canonical selection tick. Authored on a 24-unit grid.
class CheckGlyph extends FossGlyph {
  /// Creates a check glyph in [color].
  const CheckGlyph(super.color);

  @override
  double get _stroke => 0.125;

  @override
  void _draw(_Pen pen) => pen.path(const [
    (5.252 / 24, 12.7 / 24),
    (10.2 / 24, 18.63 / 24),
    (18.748 / 24, 5.37 / 24),
  ]);
}

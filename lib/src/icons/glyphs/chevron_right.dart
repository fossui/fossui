part of '../foss_glyph.dart';

/// A chevron pointing right, a step forward through a sequence.
class ChevronRightGlyph extends FossGlyph {
  /// Creates a chevron glyph in [color].
  const ChevronRightGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) =>
      pen.path(const [(0.38, 0.28), (0.62, 0.5), (0.38, 0.72)]);
}

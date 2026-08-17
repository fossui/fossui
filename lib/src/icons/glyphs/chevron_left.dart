part of '../foss_glyph.dart';

/// A chevron pointing left, a step back through a sequence.
class ChevronLeftGlyph extends FossGlyph {
  /// Creates a chevron glyph in [color].
  const ChevronLeftGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) =>
      pen.path(const [(0.62, 0.28), (0.38, 0.5), (0.62, 0.72)]);
}

part of '../foss_glyph.dart';

/// A success mark: a circled check.
class SuccessGlyph extends FossGlyph {
  /// Creates a success glyph in [color].
  const SuccessGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..ring()
    ..path(const [(0.32, 0.52), (0.45, 0.65), (0.69, 0.37)]);
}

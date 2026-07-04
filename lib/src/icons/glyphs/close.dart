part of '../foss_glyph.dart';

/// An X, the canonical close and clear mark.
class CloseGlyph extends FossGlyph {
  /// Creates a close glyph in [color].
  const CloseGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..line(0.28, 0.28, 0.72, 0.72)
    ..line(0.72, 0.28, 0.28, 0.72);
}

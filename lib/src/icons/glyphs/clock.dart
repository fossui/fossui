part of '../foss_glyph.dart';

/// A clock face: a ring with the hour and minute hands reading half past ten.
class ClockGlyph extends FossGlyph {
  /// Creates a clock glyph in [color].
  const ClockGlyph(super.color);

  @override
  double get _stroke => 0.08;

  @override
  void _draw(_Pen pen) => pen
    ..ring()
    ..path(const [(0.5, 0.26), (0.5, 0.5), (0.68, 0.6)]);
}

part of '../foss_glyph.dart';

/// An informational mark: a circled dot and stem.
class InfoGlyph extends FossGlyph {
  /// Creates an info glyph in [color].
  const InfoGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..ring()
    ..dot(0.5, 0.32)
    ..line(0.5, 0.46, 0.5, 0.7);
}

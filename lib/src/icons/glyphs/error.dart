part of '../foss_glyph.dart';

/// An error mark: a circled exclamation.
class ErrorGlyph extends FossGlyph {
  /// Creates an error glyph in [color].
  const ErrorGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..ring()
    ..line(0.5, 0.3, 0.5, 0.55)
    ..dot(0.5, 0.68);
}

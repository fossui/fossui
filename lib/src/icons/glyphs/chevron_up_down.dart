part of '../foss_glyph.dart';

/// A stacked up and down chevron, a trigger's open affordance.
class ChevronUpDownGlyph extends FossGlyph {
  /// Creates a chevron glyph in [color].
  const ChevronUpDownGlyph(super.color);

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) => pen
    ..path(const [(0.3, 0.44), (0.5, 0.3), (0.7, 0.44)])
    ..path(const [(0.3, 0.56), (0.5, 0.7), (0.7, 0.56)]);
}

part of '../foss_glyph.dart';

/// A five-point star, the rating mark. Authored on a 24-unit grid.
///
/// One shape serves both layers of a rating: [filled] paints it solid, the
/// default strokes it as an outline. Sharing the vertices means a partially
/// filled star cannot drift into two differently shaped halves.
class StarGlyph extends FossGlyph {
  /// Creates a star glyph in [color], solid when [filled].
  const StarGlyph(super.color, {this.filled = false});

  /// Whether the star is painted solid rather than stroked as an outline.
  final bool filled;

  // The ten vertices of a regular five-point star about the grid center, outer
  // radius 11 and inner radius 4.2, the first point at the top. The inner
  // radius is the one that keeps each of the ten edges straight.
  static const List<(double, double)> _points = [
    (12 / 24, 1 / 24),
    (14.47 / 24, 8.6 / 24),
    (22.46 / 24, 8.6 / 24),
    (15.99 / 24, 13.3 / 24),
    (18.47 / 24, 20.9 / 24),
    (12 / 24, 16.2 / 24),
    (5.53 / 24, 20.9 / 24),
    (8.01 / 24, 13.3 / 24),
    (1.54 / 24, 8.6 / 24),
    (9.53 / 24, 8.6 / 24),
  ];

  @override
  double get _stroke => 0.09;

  @override
  void _draw(_Pen pen) =>
      filled ? pen.shape(_points) : pen.path(_points, close: true);

  @override
  bool shouldRepaint(covariant StarGlyph old) =>
      old.color != color || old.filled != filled;
}

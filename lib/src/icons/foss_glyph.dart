import 'package:flutter/widgets.dart';

part 'glyphs/check.dart';
part 'glyphs/chevron_up_down.dart';
part 'glyphs/close.dart';
part 'glyphs/error.dart';
part 'glyphs/info.dart';
part 'glyphs/minus.dart';
part 'glyphs/success.dart';
part 'glyphs/warning.dart';

/// Base for the built-in glyphs the components paint when no icon is supplied.
///
/// The package takes no icon dependency, so the default marks (a close cross, a
/// status symbol, a selection check) are stroked in code. Each glyph is a small
/// subclass describing only its shape and weight; the scaffolding here maps a
/// unit box to the paint size once.
abstract class FossGlyph extends CustomPainter {
  /// Creates a glyph painted in [color].
  const FossGlyph(this.color);

  /// The stroke and fill color.
  final Color color;

  // The stroke weight as a fraction of the shortest side.
  double get _stroke;

  // Strokes the glyph in a unit box, top-left (0, 0) to bottom-right (1, 1).
  void _draw(_Pen pen);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    _draw(_Pen(canvas, s, color, s * _stroke));
  }

  @override
  bool shouldRepaint(covariant FossGlyph old) => old.color != color;
}

/// Unit-box drawing helper shared by the glyphs. Holds the scale, the stroke
/// paint, and a fill, and exposes the primitives each glyph is built from, so
/// the paint setup is written once rather than copied per glyph.
class _Pen {
  _Pen(this.canvas, this.s, Color color, double strokeWidth)
    : _stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      _fill = Paint()..color = color;

  final Canvas canvas;
  final double s;
  final Paint _stroke;
  final Paint _fill;

  Offset _p(double x, double y) => Offset(x * s, y * s);

  /// A stroked segment between two unit-box points.
  void line(double x1, double y1, double x2, double y2) =>
      canvas.drawLine(_p(x1, y1), _p(x2, y2), _stroke);

  /// A stroked polyline through [points], optionally closed into a loop.
  void path(List<(double, double)> points, {bool close = false}) {
    final (fx, fy) = points.first;
    final path = Path()..moveTo(_p(fx, fy).dx, _p(fx, fy).dy);
    for (final (x, y) in points.skip(1)) {
      path.lineTo(_p(x, y).dx, _p(x, y).dy);
    }
    if (close) path.close();
    canvas.drawPath(path, _stroke);
  }

  /// A small filled dot at a unit-box point.
  void dot(double x, double y) => canvas.drawCircle(_p(x, y), s * 0.055, _fill);

  /// A stroked circle centered in the box.
  void ring() => canvas.drawCircle(_p(0.5, 0.5), s * 0.42, _stroke);
}

/// Paints a [FossGlyph] at [size] in the glyph's own color. A lightweight
/// stand-in for an icon font, used only for the components' default marks.
///
/// Pass a [semanticLabel] when the glyph carries meaning (a status); leave it
/// null for decorative marks, which are then excluded from the semantics tree.
/// With no [size] the glyph fills the parent's constraints.
class FossGlyphIcon extends StatelessWidget {
  /// Creates a glyph icon for [glyph].
  const FossGlyphIcon(this.glyph, {this.size, this.semanticLabel, super.key});

  /// The glyph to paint. Carries its own color.
  final FossGlyph glyph;

  /// The square extent in logical pixels, or null to fill the parent.
  final double? size;

  /// An optional label for assistive technology.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final extent = size;
    final child = CustomPaint(
      size: extent == null ? Size.zero : Size.square(extent),
      painter: glyph,
    );
    if (semanticLabel case final label?) {
      return Semantics(label: label, image: true, child: child);
    }
    return ExcludeSemantics(child: child);
  }
}

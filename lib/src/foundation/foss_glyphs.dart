import 'package:flutter/widgets.dart';

/// The built-in glyphs the components paint when no icon is supplied.
///
/// The package takes no icon dependency, so the default affordances (a dialog
/// close, an alert or toast status mark) are stroked in code. Pass your own
/// `Widget` to any icon slot to override these.
enum FossGlyph {
  /// A close cross.
  close,

  /// An informational mark (a circled dot and stem).
  info,

  /// A success mark (a circled check).
  success,

  /// A warning mark (a triangle with an exclamation).
  warning,

  /// An error mark (a circled exclamation).
  error,
}

/// Paints a [FossGlyph] at [size] in [color]. A lightweight stand-in for an
/// icon font, used for the components' default affordances.
///
/// ```dart
/// const FossGlyphIcon(FossGlyph.success, size: 16, color: Color(0xFF10B981));
/// ```
class FossGlyphIcon extends StatelessWidget {
  /// Creates a glyph icon. [semanticLabel] names it for assistive tech when
  /// the glyph carries meaning (a status); leave it null when decorative.
  const FossGlyphIcon(
    this.glyph, {
    required this.size,
    required this.color,
    this.semanticLabel,
    super.key,
  });

  /// Which glyph to paint.
  final FossGlyph glyph;

  /// The square extent in logical pixels.
  final double size;

  /// The stroke color.
  final Color color;

  /// An optional label for assistive technology.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _FossGlyphPainter(glyph: glyph, color: color),
    );
    if (semanticLabel case final label?) {
      return Semantics(label: label, image: true, child: icon);
    }
    return ExcludeSemantics(child: icon);
  }
}

class _FossGlyphPainter extends CustomPainter {
  const _FossGlyphPainter({required this.glyph, required this.color});

  final FossGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    // Each glyph is described in a unit box and scaled by s.
    Offset p(double x, double y) => Offset(x * s, y * s);
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(p(x1, y1), p(x2, y2), stroke);
    void dot(double x, double y) => canvas.drawCircle(p(x, y), s * 0.055, fill);
    void ring() => canvas.drawCircle(p(0.5, 0.5), s * 0.42, stroke);

    switch (glyph) {
      case FossGlyph.close:
        line(0.28, 0.28, 0.72, 0.72);
        line(0.72, 0.28, 0.28, 0.72);
      case FossGlyph.info:
        ring();
        dot(0.5, 0.32);
        line(0.5, 0.46, 0.5, 0.7);
      case FossGlyph.success:
        ring();
        canvas.drawPath(
          Path()
            ..moveTo(p(0.32, 0.52).dx, p(0.32, 0.52).dy)
            ..lineTo(p(0.45, 0.65).dx, p(0.45, 0.65).dy)
            ..lineTo(p(0.69, 0.37).dx, p(0.69, 0.37).dy),
          stroke,
        );
      case FossGlyph.warning:
        canvas.drawPath(
          Path()
            ..moveTo(p(0.5, 0.16).dx, p(0.5, 0.16).dy)
            ..lineTo(p(0.9, 0.82).dx, p(0.9, 0.82).dy)
            ..lineTo(p(0.1, 0.82).dx, p(0.1, 0.82).dy)
            ..close(),
          stroke,
        );
        line(0.5, 0.42, 0.5, 0.6);
        dot(0.5, 0.71);
      case FossGlyph.error:
        ring();
        line(0.5, 0.3, 0.5, 0.55);
        dot(0.5, 0.68);
    }
  }

  @override
  bool shouldRepaint(_FossGlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

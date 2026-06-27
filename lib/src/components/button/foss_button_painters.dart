part of 'foss_button.dart';

/// Paints a 1px top-lit rim inside the button, the inner highlight on filled
/// variants. Brightest along the top edge, fading to nothing by the middle.
class _TopHighlightPainter extends CustomPainter {
  const _TopHighlightPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RSuperellipse.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(radius),
    );
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRSuperellipse(shape, paint);
  }

  @override
  bool shouldRepaint(_TopHighlightPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Paints the focus ring: a 2px superellipse outset just past the button edge,
/// matching its corner shape so it reads smooth, not circular.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(2);
    final shape = RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(radius + 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRSuperellipse(shape, paint);
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

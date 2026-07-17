part of 'foss_calendar.dart';

/// Paints a single chevron pointing left or right, the month navigation
/// affordance. Mirrors under RTL via [pointsLeft], set by the caller.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color, required this.pointsLeft});

  final Color color;
  final bool pointsLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final near = pointsLeft ? 0.38 : 0.62;
    final far = pointsLeft ? 0.62 : 0.38;
    final path = Path()
      ..moveTo(w * far, h * 0.24)
      ..lineTo(w * near, h * 0.5)
      ..lineTo(w * far, h * 0.76);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) =>
      old.color != color || old.pointsLeft != pointsLeft;
}

/// Paints the keyboard focus ring: a superellipse stroke inset just inside the
/// cell edge, so it reads as the day's corner shape and is not clipped by the
/// abutting neighbor cells.
class _DayRingPainter extends CustomPainter {
  const _DayRingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_ringWidth / 2);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(
        rect,
        Radius.circular(radius - _ringWidth / 2),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth,
    );
  }

  @override
  bool shouldRepaint(_DayRingPainter old) =>
      old.color != color || old.radius != radius;
}

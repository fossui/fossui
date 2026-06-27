import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/theme.dart';

/// A circular loading indicator: an open arc that spins continuously.
///
/// The arc paints in [color], defaulting to the theme `foreground` token. The
/// rotation cycle comes from the `spinner` motion token and stops under reduced
/// motion.
///
/// ```dart
/// const FossSpinner(size: 18);
/// ```
class FossSpinner extends StatefulWidget {
  /// Creates a spinner [size] logical pixels across, in [color].
  const FossSpinner({
    this.size = 24,
    this.color,
    this.semanticLabel = 'Loading',
    super.key,
  });

  /// The width and height of the indicator, in logical pixels.
  final double size;

  /// The arc color. Defaults to the theme `foreground` token.
  final Color? color;

  /// The accessibility label announced while loading.
  final String semanticLabel;

  @override
  State<FossSpinner> createState() => _FossSpinnerState();
}

class _FossSpinnerState extends State<FossSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the motion token here, not in initState: it depends on inherited
    // widgets. A new cycle length applies on the next loop.
    _controller.duration = context.fossTheme.motion.spinner;
    if (!_controller.isAnimating) unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.fossTheme.colors.foreground;

    final arc = SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _SpinnerPainter(color)),
    );

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: widget.semanticLabel,
      child: reduceMotion
          ? arc
          : RotationTransition(turns: _controller, child: arc),
    );
  }
}

/// Paints a 270-degree arc with a round cap, the spinner glyph.
class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width / 12;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // A 270-degree arc starting at the top.
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) => oldDelegate.color != color;
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/progress/foss_progress.dart';
import 'package:fossui/src/theme/theme.dart';

/// {@category Feedback}
/// {@template foss.spinner.preview}
/// <img src="https://fossui.org/components/spinner/overview/light.png"
///   alt="FossSpinner, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/spinner/overview/dark.png"
///   alt="FossSpinner, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [spinner documentation ↗](https://fossui.org/docs/components/spinner) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/spinner/fossspinner/playground).
/// {@endtemplate}
///
/// A circular loading indicator: an open arc that spins continuously.
///
/// The arc paints in [color], defaulting to the theme `foreground` token. The
/// rotation cycle comes from the `spinner` motion token and stops under reduced
/// motion.
///
/// See also [FossProgress] for determinate progress.
///
/// ```dart
/// const FossSpinner(size: 18);
/// ```
class FossSpinner extends StatefulWidget {
  /// {@macro foss.spinner.preview}
  ///
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
    // Read inherited config here, not in initState. A new cycle length applies
    // on the next loop.
    _controller.duration = context.fossTheme.motion.spinner;
    // Only spin when motion is allowed: under reduced motion build drops the
    // rotation, so a running controller would tick invisibly. React either way
    // the flag flips.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
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
      liveRegion: true,
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

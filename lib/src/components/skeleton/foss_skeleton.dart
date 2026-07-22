import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

/// {@category Feedback}
/// {@template foss.skeleton.preview}
/// <img src="https://fossui.org/components/skeleton/overview/light.png"
///   alt="FossSkeleton, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/skeleton/overview/dark.png"
///   alt="FossSkeleton, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [skeleton documentation ↗](https://fossui.org/docs/components/skeleton)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/skeleton/fossskeleton/playground).
/// {@endtemplate}
///
/// A placeholder that stands in for content while it loads.
///
/// Sits in the layout at the size of the content it replaces, filled with the
/// theme `muted` token and swept by a soft shimmer. Compose several boxes to
/// outline a card or list row; use [FossSkeleton.circle] for avatars.
///
/// The shimmer runs on the `skeleton` motion token and stops under reduced
/// motion, leaving a static fill.
///
/// ```dart
/// const FossSkeleton(width: 200, height: 16);
/// const FossSkeleton.circle(size: 40);
/// ```
@FossSince('0.1.1')
class FossSkeleton extends StatefulWidget {
  /// {@macro foss.skeleton.preview}
  ///
  /// Creates a rectangular placeholder [width] by [height] logical pixels,
  /// with corners rounded to the theme `sm` radius.
  const FossSkeleton({this.width, this.height, super.key}) : _circle = false;

  /// Creates a circular placeholder [size] logical pixels across, for avatars
  /// and other round content.
  const FossSkeleton.circle({required double size, super.key})
    : width = size,
      height = size,
      _circle = true;

  /// The placeholder width in logical pixels. Null defers to the parent
  /// constraints; pass `double.infinity` to fill the available width.
  final double? width;

  /// The placeholder height in logical pixels. Null defers to the parent
  /// constraints; pass `double.infinity` to fill the available height.
  final double? height;

  final bool _circle;

  @override
  State<FossSkeleton> createState() => _FossSkeletonState();
}

class _FossSkeletonState extends State<FossSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the cycle length from the theme here, not in initState. A new value
    // applies on the next loop.
    _controller.duration = context.fossTheme.motion.skeleton;
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
    final colors = context.fossTheme.colors;
    final shape = widget._circle
        ? const CircleBorder()
        : RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(context.fossTheme.radii.sm),
          );

    final base = DecoratedBox(
      decoration: ShapeDecoration(shape: shape, color: colors.muted),
    );

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // The shimmer is always a lightening band; only its strength shifts with
    // the theme, brighter on a light surface, barely-there on a dark one.
    final isDark = colors.background.computeLuminance() < 0.5;
    final highlight = Color.fromRGBO(255, 255, 255, isDark ? 0.04 : 0.64);

    // A skeleton is a decorative loading placeholder; keep it out of the
    // semantics tree so a reader is not read an empty box.
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: reduceMotion
            ? base
            : Stack(
                fit: StackFit.expand,
                children: [
                  base,
                  ClipPath(
                    clipper: ShapeBorderClipper(shape: shape),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0x00FFFFFF),
                              highlight,
                              const Color(0x00FFFFFF),
                            ],
                            stops: const [0.35, 0.5, 0.65],
                            // Tile the band so one sweeps in as the last sweeps
                            // out: a continuous shimmer with no flat beat.
                            tileMode: TileMode.repeated,
                            transform: _SweepTranslate(_controller.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Slides the tiled shimmer gradient by exactly one width as [t] runs 0 to 1,
/// so the loop is seamless: [t] = 1 lands on the same phase as [t] = 0.
class _SweepTranslate extends GradientTransform {
  const _SweepTranslate(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(-t * bounds.width, 0, 0);
}

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/motion/foss_motion.dart';

/// The scrim behind a modal overlay: black at 32% opacity (alpha 0x52).
const _scrim = Color(0x52000000);

/// Backdrop blur radius behind the scrim, in logical pixels.
const double _blurSigma = 4;

/// The spring-like curve a bottom sheet and a drawer ride in and out on.
const Cubic kSheetCurve = Cubic(0.32, 0.72, 0, 1);

/// Slides [child] up from the bottom edge on [kSheetCurve]; the bottom-sheet
/// dialog presentation reuses the same route and motion as the drawer.
Widget bottomSheetTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => SlideTransition(
  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(parent: animation, curve: kSheetCurve),
  ),
  child: child,
);

/// Opens [builder] as a modal route, the shared foundation for the dialog,
/// alert dialog, and drawer.
///
/// Wraps [showGeneralDialog] so the framework supplies the focus trap and focus
/// restoration. The scrim is painted here (a 32% black tint over a backdrop
/// blur) so it can fade on its own while the content runs its own transition:
/// the framework barrier is transparent and only handles taps, Esc, and focus.
///
/// The active [FossThemeData] is captured here and re-provided inside the route
/// (which mounts above the app's [FossTheme]), so `context.fossTheme` resolves
/// the same tokens. By default the content runs a fade plus a slight scale over
/// [FossMotion.overlay]; pass [transitionBuilder] and [transitionDuration] to
/// override the content transition only (the drawer and the bottom sheet slide
/// from an edge). The duration is zeroed under `MediaQuery.disableAnimations`.
Future<T?> showFossModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
  Duration? transitionDuration,
  RouteTransitionsBuilder? transitionBuilder,
}) {
  final theme = context.fossTheme;
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final contentTransition = transitionBuilder ?? _fadeScale;

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? (barrierDismissible ? 'Dismiss' : null),
    // Transparent: the visible scrim is painted below, so it blurs and fades
    // independently of the content transition. This barrier only takes taps.
    barrierColor: const Color(0x00000000),
    transitionDuration: reduceMotion
        ? Duration.zero
        : (transitionDuration ?? theme.motion.overlay),
    pageBuilder: (context, animation, secondaryAnimation) => FossTheme(
      data: theme,
      // The route mounts outside any Material or DefaultTextStyle, so text
      // would fall back to the framework's debug style. Set a clean base.
      child: DefaultTextStyle(
        style: theme.typography.base.copyWith(
          color: theme.colors.popoverForeground,
          decoration: TextDecoration.none,
        ),
        child: Stack(
          children: [
            _Scrim(animation: animation),
            contentTransition(
              context,
              animation,
              secondaryAnimation,
              Builder(builder: builder),
            ),
          ],
        ),
      ),
    ),
    // The content transition is applied inside pageBuilder so the scrim can sit
    // outside it; the route-level transition is a pass-through.
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

/// The blurred, tinted scrim, fading on the route animation. Ignores pointers
/// so taps fall through to the framework barrier that dismisses the route.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: const ColoredBox(color: _scrim),
          ),
        ),
      ),
    );
  }
}

/// The default content enter and exit: a fade plus a slight scale.
Widget _fadeScale(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
      child: child,
    ),
  );
}

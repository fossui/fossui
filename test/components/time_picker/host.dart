import 'package:flutter/widgets.dart';
import 'package:fossui/fossui.dart';

/// Wraps [child] in a themed [WidgetsApp] so the time dialog has a Navigator to
/// push its modal route onto.
///
/// The direction and media data sit in the app builder, above the navigator, so
/// the pushed modal inherits them too. The date picker harness keeps them in
/// `home`, which is enough for a trigger-only assertion but leaves a route on
/// the app defaults.
Widget host(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool reduceMotion = false,
  bool alwaysUse24HourFormat = false,
}) => FossTheme(
  data: theme ?? FossThemeData.light,
  child: WidgetsApp(
    color: const Color(0xFF000000),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, _) => builder(context),
    ),
    builder: (context, navigator) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
          alwaysUse24HourFormat: alwaysUse24HourFormat,
        ),
        child: navigator ?? const SizedBox.shrink(),
      ),
    ),
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

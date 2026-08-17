import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

/// Wraps [child] in a minimal app for pagination widget tests. The default
/// [width] is wide enough to hold nine slots, so the row keeps the requested
/// sibling count unless a test narrows it.
Widget host(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  double width = 500,
}) => MaterialApp(
  home: FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Center(
          child: SizedBox(
            width: width,
            child: Center(child: child),
          ),
        ),
      ),
    ),
  ),
);

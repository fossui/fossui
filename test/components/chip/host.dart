import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

/// Wraps [child] in a minimal app for chip widget tests. Keyboard tests need a
/// real app for focus traversal, so this hosts the chip inside one.
Widget host(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  double width = 400,
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

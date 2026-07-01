import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';

/// Wraps [child] in a themed app with an [Overlay] so the combobox popup can
/// mount. Mirrors the harness the other overlay components test against.
Widget host(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool reduceMotion = false,
}) => FossTheme(
  data: theme ?? FossThemeData.light,
  child: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

/// Wraps [child] in a themed app with an [Overlay] so the menu panel can
/// mount. Mirrors the harness the other overlay components test against.
Widget host(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool reduceMotion = false,
  Size size = const Size(800, 600),
  Alignment alignment = Alignment.topLeft,
}) => FossTheme(
  data: theme ?? FossThemeData.light,
  child: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Align(
              alignment: alignment,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// The trigger every test taps, so the finder is the same everywhere.
const Widget menuTrigger = Text('Open');

/// Like [host], but over the navigator's own overlay, so pumping a new tree
/// updates the menu in place. [host] mounts an `Overlay` directly, and an
/// overlay reads `initialEntries` only when it mounts, so a second pump there
/// leaves the first menu standing.
Widget rebuildableHost(
  Widget child, {
  FossThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

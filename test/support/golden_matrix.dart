import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';

/// Wraps [child] in a [FossTheme] for [data] on a neutral themed surface, the
/// standard cell body for a golden scenario.
Widget themed(FossThemeData data, Widget child) => FossTheme(
  data: data,
  child: Container(
    padding: const EdgeInsets.all(16),
    color: data.colors.background,
    child: Center(child: child),
  ),
);

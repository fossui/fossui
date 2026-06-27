import 'package:flutter/material.dart';
import 'package:foss_ui_example/main.directories.g.dart';
import 'package:foss_ui_example/theme_addon.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    directories: directories,
    // Mobile viewport sweep waits on ViewportAddon (widgetbook >=3.15), which
    // needs a newer Flutter than the pinned SDK allows. Add it on the bump.
    addons: [
      fossThemeAddon(),
      TextScaleAddon(min: 1),
    ],
  );
}

void main() => runApp(const WidgetbookApp());

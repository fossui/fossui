import 'package:flutter/widgets.dart';
import 'package:foss_ui/foss_ui.dart';
import 'package:widgetbook/widgetbook.dart';

const WidgetbookTheme<FossThemeData> _dark = WidgetbookTheme(
  name: 'Dark',
  data: FossThemeData.dark,
);

/// The light/dark [FossThemeData] axis, the primary visual dimension.
///
/// Each use-case renders wrapped in a [FossTheme] so `context.fossTheme`
/// resolves exactly as it would in a consumer app, over a surface painted with
/// the selected theme's `background` token. Defaults to dark to match the
/// catalog shell.
ThemeAddon<FossThemeData> fossThemeAddon() => ThemeAddon<FossThemeData>(
  themes: const [
    WidgetbookTheme(name: 'Light', data: FossThemeData.light),
    _dark,
  ],
  initialTheme: _dark,
  themeBuilder: (context, theme, child) => FossTheme(
    data: theme,
    child: ColoredBox(color: theme.colors.background, child: child),
  ),
);

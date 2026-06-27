# foss_ui example

An interactive Widgetbook catalog for the components in `foss_ui`. It doubles as
the package example: one app that browses every component and shows how to wire
the theme.

## Run it

```bash
fvm flutter pub get
fvm dart run build_runner build
fvm flutter run
```

`build_runner` regenerates `lib/main.directories.g.dart`, the use-case tree
collected from the `@UseCase` annotations. That file is generated, so it is not
checked in; run the build step after pulling or adding a component.

## How it is laid out

- `lib/use_cases/` holds one file per component, mirroring
  `lib/src/components/` in the package. Each use-case is a small annotated
  function; knobs drive its props so you can flip variant, size, and state live.
- `lib/theme_addon.dart` wires the light and dark `FossThemeData` as the theme
  axis. Every use-case renders inside a `FossTheme`, so `context.fossTheme`
  resolves exactly as it does in a consumer app.
- A text-scale addon sweeps from 1.0 to 2.0 for the accessibility pass.

Icons in the catalog come from `lucide_icons_flutter`, the companion icon set
the docs use throughout. The package itself takes no icon dependency.

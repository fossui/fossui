<div align="center">

<img src="assets/logo.png" alt="fossui" width="200" />

**The Fresh, Minimal Flutter UI kit.<br/>
Themed from one source. Inspired by [coss.com/ui](https://coss.com/ui), Cal.com's design system.**

[![Pub Version](https://img.shields.io/pub/v/fossui?logo=dart&color=0175C2)](https://pub.dev/packages/fossui) [![Pub Likes](https://img.shields.io/pub/likes/fossui?logo=dart&color=0175C2)](https://pub.dev/packages/fossui) [![GitHub stars](https://img.shields.io/github/stars/fossui/fossui?logo=github)](https://github.com/fossui/fossui) [![Coverage](https://img.shields.io/endpoint?url=https://coverage.fossui.org/coverage.json)](https://coverage.fossui.org)

</div>

<p align="center">
  <img src="assets/demo.gif" alt="fossui components" width="900" />
</p>

fossui is a component set for developers tired of every Flutter app looking like
Material. It drops into any app, whether you use `MaterialApp`, `CupertinoApp`,
or a bare `WidgetsApp`, and reads its own theme first rather than replacing
yours. The look is drawn from [coss.com/ui](https://coss.com/ui), Cal.com's
design system: clean and neutral, with superellipse corners. One import, one
theme, light and dark out of the box.

> [!IMPORTANT]
> Unofficial and independent. Not affiliated with or endorsed by Cal.com, Inc.
> or coss.com. See [NOTICE](NOTICE) for attribution.

## Features

- **A look that isn't Material.** A neutral, understated aesthetic with
  superellipse corners, drawn from the coss/Cal.com design language.
- **Framework-agnostic.** Built on `package:flutter/widgets.dart`, with no
  platform channels and no `FossApp` wrapper. The widgets work under any app
  shell.
- **Reads your theme, not the other way around.** Components resolve
  `context.fossTheme` before falling back to Material, so they keep their look
  inside an existing app.
- **Themed from one source.** A single `FossThemeData` holds every semantic
  token: color, type, radius, spacing, shadow, motion. Reskin the whole app,
  light and dark, in one call.
- **Light on dependencies.** One runtime dependency and no bundled icon package.
  A worst-case app that imports nearly every component adds about 384 KB: roughly
  310 KB of Dart code, which tree-shakes down to what you actually use, plus the
  Geist font (74 KB installed, ~35 KB over the wire). Pass your own icons through
  plain `Widget` slots.
- **Preview-rich docs.** Every component's API doc renders a live light and dark
  preview, not just text, and the same preview shows on hover in your IDE. Each
  one states plainly what it does and does not do.
- **Accessible by default.** Semantics, focus, and touch targets are built into
  each component.

## Install

```yaml
dependencies:
  fossui: ^0.1.1
```

Or from the command line:

```bash
flutter pub add fossui
```

## Quick start

Register the theme once, then use the widgets anywhere.

```dart
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

void main() => runApp(
      MaterialApp(
        theme: FossThemeData.light.toThemeData(),
        darkTheme: FossThemeData.dark.toThemeData(),
        home: Scaffold(
          body: Center(
            child: FossButton(
              onPressed: () {},
              child: const Text('Get started'),
            ),
          ),
        ),
      ),
    );
```

No wrapper lock-in. `FossTheme` drops into any app, and `context.fossTheme`
resolves identically under `MaterialApp`, `CupertinoApp`, or a bare
`WidgetsApp`.

See [`example/`](https://pub.dev/packages/fossui/example) for a runnable app.

## Theming

The defaults give fossui its look, but nothing is locked. Read tokens through
one accessor:

```dart
final theme = context.fossTheme;
final color = theme.colors.primary;
final radius = theme.radii.md;
```

To reskin the app, layer a `FossThemeSpec` over a base theme. Every field is
optional, and anything you leave unset keeps the default.

```dart
MaterialApp(
  theme: FossThemeData.light.retheme(
    const FossThemeSpec(primary: Color(0xFF16A34A), radius: 22),
  ).toThemeData(),
  darkTheme: FossThemeData.dark.retheme(
    const FossThemeSpec(primary: Color(0xFF51F0A8), radius: 22),
  ).toThemeData(),
);
```

## Components

The library covers input, feedback, overlays, and layout:

| Group | Components |
| --- | --- |
| Actions and input | Button, TextField, NumberField, OtpField, Select, Combobox, Checkbox, Radio, Switch, Toggle, ToggleGroup, Slider, DatePicker |
| Feedback | Alert, Badge, Meter, Progress, Skeleton, Spinner, Toast, Tooltip |
| Overlays | Dialog, Drawer (sheet and bottom sheet), Popover |
| Layout and media | Accordion, Card, Tabs, Separator, Text, Calendar, Avatar |

See the [components roadmap](https://github.com/fossui/fossui/blob/main/doc/components/roadmap.md)
for what is shipped and what is planned, and the
[component checklist](https://github.com/fossui/fossui/blob/main/doc/components/checklist.md)
for the bar each one clears.

## Icons

Icon slots accept a plain `Widget`, so any icon set works: Lucide, Material
Icons, Cupertino, SVGs, or your own. The package pulls in no icon dependency of
its own. Examples and docs use [Lucide](https://pub.dev/packages/lucide_icons)
as the documented companion.

## Platforms

With no platform channels, fossui runs anywhere Flutter does: Android, iOS, web,
macOS, Windows, and Linux are all supported.

## AI-native

fossui runs an MCP server so your AI coding assistant writes fossui code against
the real component API instead of guessing prop names and enum values. It works
with any MCP client (Claude Code, Cursor, VS Code, and more) over one endpoint:

```
https://mcp.fossui.org
```

Per-client setup and the full tool list are in the
[AI-native docs](https://fossui.org/docs/ai-native).

## Ecosystem

- Documentation: [fossui.org](https://fossui.org)
- Live gallery: [play.fossui.org](https://play.fossui.org)
- AI-native (MCP): [fossui.org/docs/ai-native](https://fossui.org/docs/ai-native)
- Package: [pub.dev/packages/fossui](https://pub.dev/packages/fossui)

## Development

This package pins its Flutter SDK with [fvm](https://fvm.app):

```bash
fvm install          # uses .fvmrc (Flutter 3.41.9)
fvm flutter pub get
fvm flutter test
```

The test suite runs on every change and holds full line coverage; browse the
live report at [coverage.fossui.org](https://coverage.fossui.org).

Contributions are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Acknowledgements

The look and component API are drawn from [coss.com/ui](https://coss.com/ui), the
Cal.com design system, with ideas from [Base UI](https://github.com/mui/base-ui)
and [shadcn/ui](https://github.com/shadcn-ui/ui). Full attribution is in
[NOTICE](NOTICE).

## Support

If fossui is useful to you, two clicks go a long way:

- ⭐ [Star fossui on GitHub](https://github.com/fossui/fossui)
- 👍 [Like fossui on pub.dev](https://pub.dev/packages/fossui)
- ✉️ Questions or feedback: [support@fossui.org](mailto:support@fossui.org)

## Star History

<!-- star-history:start -->
[![Star History](https://raw.githubusercontent.com/fossui/fossui/main/assets/star-history/star-history.png)](https://star-history.com/#fossui/fossui&Date)
<!-- star-history:end -->

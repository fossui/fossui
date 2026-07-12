# fossui

An open-source Flutter UI library of themeable, accessible components, inspired
by coss.com/ui, Cal.com's design system. Themed from one source, one import.

> **Under active development.** `0.1.0` ships 21 components. Under 0.x, APIs and
> tokens can still change between releases, so pin a version you have tested
> against.

> **Unofficial.** Not affiliated with or endorsed by Cal.com, Inc. or coss.com.
> See [NOTICE](NOTICE) for attribution.


![examples](assets/examples.png)


## Install

```yaml
dependencies:
  fossui: ^0.1.0
```

## Usage

Register the theme once, then read tokens through `context.fossTheme`. There is
no `FossApp` wrapper; the library works under `MaterialApp`, `CupertinoApp`, or a
bare `WidgetsApp`.

```dart
import 'package:flutter/material.dart';
import 'package:fossui/fossui.dart';

void main() => runApp(
      MaterialApp(
        theme: FossThemeData.light.toThemeData(),
        darkTheme: FossThemeData.dark.toThemeData(),
        home: const Scaffold(
          body: Center(child: FossBadge(label: Text('fossui'))),
        ),
      ),
    );
```

See [`example/`](example/) for a runnable app. Components and theming are added
in tiers. See the
[components roadmap](doc/components/roadmap.md) for what is shipped and what is
planned, the [component checklist](doc/components/checklist.md) for the bar each
one clears, and [CHANGELOG.md](CHANGELOG.md) for released versions.

## Links

- Documentation: [fossui.org](https://fossui.org)
- Live gallery: [play.fossui.org](https://play.fossui.org)
- Package: [pub.dev/packages/fossui](https://pub.dev/packages/fossui)

## Platforms

Built on `package:flutter/widgets.dart` with no platform channels, so it runs
anywhere Flutter does. Mobile is the tested target:

| Platform | Status |
| --- | --- |
| iOS, Android | Tested and supported. |
| Web, macOS, Windows, Linux | Should work, not yet verified. Use with care. |

## Development

This package pins its Flutter SDK with [fvm](https://fvm.app):

```bash
fvm install          # uses .fvmrc (Flutter 3.41.9)
fvm flutter pub get
fvm flutter test
```

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
workflow and the [Code of Conduct](CODE_OF_CONDUCT.md).



## License

MIT. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Star History

<!-- star-history:start -->
[![Star History](https://raw.githubusercontent.com/fossui/fossui/main/assets/star-history/star-history.png)](https://star-history.com/#fossui/fossui&Date)
<!-- star-history:end -->

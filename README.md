# foss_ui

An open-source Flutter UI library. Unofficial port inspired by
[coss.com/ui](https://coss.com/ui) (the Cal.com design system), reimplemented
with Flutter-native theming and golden-tested widgets.

> **Status:** early development. APIs and tokens will change.

> **Unofficial.** Not affiliated with or endorsed by Cal.com, Inc. or coss.com.
> See [NOTICE](NOTICE) for attribution.

## Install

```yaml
dependencies:
  foss_ui: ^0.0.1
```

## Usage

```dart
import 'package:foss_ui/foss_ui.dart';
```

Components and theming are added in tiers. See the
[components roadmap](docs/components/roadmap.md) for what is shipped and what is
planned, the [component checklist](docs/components/checklist.md) for the bar each
one clears, and [CHANGELOG.md](CHANGELOG.md) for released versions.

## Development

This package pins its Flutter SDK with [fvm](https://fvm.app):

```bash
fvm install          # uses .fvmrc (Flutter 3.41.9)
fvm flutter pub get
fvm flutter test
```

## License

MIT. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

# Component catalog

`foss_ui` ships an interactive catalog of every component, built with [Widgetbook](https://pub.dev/packages/widgetbook). It runs each component live, under the package themes and an accessibility text-scale sweep, so you can flip a variant or a size and watch it change instead of reading a static grid. The same app doubles as the package `example/`, the reference a consumer lands on from the pub.dev page.

The catalog is for seeing and demoing. It does not assert anything: the goldens lock the pixels and the widget tests drive behavior. Think of it as the showroom, with [goldens.md](goldens.md) as the inspection.

## It lives in `example/`, on purpose

The catalog is a separate Dart package under [`example/`](../../example), with its own `pubspec.yaml` and a path dependency back on the package:

```yaml
dependencies:
  foss_ui:
    path: ../
```

That split is the whole point. The Widgetbook toolchain (widgetbook, the generator, lucide for the demo icons) lives only in `example/pubspec.yaml`, never in the package. So a consumer who adds `foss_ui` pulls the package's runtime dependencies and nothing else: pub never reads a dependency's nested `example/pubspec.yaml`, and dev dependencies do not propagate. The catalog can grow as heavy as it likes without adding a gram to what consumers resolve.

One exception runs the other way: Alchemist stays a package dev dependency, because the goldens run in `test/`, not here.

## Running it

From the repo root:

```sh
sh scripts/dev/catalog.sh
```

This syncs the catalog's deps, regenerates the use-case tree, then launches the app and prompts for a device. To regenerate without launching (what CI does before a web build):

```sh
sh scripts/dev/catalog.sh --build
sh scripts/dev/catalog.sh -- -d chrome    # launch on a chosen device
sh scripts/dev/catalog.sh --help          # all options
```

The script picks the launcher for you: `fvm flutter` locally, plain `flutter` in CI (or where `fvm` is absent), the same way `coverage.sh` and `goldens.sh` do. The pinned SDK is the same either way; only the prefix differs.

The raw commands, if you would rather not use the script:

```sh
cd example
fvm flutter pub get
fvm dart run build_runner build
fvm flutter run
```

## Use-cases are generated

You do not hand-build the catalog tree. Each entry is a top-level function annotated with `@UseCase`, and the generator collects them:

```dart
@widgetbook.UseCase(name: 'Default', type: FossSpinner)
Widget defaultSpinner(BuildContext context) {
  final size = context.knobs.double.slider(label: 'Size', initialValue: 24);
  return Center(child: FossSpinner(size: size));
}
```

`build_runner` walks those annotations and writes [`example/lib/main.directories.g.dart`](../../example/lib/main.directories.g.dart), the tree `main.dart` mounts. Knobs (the `context.knobs` calls) become live controls in the panel, so one use-case covers a whole prop instead of one cell per value.

`example/lib/use_cases/` mirrors `lib/src/components/` one to one, the same way `test/components/` mirrors `lib/src`. A component at `src/components/spinner/foss_spinner.dart` has its catalog entries at `example/lib/use_cases/spinner_use_cases.dart`. Add a component, add the matching use-case file, rerun the script.

## The generated file is not committed

`main.directories.g.dart` is an app artifact, regenerated on demand, so it is gitignored. This is the opposite call from the package's `*.tailor.dart`, which **is** committed because it is part of the published `lib/`. The catalog tree ships nowhere, so it is rebuilt from the annotations whenever you run the script. After pulling, or adding a component, run `--build` (or the full script) to refresh it.

## Theme and addons

The root wraps every use-case so components resolve `context.fossTheme` exactly as a consumer app would. Two addons drive the axes:

| Addon | What it sweeps |
|-------|----------------|
| Theme | the package light and dark `FossThemeData`, the primary visual axis |
| Text scale | 1.0 to 2.0, the accessibility pass |

The theme addon wires the package themes through a `FossTheme`, so the preview canvas is painted in the selected theme's `background` and components read real tokens. It defaults to dark to match the catalog shell.

Two things worth knowing about the surface you see:

- **The dashboard chrome (the nav tree and toolbar) is Widgetbook's own fixed UI.** The addon themes the preview canvas, not the surrounding shell; that shell is not restyleable from here.
- **The mobile viewport sweep is not wired yet.** It needs Widgetbook's `ViewportAddon`, which wants a newer Flutter than the pinned SDK allows. It lands with the SDK bump; until then the catalog renders at the window size.

## Where it is headed

The web build is meant to deploy as living documentation, with hosted visual regression alongside the local goldens. That needs the web platform configured (`flutter create . --platforms web`) and CI wiring, neither done yet. The `--build` step exists so CI can regenerate the tree before that web build slots in.

## Troubleshooting

- **The catalog opens but the nav tree is empty.** The generated tree is stale or missing. Run `sh scripts/dev/catalog.sh --build` to regenerate `main.directories.g.dart`.
- **A new component does not appear.** Its use-case file is missing or the build was not rerun. Add `example/lib/use_cases/<component>_use_cases.dart` with an `@UseCase` function, then rerun the script.
- **`flutter run` finds no devices.** No platform is configured for this app yet. Run `flutter create . --platforms web` in `example/`, then `sh scripts/dev/catalog.sh -- -d chrome`.
- **The preview looks dark and you wanted light.** Dark is the default to match the shell; switch it in the Theme addon in the toolbar.

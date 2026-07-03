# Golden tests

`foss_ui` locks the rendered look of every component with golden tests, powered by [Alchemist](https://pub.dev/packages/alchemist). A golden is a reference image of a widget; the test re-renders the widget and fails if a single pixel drifts from the committed reference. That is how an accidental change to padding, color, or radius gets caught before review instead of after.

Goldens cover what a widget looks like: geometry, color, slot layout, and how those shift across theme, text direction, and text scale. They do not cover behavior (tap, focus, state) or the semantics tree; those are widget tests and accessibility tests. Keep the split in mind when deciding where an assertion belongs.

## Two flavors

Every golden runs in one of two flavors, and the difference is the whole trick to making image tests reliable.

| | CI flavor | Platform flavor |
|---|---|---|
| Font | Ahem (every glyph a solid box) | the bundled Geist face |
| Text | obscured to boxes | rendered normally |
| Shadows | off | on |
| Committed | yes, under `goldens/ci/` | no, gitignored |
| Role | the build gate | a readable local preview |

The CI flavor is the source of truth. It trades real fonts and shadows for output that is byte-identical across machines, so a reference you generate on a Mac matches what the Linux CI renders. That parity is the only reason a committed image can gate the build at all.

The platform flavor is for your eyes. It renders with the real font and shadows so you can actually see what changed, but it is never committed and never authoritative.

The two are split on the `CI` environment variable in [`test/flutter_test_config.dart`](../../test/flutter_test_config.dart). GitHub Actions sets `CI=true` automatically, so CI runs only the committed flavor. Locally, with `CI` unset, both run.

## Running them

Goldens are tagged `golden`, so you can run or skip them on their own. A small wrapper handles the fvm-vs-flutter launcher and the verify/update split, the same way `coverage.sh` does:

```sh
# verify against the committed references
sh scripts/dev/goldens.sh

# skip goldens for the fast inner loop
fvm flutter test --exclude-tags golden
```

The hooks already do the right thing: `pre-commit` skips goldens to stay fast, and `pre-push` runs the full suite including them. See [lefthook.md](lefthook.md).

## The matrix

A component is golden-tested across the axes that actually change its pixels, and only those. Taking every axis for every component would explode the image count for no signal, so each test takes the relevant axes and documents the ones it drops.

The full set of axes is `variant x size x state x theme x direction x textScale`. A component picks from it. The spinner, for example, sweeps `size x color x theme` and drops state, direction, and text scale, because it has no interactive state, no text, and no directional layout. That decision is written into the test so the trim is deliberate, not forgotten.

Each cell is a scenario on a neutral themed surface, with no app chrome. The themed wrap is factored into [`test/support/golden_matrix.dart`](../../test/support/golden_matrix.dart) so components share one builder instead of repeating it.

## Animated widgets

An animation that never settles will hang the default golden setup, because it waits for the widget to go still and the widget never does. The fix is to capture a single, fixed frame.

A widget like the spinner passes a custom `pumpBeforeTest` that pumps one frame to a known point in the loop, rather than pumping until settled. That gives a deterministic image every run. Any component with an indefinite animation needs the same treatment; never let a golden depend on a frame whose timing you do not control.

## What is committed

Tests mirror `lib/src`. References sit in flavor subfolders beside the test:

```
test/
  flutter_test_config.dart          the CI/platform split
  support/
    golden_matrix.dart              shared scenario builders
  components/
    spinner/
      foss_spinner_golden_test.dart
      failures/  ...               gitignored (written on a mismatch)
      goldens/
        ci/        spinner.png      committed
        macos/     spinner.png      gitignored (also linux/, windows/)
```

Only `ci/` enters history. The gitignore ignores every flavor folder, re-includes `ci/`, and drops the mismatch artifacts:

```
test/**/goldens/*/
!test/**/goldens/ci/
test/**/failures/
```

Keep cells small so the committed PNGs stay tiny and a diff stays readable in a pull request.

## Updating a reference

When you change a component on purpose, its golden will fail, and you regenerate it.

The committed `ci/` references render on the CI platform, so regenerate them there: run the **Update goldens** workflow ([`.github/workflows/update-goldens.yaml`](../../.github/workflows/update-goldens.yaml)) on your branch from the Actions tab, or with `gh workflow run "Update goldens" --ref <branch>`. It renders the references on CI and commits them back to the branch.

Locally, `--update` regenerates only the host-rendered preview, which is gitignored:

```sh
sh scripts/dev/goldens.sh --update
```

Then look at the diff of `goldens/ci/*.png` before merging it. A changed reference is a reviewed artifact, not a rubber stamp: an unexpected pixel change is a bug to chase, not an image to accept. Only `ci/` is committed; the preview and failure images stay gitignored.

A change to a shared token (a color, a radius, a type scale) will move every component's goldens at once. That sweep is reviewed as one diff, since the point is to see exactly what the token shifted.

## How it is wired

CI runs goldens as their own job, calling [`scripts/dev/goldens.sh`](../../scripts/dev/goldens.sh). GitHub Actions sets `CI=true`, so only the committed Ahem flavor renders and gates. Config lives in the workflow ([`.github/workflows/ci.yaml`](../../.github/workflows/ci.yaml)) and the test config above. The SDK is pinned with FVM (`.fvmrc`), and goldens are only valid for that SDK; a Flutter bump is a deliberate regenerate-everything change, reviewed as a sweep, because a renderer can shift edge antialiasing between versions.

## Troubleshooting

- **A golden test hangs forever.** The widget animates and never settles. Give it a custom `pumpBeforeTest` that pumps a single frame; see above.
- **The reference looks blank or text is boxes.** That is the CI flavor doing its job (Ahem font, obscured text). Open the `macos/` image instead for a readable preview.
- **A golden fails right after an SDK change.** Antialiasing can shift between Flutter versions. Regenerate all goldens and review the sweep, do not loosen the tolerance.
- **A reference you did not touch fails.** Check for a shared-token change upstream; one token moves every dependent golden.
- **Platform goldens look wrong locally.** The real font may not have loaded. Only the committed CI flavor gates, so this never affects the build; fix the font load if you want the preview back.

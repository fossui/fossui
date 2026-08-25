# Package size

What fossui adds to your app. These are worst-case numbers, from an app that
references every component in the library. A real app that touches a few adds
less, because Flutter tree-shakes the Dart code it does not use.

## Breakdown

| Item | Size | Notes |
|------|------|-------|
| Dart code (AOT) | 357 KB | tree-shaken; scales with the components you use |
| Geist font | 74 KB | fixed cost, always bundled |
| Runtime deps | ~0 | one small annotation package, no icon dependency |
| **Total** | **~430 KB** | Dart plus font |

Only one runtime dependency, `theme_tailor_annotation`, and no bundled icon set,
so nothing beyond the font is pulled in.

The font is the one fixed cost: it does not tree-shake the way Dart code does. It
is subset to Latin and the 400 to 700 weight range, which keeps it at 74 KB.

## What tree-shaking saves

The same build measured against an app referencing 34 of the 39 components comes
out at 316 KB of Dart, against 357 KB for all 39. Five components account for
41 KB, so the total above is a ceiling rather than a baseline.

## On disk vs download

- **On disk**: the unpacked size after install (font 74 KB).
- **Download**: the compressed size inside the release build (font ~35 KB). This
  is what a user actually downloads.

Numbers current as of the `0.1.2` release, measured on an arm64 release APK.
Regenerate them with `scripts/dev/measure-size.sh [app-dir]`, which builds the
given app with `--analyze-size` and sums the `package:fossui` symbols plus the
font. Point it at an app that references every component; the bundled `example/`
does not, so it reads about 41 KB light.

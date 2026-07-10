# Package size

What fossui adds to your app. These are worst-case numbers, from an app that
imports nearly every component. A real app that touches a few adds less, because
Flutter tree-shakes the Dart code it does not use.

## Breakdown

| Item | Size | Notes |
|------|------|-------|
| Dart code (AOT) | 237 KB | tree-shaken; scales with the components you use |
| Geist font | 74 KB | fixed cost, always bundled |
| Runtime deps | ~0 | one small annotation package, no icon dependency |
| **Total** | **~314 KB** | about 1.9% of a typical 16.7 MB release APK |

Only one runtime dependency, `theme_tailor_annotation`. Icon slots take a
`Widget?`, so there is no icon package to pull in.

The font is the one fixed cost: it does not tree-shake the way Dart code does. It
is subset to Latin and the 400 to 700 weight range, which keeps it at 74 KB.

## On disk vs download

- **On disk**: the unpacked size after install (font 74 KB).
- **Download**: the compressed size inside the release build (font ~36 KB). This
  is what a user actually downloads.

Numbers current as of the `0.1.0-beta.3` release.

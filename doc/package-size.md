# Package size

What fossui adds to your app. These are worst-case numbers, from an app that
imports nearly every component. A real app that touches a few adds less, because
Flutter tree-shakes the Dart code it does not use.

## Breakdown

| Item | Size | Notes |
|------|------|-------|
| Dart code (AOT) | 310 KB | tree-shaken; scales with the components you use |
| Geist font | 74 KB | fixed cost, always bundled |
| Runtime deps | ~0 | one small annotation package, no icon dependency |
| **Total** | **~384 KB** | Dart plus font |

Only one runtime dependency, `theme_tailor_annotation`, and no bundled icon set,
so nothing beyond the font is pulled in.

The font is the one fixed cost: it does not tree-shake the way Dart code does. It
is subset to Latin and the 400 to 700 weight range, which keeps it at 74 KB.

## On disk vs download

- **On disk**: the unpacked size after install (font 74 KB).
- **Download**: the compressed size inside the release build (font ~35 KB). This
  is what a user actually downloads.

Numbers current as of the `0.1.1` release. Regenerate them with
`scripts/dev/measure-size.sh`, which builds the bundled `example/` (worst case,
every component referenced) with `--analyze-size` and sums the `package:fossui`
code plus the font.

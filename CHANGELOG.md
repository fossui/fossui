## 0.1.0-beta.3

A quality pass over every component: accessibility, visual fidelity, touch
targets, and golden coverage. No new components, plus one additive theming API
for one-call rebrands.

### Added

* `FossNumberField`: a numeric input flanked by decrement and increment steppers.
  Holds a `num` clamped to `[min, max]`, steps by `step` (and `largeStep` on the
  page keys), and formats display and typed entry through `format` / `parse`. It
  reuses the text field box across three sizes, exposes the invalid state through
  `error`, and takes a `FossNumberFieldStyle` for one-off overrides.
* `FossThemeData.retheme` layers a compact `FossThemeSpec` over a base theme:
  enumerated color roles, plus single seeds for radius, spacing, shadow tint, and
  font family. `FossRadii.fromBase` derives the radius scale from one value.

### Improved

* Accessibility across the set. The progress bar exposes its role and numeric
  range. Radio groups get arrow-key roving focus and a group role. The spinner
  stops under reduced motion and announces once on appear. Toasts announce
  errors assertively and hold open while pressed. Text fields expose the hint as
  an accessible hint and drop focus on an outside tap.
* Touch targets sized for the finger. A standalone checkbox and an icon-only
  button floor to a full target, while grouped rows hug their content so a stack
  keeps even spacing.
* Fidelity fixes. Softer resting shadows on the switch, tabs, tooltip, and
  slider. Corrected padding on the badge, tabs, and text field. Card content
  inherits the card foreground, and every form error caption shares one color.
* Toasts swipe to dismiss in any direction, and the drawer drags without
  rebuilding its panel. A burst of toasts now collapses into a peek pile, so the
  stack stays compact instead of filling the screen.
* The bundled font ships lighter, trimmed to the glyphs and weights the library
  renders, so it adds about half of what it did to an app.

### Fixed

* A toast queued behind the visible cap no longer expires before it is seen; its
  timer pauses until it surfaces.

## 0.1.0-beta.2

Consolidation and polish. No new components; the public API is unchanged.

### Improved

* Dialogs share one surface and route. `FossAlertDialog` composes `FossDialog`,
  and a helper presents either as a bottom sheet or a centered card.
* Select and combobox popups dismiss on scroll, stay within the viewport, and
  open on arrow-down.
* The text field and combobox share one field frame, so their border, focus
  ring, and sizing match.
* Default marks (checks, chevrons, close, status icons) render from one internal
  glyph set, for a single consistent geometry.

### Fixed

* Combobox popup no longer duplicates entries or leaves its overlay behind.

## 0.1.0-beta.1

First component release. Everything ships from a single
`import 'package:fossui/fossui.dart';`.

### Theming

* Token system as a `ThemeExtension`: `FossThemeData` with light and dark
  defaults, six token bundles (colors, typography, radii, spacing, shadows,
  motion), a `FossTheme` widget for non-Material apps, and the
  `context.fossTheme` accessor.

### Components

* Buttons and inputs: `FossButton` (with an icon-only variant), `FossTextField`,
  `FossCheckbox`, `FossRadio`, `FossSwitch`, `FossSlider`.
* Selection: `FossSelect`, `FossMultiSelect`, `FossCombobox`.
* Surfaces and overlays: `FossCard`, `FossDialog`, `FossAlertDialog`,
  `FossDrawer`, `FossTooltip`, `FossToast` with `FossToaster`.
* Feedback and display: `FossAlert`, `FossBadge`, `FossAvatar`, `FossProgress`,
  `FossSpinner`, `FossSeparator`, `FossTabs`.

## 0.0.1

* Initial package scaffold: structure, theming and component barrels, MIT
  license, and attribution NOTICE.

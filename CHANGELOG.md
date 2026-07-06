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

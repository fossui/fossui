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

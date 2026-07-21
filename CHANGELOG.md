## 0.1.1

### Added

* `FossAccordion` presents a vertical stack of collapsible sections. It is
  keyboard navigable, supports single or multiple open sections, and takes a
  `FossAccordionStyle` for one-off overrides.
* `FossCalendar` shows a single month grid with single, multiple, or range
  selection (`FossCalendar.single` / `.multiple` / `.range`), a `FossDateRange`
  value type, `minDate` / `maxDate` and `isDateEnabled` bounds, keyboard grid
  navigation, and a `FossCalendarStyle` for one-off overrides.
* `FossDatePicker` opens a `FossCalendar` in a modal dialog from a field trigger
  and shows the chosen date back in it (`FossDatePicker.single` / `.range`). It
  presents as a bottom sheet by default or a centered card via `presentation`,
  and takes a `format` callback with a built-in default (no date library), a
  `closeOnSelect` policy, controlled (`open` + `onOpenChange`) or uncontrolled
  open, keyboard open and `Escape` dismiss, `minDate` / `maxDate` /
  `isDateEnabled` / `firstDayOfWeek` passed through to the calendar, and a
  `FossDatePickerStyle` for one-off overrides.
* `FossMeter` renders a static gauge for a bounded value, themed through
  `FossMeterStyle`.
* `FossNumberField` pairs a numeric input with decrement and increment steppers,
  clamping to `[min, max]` with `step` and `largeStep`, `format` / `parse`
  callbacks, three sizes, and a `FossNumberFieldStyle` for one-off overrides.
* `FossOtpField` is a segmented one-time-code field: a row of single-character
  slots over one hidden input, with typing, backspace, arrow, and paste (or
  platform one-time-code autofill) driving a shared value. It takes a required
  `length`, controlled (`value` + `onChanged`) or uncontrolled use, an
  `onCompleted` callback, two sizes, character `validation` (numeric default),
  optional `obscure` masking, optional `groups` separators, an `error` state,
  and a `FossOtpFieldStyle` for one-off overrides.
* `FossPopover` anchors an interactive floating surface to a trigger, opening on
  a preferred `side` / `align` and flipping to stay on screen. It is controlled
  (`open` + `onOpenChange`) or uncontrolled, with a `FossPopoverController` for
  imperative open / close / toggle, an optional `modal` scrim with focus trap,
  outside-tap and `Escape` dismiss, and a `FossPopoverStyle` for one-off
  overrides.
* `FossSkeleton` is a loading placeholder that stands in for content while it
  loads: a `muted`-filled box (or `FossSkeleton.circle` for avatars) with
  superellipse corners and a shimmer that sweeps on the `skeleton` motion token
  and stops under reduced motion. Size it to the content it replaces.
* `FossText` renders a string in a type step (`FossTextSize`) at one of four
  weights (`FossTextWeight`), with an optional semantic color role
  (`FossTextColor`) that uses the `foreground` role when unset. Named
  constructors (`FossText.body` / `.label` / `.title` / `.heading` / `.display`
  / `.caption`) cover the common roles, a `TextStyle` merges over the resolved
  style for a one-off, an opt-in `header` flag marks a true document heading for
  assistive technology, and the common `Text` props pass through.
* `FossToggle` is a two-state pressable button that holds an on / off state
  (`pressed` + `onPressedChanged`, null disables). It renders a label, a
  `leading` icon, or a square icon-only control, with `standard` and `outline`
  variants, three sizes, keyboard toggle, a focus ring, and a `FossToggleStyle`
  for one-off overrides.
* `FossToggleGroup` binds a set of toggles to one selection
  (`FossToggleGroup.single` / `.multiple`), propagating `variant` and `size` to
  every `FossToggleGroupItem`. The `outline` variant joins the items into a
  segmented bar with a shared border and rounded outer ends; `standard` spaces
  them. It supports horizontal or vertical `orientation`, group and per-item
  disable, and a `FossToggleGroupStyle` for one-off overrides.

### Improved

* `FossDrawer` now fades its content at whichever scroll edge still has more to
  show, cueing that the panel body scrolls.

### Fixed

* The default type scale now renders in the bundled Geist font in consumer
  apps. The family is referenced package-qualified, so text no longer fell back
  to the platform system font.

## 0.1.0

The first stable release. `fossui` ships 21 themeable, accessible components,
themed from one source and reached through a single import. It works under
`MaterialApp`, `CupertinoApp`, or a bare `WidgetsApp`, with no `FossApp` wrapper.
This cut also lands a documentation pass and a few public API renames for naming
consistency.

### Added

* `FossSince` annotation marks the version a public API arrived in. Everything in
  this release is unannotated; the marker starts appearing on APIs added after
  `0.1.0`.

### Changed

* Toast naming now lines up with the other variant enums. `FossToastType` is
  `FossToastVariant`, its `normal` case is `neutral`, and `FossToast` takes the
  variant through `variant:` rather than `type:`.
* The accessibility label parameter is spelled `semanticLabel` throughout.
  `FossAvatar`, `FossBadge`, `FossProgress`, `FossSwitch`, and `FossTooltip` drop
  the old `semanticsLabel` spelling to match the rest of the set.
* Picker callbacks line up on `onChanged`. `FossCombobox` and `FossMultiCombobox`
  report a pick through `onChanged` (was `onSelected`), matching `FossSelect` and
  the other form fields. `FossSelect.onChanged` narrows to `ValueChanged<T>`,
  since the field has no clear action and never reported null.
* `showFossToast` returns a `FossToastHandle` instead of a bare id. Call
  `.dismiss()` or `.update()` on it to control the toast, no `BuildContext`
  needed.
* `FossMultiSelect.selectionLabel` is now `selectionLabelBuilder`, matching the
  builder-parameter convention.
* `FossCheckboxGroupScope` and `FossRadioGroupScope` are no longer part of the
  public API; they were internal plumbing, never meant to be used directly.

### Improved

* API docs carry more for every component: a per-theme preview image, links to
  the documentation site and live playground, an explicit summary of what the
  component does and does not do, sidebar grouping by category, and cross-links
  between related components. Previews also show on hover over a constructor.
* Accessibility refinements: the slider stops announcing an unchanged value once
  it reaches either bound, the drawer names its route for screen readers, and the
  disabled switch drops the forbidden cursor for the standard pointer.
* Design fidelity: title-to-description spacing now tracks each surface (tighter on
  the alert and toast, looser on the dialog and drawer), every form error caption
  shares the deeper destructive-foreground red, the select trigger padding lines up
  with the other fields, the toast enter and exit ease over a longer beat with a
  lighter rear-card tint, the tabs indicator uses a symmetric ease, the alert
  action row keeps its full gap above the text, and checkbox and radio labels are
  medium weight.

### Fixed

* A single-select combobox no longer collapses to the chosen row when reopened;
  the full option list shows again.
* Tabs seeded with an `initialValue` that names a disabled or missing tab now
  fall back to the first enabled tab instead of leaving the panel blank.
* Fields and dialogs render correctly under a theme with a zero corner radius.
* Right-to-left fixes: the multi-select combobox placeholder and the select popup
  align to the reading-direction start rather than the physical left.
* A diagonal swipe on a toast dismisses it once instead of firing its dismiss
  twice.

## 0.1.0-beta.3

A quality pass over every component: accessibility, visual fidelity, touch
targets, and golden coverage. No new components, plus one additive theming API
for one-call rebrands.

### Added

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

### Added

* Initial package scaffold: structure, theming and component barrels, MIT
  license, and attribution NOTICE.

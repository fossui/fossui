# fossui

An open-source Flutter UI library, inspired by Cal.com's design system. One import gives you the theme system and every component.

```dart
import 'package:fossui/fossui.dart';
```

## Setup

Register the theme once, then read tokens through `context.fossTheme`. There is no `FossApp` wrapper.

- Material: `MaterialApp(theme: FossThemeData.light.toThemeData(), darkTheme: FossThemeData.dark.toThemeData())`.
- Non-Material: `FossTheme(data: FossThemeData.light, child: ...)`.

## Theme tokens

Read via `context.fossTheme`. Families:

- colors: 26 semantic roles, light and dark.
- radii: sm 6, md 8, lg 10, xl 14, xl2 16.
- spacing: unit 4; `context.fossTheme.spacing(2)` is 8.
- typography: xs, sm, base, lg, xl, xl2 (Geist).
- shadows: xs, sm, md, lg.
- motion: named durations in `context.fossTheme.motion`.

Each family resolves to a Dart type at the access site: colors `Color`, radii `double`, spacing `double`, typography `TextStyle`, shadows `List<BoxShadow>`, motion `Duration`.

## Components

All are `Foss`-prefixed. Variants and sizes are enums passed as named params; a single `style` object per component is the one-off override escape hatch. Icon slots take any `Widget`.

### Inputs

- FossAutocomplete: A text field whose dropdown filters a list of suggestions as you type.
- FossButton: A pressable button in the fossui style. (Variant: primary | secondary | outline | ghost | destructive | link. Size: sm | md | lg. Status: idle | loading | disabled)
  - controller FossButtonController(status)
  - style FossButtonStyle(backgroundColor, foregroundColor, side, borderRadius, padding, minHeight, textStyle, shadow, iconSize, gap, disabledOpacity)
- FossCalendar: A month grid for viewing and picking dates: a seven-column day grid under a month caption with previous and next navigation.
  - style FossCalendarStyle(dayTextStyle, weekdayTextStyle, captionTextStyle, dayForegroundColor, mutedForegroundColor, selectedColor, selectedForegroundColor, rangeColor, hoverColor, todayIndicatorColor, selectedTodayIndicatorColor, focusRingColor, chevronColor, dayRadius, cellSize)
- FossCheckbox: A checkbox: an independent on / off toggle that can also show an indeterminate state. (GroupVariant: plain | card)
  - group FossCheckboxGroup(children, values, onChanged, label, errorText, variant, enabled)
  - item FossCheckboxItem(value, label, description, enabled, style)
  - style FossCheckboxStyle(backgroundColor, checkedColor, checkColor, borderColor, shadow, boxSize, glyphSize, gap, labelStyle, descriptionStyle)
- FossChip: A compact pill carrying a value the user can pick or drop: a filter in a bar, a tag on a record, an entry in a multi-select field. (Variant: soft | outline. Size: sm | md)
  - style FossChipStyle(backgroundColor, foregroundColor, side, borderRadius, padding, minHeight, textStyle, iconSize, gap, disabledOpacity)
- FossCombobox: A text field with a filtered dropdown of predefined items, each carrying a check when picked.
  - item FossComboboxItem(value, label, icon, enabled)
  - style FossComboboxStyle(backgroundColor, borderColor, borderRadius, textStyle, shadow)
- FossDatePicker: A date field that opens a calendar in a modal dialog and shows the chosen date back in its trigger.
  - style FossDatePickerStyle(placeholderColor, gap)
- FossMultiCombobox: A combobox that holds several picks at once, shown as removable chips.
- FossMultiSelect: A pick-several-from-list control with no typing.
- FossNumberField: A numeric input flanked by a decrement and an increment button.
  - style FossNumberFieldStyle(backgroundColor, borderColor, borderRadius, minHeight, textStyle, iconSize, stepperHoverColor, shadow)
- FossOtpField: A segmented one-time-code field: a row of single-character slots over one hidden input. (Size: md | lg)
  - style FossOtpFieldStyle(backgroundColor, borderColor, borderRadius, slotSize, textStyle, gap, shadow, separatorColor, separatorSize)
- FossRadio: A single option within a [FossRadioGroup]. (GroupVariant: plain | card)
  - group FossRadioGroup(children, groupValue, onChanged, label, errorText, variant, enabled)
  - style FossRadioStyle(backgroundColor, checkedColor, dotColor, borderColor, shadow, circleSize, dotSize, gap, labelStyle, descriptionStyle)
- FossSelect: A pick-from-list control with no typing. (Size: sm | md | lg)
  - item FossSelectItem(value, label, icon, enabled)
  - style FossSelectStyle(backgroundColor, foregroundColor, placeholderColor, borderColor, borderRadius, padding, minHeight, textStyle, shadow, iconSize, gap)
- FossSlider: A horizontal slider: a track with a draggable thumb that picks a [double] from `[min, max]`.
  - style FossSliderStyle(trackColor, rangeColor, thumbColor, borderColor, shadow, trackHeight, thumbSize)
- FossSwitch: An instant on / off toggle: a pill track with a sliding thumb that commits a boolean the moment it is flipped.
  - style FossSwitchStyle(activeTrackColor, inactiveTrackColor, thumbColor, shadow, trackWidth, trackHeight, thumbSize)
- FossTextField: A text field in the fossui style. (Size: sm | md | lg)
  - style FossTextFieldStyle(backgroundColor, borderColor, borderRadius, contentPadding, minHeight, textStyle, labelStyle, helperStyle, iconSize, gap, shadow)
- FossTimePicker: A time field that opens scrolling wheels in a modal dialog and shows the chosen time back in its trigger.
  - style FossTimePickerStyle(placeholderColor, gap, itemExtent, visibleItemCount, highlightColor)
- FossToggle: A button that holds a two-state pressed look: tap it to turn it on, tap again to release. It is the control behind a formatting button (bold, italic) in a toolbar, sized and shaped like a FossButton but carrying a binary on / off state. (Variant: standard | outline. Size: sm | md | lg)
  - style FossToggleStyle(backgroundColor, foregroundColor, side, borderRadius, cornerRadius, padding, minHeight, textStyle, shadow, iconSize, gap, disabledOpacity)
  - item FossToggleGroupItem(value, leading, child, semanticLabel, enabled)
  - group FossToggleGroup.single(children, value, onChanged, variant, size, orientation, enabled, style)
  - group FossToggleGroup.multiple(children, value, onChanged, variant, size, orientation, enabled, style)
  - style FossToggleGroupStyle(gap, connectedBorderColor)

### Feedback

- FossAlert: A static inline callout: a leading status glyph, a title, an optional description, and optional actions, on a bordered surface tinted by the [variant]. (Variant: neutral | info | success | warning | error)
  - style FossAlertStyle(backgroundColor, borderColor, iconColor, borderRadius, titleStyle, descriptionStyle)
- FossBadge: A compact status pill: a content-hugging, single-line label that tags a count, a state, or a category. Static and non-interactive. (Variant: primary | secondary | outline | destructive | info | success | warning | error. Size: sm | md | lg)
  - style FossBadgeStyle(backgroundColor, borderColor, foregroundColor, borderRadius, labelStyle)
- FossMeter: A static gauge: a full-width track with a leading fill that shows one measurement inside a fixed range (disk used, a quota, a rating). It is the display-only sibling of the progress bar: bounded and non-interactive.
  - style FossMeterStyle(trackColor, fillColor, labelStyle, valueStyle)
- FossProgress: A determinate progress bar: a full-width track with a leading fill that grows from the start to show how far a long task has run. It is static and non-interactive.
  - style FossProgressStyle(trackColor, fillColor, labelStyle, valueLabelStyle)
- FossSkeleton: A placeholder that stands in for content while it loads.
- FossSpinner: A circular loading indicator: an open arc that spins continuously.

### Overlays

- FossAlertDialog: A non-dismissible modal that interrupts to require a decision.
  - showFossAlertDialog(context, builder, presentation, barrierLabel, useRootNavigator)
  - style FossAlertDialogStyle(backgroundColor, borderColor, borderRadius, maxWidth, shadows, titleStyle, descriptionStyle)
- FossDialog: A modal surface with slots for a title, description, body, and actions, plus a default close affordance. Presents as a bottom sheet by default, or a centered card via [presentation]. (FooterVariant: bare | filled. Presentation: centered | bottomSheet)
  - showFossDialog(context, builder, presentation, barrierDismissible, barrierLabel, useRootNavigator)
  - style FossDialogStyle(backgroundColor, borderColor, borderRadius, maxWidth, shadows, titleStyle, descriptionStyle)
- FossDrawer: An edge-anchored modal panel with slots for a title, description, body, and actions, plus an optional drag handle and close affordance. (Side: bottom | top | left | right. Variant: rounded | straight. FooterVariant: bare | filled)
  - showFossDrawer(context, builder, side, barrierDismissible, barrierLabel, useRootNavigator)
  - style FossDrawerStyle(backgroundColor, borderColor, borderRadius, shadows, titleStyle, descriptionStyle)
- FossPopover: An interactive floating panel anchored to a [child] trigger. Tapping the trigger opens a surface built by [builder] on the preferred [side] and [align]; the surface flips and clamps to stay on screen, and an outside tap or `Escape` dismisses it (when [dismissible]). (Side: top | bottom | left | right. Align: start | center | end)
  - controller FossPopoverController()
  - style FossPopoverStyle(backgroundColor, borderColor, foregroundColor, borderRadius, padding, shadows)
- FossToast: One transient notification. Enqueue it with `showFossToast` or a `FossToastController`; the surface stays on the `popover` role for every [variant], which tints only the leading glyph. (Variant: neutral | loading | info | success | warning | error)
  - showFossToast(context, toast)
  - style FossToastStyle(backgroundColor, borderColor, borderRadius, titleStyle, descriptionStyle)
  - entry FossToastEntry(id, toast)
  - controller FossToastController()
- FossToaster: Hosts transient toasts over its [child]. Mount it once near the app root, above everything that needs to raise a toast.
- FossTooltip: Wraps a [child] trigger and shows a small floating hint next to it on hover, keyboard focus, or long-press, dismissing on exit, blur, `Escape`, or after [hideDelay]. (Side: top | bottom | left | right)
  - style FossTooltipStyle(backgroundColor, borderColor, foregroundColor, borderRadius, shadows, textStyle)

### Layout

- FossAccordion: A stack of collapsible sections: each header toggles a panel of content open or closed, with a rotating chevron and an animated height.
  - item FossAccordionItem(value, title, child, enabled)
  - style FossAccordionStyle(titleTextStyle, panelTextStyle, chevronColor, dividerColor, headerPadding, panelPadding)
- FossAvatar: A user's stand-in: a fixed-size circle that shows a profile [image] and falls back to a [fallback] glyph (usually initials) while the image loads, when it is absent, or when it fails to load. Static and non-interactive. (Size: xs | sm | md | lg | xl | xl2)
  - style FossAvatarStyle(backgroundColor, fallbackColor, fallbackTextStyle)
- FossCard: A static content container: a bordered, rounded surface that groups an optional header (title, description, trailing action), an optional content body, and an optional footer. Every slot is optional and content-agnostic; the surface renders, it does not respond.
  - style FossCardStyle(backgroundColor, borderColor, borderRadius, shadows, titleStyle, descriptionStyle)
- FossListTile: A row in a list: an optional [leading] widget, a [title] over an optional [subtitle], and an optional [trailing] widget. A settings screen or an account list is mostly this one row repeated. (Variant: filled | plain)
  - style FossListTileStyle(backgroundColor, padding, gap, minHeight, borderRadius, titleStyle, subtitleStyle, iconSize)
- FossPagination: A row that walks through pages: a previous control, a windowed run of page numbers with an ellipsis wherever the run is cut, and a next control.
  - style FossPaginationStyle(gap, buttonSize, activeVariant, inactiveVariant, ellipsisColor, ellipsisWidth)
- FossSeparator: A hairline rule that divides content along a row or a column. Static and non-interactive: a 1 logical pixel line in the `border` role. (Orientation: horizontal | vertical)
- FossTabs: A row or column of tabs that toggle between sibling panels, with an animated indicator marking the active tab. (Variant: segmented | underline. Orientation: horizontal | vertical)
  - style FossTabsStyle(barColor, indicatorColor, indicatorShadow, hoverColor, activeForeground, inactiveForeground, labelStyle)
  - item FossTab(value, label, icon, content, enabled)

### Typography

- FossText: On-brand text in one line. [FossText] renders a string in a [FossTypography] step at one of four weights, resolving the type scale and the bundled font from `context.fossTheme` so the text stays on theme without reaching into the tokens. (Size: xs | sm | base | lg | xl | xl2. Weight: regular | medium | semibold | bold. Color: foreground | mutedForeground | primary | destructive)

## Common mistakes

The wrong form, then the fix: the errors a model makes writing fossui without the API in front of it.

- FossAccordion: `FossAccordion(children: [FossAccordionItem(title: Text('One'), child: body)])` -> `FossAccordion(children: [FossAccordionItem(value: 'one', title: const Text('One'), child: body)])`
- FossAccordion: `FossAccordion(value: open, initialValue: {'one'}, children: items)` -> `FossAccordion(value: open, onValueChanged: (v) => setState(() => open = v), children: items)`
- FossAccordion: `FossAccordion(headerPadding: EdgeInsets.all(12), children: items)` -> `FossAccordion(style: const FossAccordionStyle(headerPadding: EdgeInsets.all(12)), children: items)`
- FossAlert: `FossAlert(variant: 'error', title: Text('Failed'))` -> `FossAlert(variant: FossAlertVariant.error, title: const Text('Failed'))`
- FossAlert: `FossAlert(color: Colors.red, title: Text('Failed'))` -> `FossAlert(variant: FossAlertVariant.error, title: const Text('Failed'))`
- FossAlert: `FossAlert(variant: FossAlertVariant.neutral, title: Text('Note'))  // expecting an icon` -> `FossAlert(variant: FossAlertVariant.info, title: const Text('Note'))`
- FossAlert: `FossAlert(title: Text('Retry'), onTap: _retry)` -> `FossAlert(title: const Text('Save failed'), actions: [FossButton(onPressed: _retry, child: const Text('Retry'))])`
- FossAlertDialog: `FossAlertDialog(title: Text('Delete?'))` -> `FossAlertDialog(title: const Text('Delete?'), actions: [FossButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])`
- FossAlertDialog: `showFossDialog(context: context, builder: (context) => FossAlertDialog(actions: [ok]))` -> `showFossAlertDialog(context: context, builder: (context) => FossAlertDialog(actions: [ok]))`
- FossAlertDialog: `FossAlertDialog(showCloseButton: false, actions: [ok])` -> `FossAlertDialog(actions: [ok])`
- FossAlertDialog: `FossAlertDialog(style: const FossDialogStyle(maxWidth: 640), actions: [ok])` -> `FossAlertDialog(style: const FossAlertDialogStyle(maxWidth: 640), actions: [ok])`
- FossAutocomplete: `FossAutocomplete(items: const [FossComboboxItem(value: 'a', label: 'Apple')], onChanged: _set)` -> `FossAutocomplete(items: const ['Apple', 'Banana'], onChanged: _set)`
- FossAutocomplete: `FossAutocomplete(value: fruit, items: items, onSelected: _set)` -> `FossAutocomplete(items: items, onChanged: (value) => setState(() => fruit = value))`
- FossAutocomplete: `FossAutocomplete(size: 'lg', items: items)` -> `FossAutocomplete(size: FossTextFieldSize.lg, items: items)`
- FossAutocomplete: `FossAutocomplete(items: items, borderRadius: 12)` -> `FossAutocomplete(items: items, style: const FossComboboxStyle(borderRadius: 12))`
- FossAvatar: `FossAvatar(image: 'https://example.com/v.png')` -> `FossAvatar(image: NetworkImage('https://example.com/v.png'), fallback: const Text('VL'))`
- FossAvatar: `FossAvatar(image: img, size: 40)` -> `FossAvatar(image: img, size: FossAvatarSize.xl)`
- FossAvatar: `FossAvatar(image: img, backgroundColor: Colors.grey)` -> `FossAvatar(image: img, style: const FossAvatarStyle(fallbackColor: Color(0xFFE5E7EB)))`
- FossAvatar: `FossAvatar(image: img, onTap: openProfile)` -> `GestureDetector(onTap: openProfile, child: FossAvatar(image: img))`
- FossBadge: `FossBadge(label: 'New')` -> `FossBadge(label: const Text('New'))`
- FossBadge: `FossBadge(label: Text('New'), variant: 'success')` -> `FossBadge(label: const Text('New'), variant: FossBadgeVariant.success)`
- FossBadge: `FossBadge(label: Text('New'), size: 'lg')` -> `FossBadge(label: const Text('New'), size: FossBadgeSize.lg)`
- FossBadge: `FossBadge(label: Text('New'), backgroundColor: Colors.green)` -> `FossBadge(label: const Text('New'), variant: FossBadgeVariant.success)`
- FossButton: `FossButton(color: Colors.red, onPressed: _delete, child: Text('Delete'))` -> `FossButton(variant: FossButtonVariant.destructive, onPressed: _delete, child: const Text('Delete'))`
- FossButton: `FossButton(variant: 'primary', onPressed: _save, child: Text('Save'))` -> `FossButton(variant: FossButtonVariant.primary, onPressed: _save, child: const Text('Save'))`
- FossButton: `FossButton.icon(icon: Icon(LucideIcons.x), onPressed: _close)` -> `FossButton.icon(icon: const Icon(LucideIcons.x), semanticLabel: 'Close', onPressed: _close)`
- FossCalendar: `FossCalendar.single(selected: day, onSelected: (d) {}, firstDayOfWeek: 0)` -> `FossCalendar.single(selected: day, onSelected: (d) {}, firstDayOfWeek: DateTime.sunday)`
- FossCalendar: `FossCalendar.range(selected: DateRange(a, b), onSelected: (r) {})` -> `FossCalendar.range(selected: FossDateRange(start: a, end: b), onSelected: (r) {})`
- FossCalendar: `FossCalendar.single(onSelected: (d) => setState(() => day = d))` -> `FossCalendar.single(selected: day, onSelected: (d) => setState(() => day = d))`
- FossCard: `Container(decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(12)), child: body)` -> `FossCard(content: body)`
- FossCard: `FossCard(content: body, color: Colors.white, borderRadius: 16)` -> `FossCard(content: body, style: const FossCardStyle(backgroundColor: Color(0xFFFFFFFF), borderRadius: 16))`
- FossCard: `FossCard(content: Padding(padding: EdgeInsets.all(24), child: body))` -> `FossCard(content: body)`
- FossCard: `FossCard(child: body)` -> `FossCard(content: body)`
- FossCheckbox: `FossCheckbox(value: accepted, onChanged: (v) {}, color: Colors.blue)` -> `FossCheckbox(value: accepted, onChanged: (v) => setState(() => accepted = v), style: const FossCheckboxStyle(checkedColor: Color(0xFF2563EB)))`
- FossCheckbox: `FossCheckbox(value: true, onChanged: (v) {}, tristate: true)` -> `FossCheckbox(value: null, onChanged: (v) {})`
- FossCheckbox: `FossCheckboxItem(value: 'a', label: 'A')` -> `FossCheckboxGroup<String>(values: selected, onChanged: (next) => setState(() => selected = next), children: const [FossCheckboxItem(value: 'a', label: 'A')])`
- FossCheckbox: `FossCheckboxGroup(variant: 'card', values: {}, children: [...])` -> `FossCheckboxGroup(variant: FossCheckboxGroupVariant.card, values: {}, children: [...])`
- FossChip: `FossChip(label: 'Design', onSelected: (v) {})` -> `FossChip(label: const Text('Design'), onSelected: (v) {})`
- FossChip: `FossChip(label: const Text('Design'), onSelected: (v) => on = v)` -> `FossChip(label: const Text('Design'), selected: on, onSelected: (v) => setState(() => on = v))`
- FossChip: `FossChip(label: const Text('Design'), backgroundColor: Colors.green)` -> `FossChip(label: const Text('Design'), style: FossChipStyle(backgroundColor: WidgetStatePropertyAll(Color(0xFF16A34A))))`
- FossCombobox: `FossCombobox<String>(value: team, items: [FossSelectItem(value: 'a', label: 'Design')], onSelected: _set)` -> `FossCombobox<String>(value: team, items: const [FossComboboxItem(value: 'a', label: 'Design')], onSelected: _set)`
- FossCombobox: `FossCombobox<String>(value: team, items: items, onChanged: _set)` -> `FossCombobox<String>(value: team, items: items, onSelected: (v) => setState(() => team = v))`
- FossCombobox: `FossCombobox<String>(items: ['Design', 'Eng'], onSelected: _set)` -> `FossCombobox<String>(items: const [FossComboboxItem(value: 'design', label: 'Design'), FossComboboxItem(value: 'eng', label: 'Engineering')], onSelected: _set)`
- FossCombobox: `FossCombobox<String>(size: 'md', items: items)` -> `FossCombobox<String>(size: FossTextFieldSize.md, items: items)`
- FossDatePicker: `FossDatePicker.single(selected: day, onSelected: (d) {}, presentation: 'card')` -> `FossDatePicker.single(selected: day, onSelected: (d) {}, presentation: FossDialogPresentation.card)`
- FossDatePicker: `FossDatePicker.single(selected: day, onSelected: (d) {}, enabled: () {})` -> `FossDatePicker.single(selected: day, onSelected: (d) {}, enabled: false)`
- FossDatePicker: `FossDatePicker.range(selected: FossDateRange(start: a, end: b), onSelected: (r) {}, format: DateFormat.yMd().format)` -> `FossDatePicker.range(selected: FossDateRange(start: a, end: b), onSelected: (r) {}, format: (r) => '${r.start} to ${r.end}')`
- FossDialog: `showDialog(context: context, builder: (_) => FossDialog(title: Text('Hi')))` -> `showFossDialog<void>(context: context, builder: (context) => const FossDialog(title: Text('Hi')))`
- FossDialog: `FossDialog(presentation: 'centered', title: Text('Hi'))` -> `showFossDialog(context: context, presentation: FossDialogPresentation.centered, builder: (context) => const FossDialog(title: Text('Hi')))`
- FossDialog: `FossDialog(borderRadius: 20, title: Text('Hi'))` -> `showFossDialog<void>(context: context, builder: (context) => const FossDialog(title: Text('Hi'), style: FossDialogStyle(borderRadius: 20)))`
- FossDialog: `FossButton(onPressed: () => Navigator.pop(context), child: Text('Save'))` -> `FossButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))`
- FossDrawer: `FossDrawer(side: FossDrawerSide.right, content: Filters())` -> `showFossDrawer(context: context, side: FossDrawerSide.right, builder: (context) => const FossDrawer(content: Filters()))`
- FossDrawer: `showModalBottomSheet(context: context, builder: (_) => FossDrawer(content: Body()))` -> `showFossDrawer(context: context, builder: (context) => const FossDrawer(content: Body()))`
- FossDrawer: `FossDrawer(variant: 'straight', content: Body())` -> `FossDrawer(variant: FossDrawerVariant.straight, content: const Body())`
- FossDrawer: `FossDrawer(borderRadius: 12, content: Body())` -> `FossDrawer(content: const Body(), style: const FossDrawerStyle(borderRadius: 12))`
- FossDrawer: `FossSheet(content: Body())` -> `showFossDrawer(context: context, builder: (context) => const FossDrawer(content: Body()))`
- FossListTile: `FossListTile(title: 'Notifications')` -> `FossListTile(title: const Text('Notifications'))`
- FossListTile: `FossListTile(title: const Text('Sync'), onTap: null) // to disable` -> `FossListTile(title: const Text('Sync'), enabled: false, onTap: startSync)`
- FossListTile: `FossCard(content: FossListTile(title: const Text('Profile')))` -> `FossCard(content: FossListTile(title: const Text('Profile'), variant: FossListTileVariant.plain))`
- FossMeter: `FossMeter(value: 40, onChanged: (v) {})` -> `FossMeter(value: 40, label: 'Storage')`
- FossMeter: `FossMeter(value: used, fillColor: Colors.green)` -> `FossMeter(value: used, style: const FossMeterStyle(fillColor: Color(0xFF16A34A)))`
- FossMeter: `FossMeter(value: 3, max: 5, formatValue: (v) => '$v')` -> `FossMeter(value: 3, max: 5, formatValue: (value, min, max) => '$value of $max')`
- FossMultiCombobox: `FossMultiCombobox<String>(value: tag, items: items, onSelected: _set)` -> `FossMultiCombobox<String>(values: tags, items: items, onSelected: (v) => setState(() => tags = v))`
- FossMultiCombobox: `FossMultiCombobox<String>(values: tags, items: [FossSelectItem(value: 'a', label: 'Design')], onSelected: _set)` -> `FossMultiCombobox<String>(values: tags, items: const [FossComboboxItem(value: 'a', label: 'Design')], onSelected: _set)`
- FossMultiCombobox: `FossMultiCombobox<String>(values: tags, items: items, onChanged: _set)` -> `FossMultiCombobox<String>(values: tags, items: items, onSelected: _set)`
- FossMultiCombobox: `FossMultiCombobox<String>(size: 'sm', items: items, values: tags)` -> `FossMultiCombobox<String>(size: FossTextFieldSize.sm, items: items, values: tags)`
- FossMultiSelect: `FossMultiSelect<String>(value: tag, items: items, onChanged: _set)` -> `FossMultiSelect<String>(values: tags, items: items, onChanged: (next) => setState(() => tags = next))`
- FossMultiSelect: `FossMultiSelect<String>(items: ['Design', 'Eng'], values: tags, onChanged: _set)` -> `FossMultiSelect<String>(items: const [FossSelectItem(value: 'design', label: 'Design'), FossSelectItem(value: 'eng', label: 'Engineering')], values: tags, onChanged: _set)`
- FossMultiSelect: `onChanged: (next) { tags.add(value); }` -> `onChanged: (next) => setState(() => tags = next)`
- FossMultiSelect: `FossMultiSelect<String>(size: 'lg', items: items)` -> `FossMultiSelect<String>(size: FossSelectSize.lg, items: items)`
- FossNumberField: `FossNumberField(value: qty, initialValue: 1, onChanged: (v) {})` -> `FossNumberField(value: qty, onChanged: (v) => setState(() => qty = v))`
- FossNumberField: `FossNumberField(value: qty, onChanged: (v) {}, size: 'lg')` -> `FossNumberField(value: qty, onChanged: (v) {}, size: FossTextFieldSize.lg)`
- FossNumberField: `FossNumberField(value: qty, onChanged: (v) {}, borderRadius: 8)` -> `FossNumberField(value: qty, onChanged: (v) {}, style: const FossNumberFieldStyle(borderRadius: 8))`
- FossOtpField: `FossOtpField(length: 6, validation: 'numeric')` -> `FossOtpField(length: 6, validation: FossOtpValidation.numeric)`
- FossOtpField: `FossOtpField(length: 6, size: 'lg')` -> `FossOtpField(length: 6, size: FossOtpFieldSize.lg)`
- FossOtpField: `FossOtpField(length: 6, groups: [2, 2])` -> `FossOtpField(length: 6, groups: [3, 3])`
- FossPagination: `FossPagination(page: 0, pageCount: 10, onPageChanged: (p) {})` -> `FossPagination(page: 1, pageCount: 10, onPageChanged: (p) => setState(() => page = p))`
- FossPagination: `IntrinsicWidth(child: FossPagination(page: 1, pageCount: 10, onPageChanged: (p) {}))` -> `SizedBox(width: 420, child: FossPagination(page: 1, pageCount: 10, onPageChanged: (p) {}))`
- FossPagination: `FossPagination(page: page, pageCount: 24, siblingCount: 4, onPageChanged: (p) {}) // expecting 4 either side on a phone` -> `FossPagination(page: page, pageCount: 24, siblingCount: 4, onPageChanged: (p) {}) // shows fewer when the width cannot hold them`
- FossPopover: `FossPopover(borderRadius: 12, builder: _menu, child: _trigger)` -> `FossPopover(style: const FossPopoverStyle(borderRadius: 12), builder: _menu, child: _trigger)`
- FossPopover: `FossPopover(side: 'top', builder: _menu, child: _trigger)` -> `FossPopover(side: FossPopoverSide.top, builder: _menu, child: _trigger)`
- FossPopover: `FossPopover(builder: (_) => const Text('Copy'), child: icon)` -> `FossTooltip(message: 'Copy', child: icon)`
- FossProgress: `FossProgress(value: 40)` -> `FossProgress(value: 0.4, valueLabel: '40%')`
- FossProgress: `FossProgress(value: 0.4, valueLabel: 40)` -> `FossProgress(value: 0.4, valueLabel: '40%')`
- FossProgress: `FossProgress()  // no known fraction, wanted a spinner` -> `const FossSpinner()`
- FossProgress: `FossProgress(value: 0.4, fillColor: Colors.green)` -> `FossProgress(value: 0.4, style: const FossProgressStyle(fillColor: Color(0xFF16A34A)))`
- FossRadio: `FossRadio(value: 'a', selected: true, onChanged: (v) {})` -> `FossRadioGroup<String>(groupValue: plan, onChanged: (v) => setState(() => plan = v), children: const [FossRadio(value: 'a', label: 'A')])`
- FossRadio: `FossRadio<String>(value: 'a', label: 'A')  // rendered on its own` -> `FossRadioGroup<String>(groupValue: plan, onChanged: (v) {}, children: const [FossRadio(value: 'a', label: 'A')])`
- FossRadio: `FossRadioGroup(variant: 'card', children: [...])` -> `FossRadioGroup(variant: FossRadioGroupVariant.card, children: [...])`
- FossRadio: `FossRadio(value: 'a', label: 'A', color: Colors.green)` -> `FossRadio(value: 'a', label: 'A', style: const FossRadioStyle(checkedColor: Color(0xFF16A34A)))`
- FossSelect: `FossSelect<String>(value: plan, items: ['Monthly', 'Yearly'], onChanged: _set)` -> `FossSelect<String>(value: plan, items: const [FossSelectItem(value: 'monthly', label: 'Monthly'), FossSelectItem(value: 'yearly', label: 'Yearly')], onChanged: _set)`
- FossSelect: `FossSelect<String>(values: picks, items: items, onChanged: _set)` -> `FossSelect<String>(value: pick, items: items, onChanged: _set)`
- FossSelect: `FossSelect<String>(size: 'sm', items: items)` -> `FossSelect<String>(size: FossSelectSize.sm, items: items)`
- FossSelect: `FossSelect<String>(borderRadius: 12, items: items)` -> `FossSelect<String>(style: const FossSelectStyle(borderRadius: 12), items: items)`
- FossSeparator: `FossSeparator(color: Colors.grey, thickness: 2)` -> `FossSeparator()`
- FossSeparator: `FossSeparator(orientation: 'vertical')` -> `FossSeparator(orientation: FossSeparatorOrientation.vertical)`
- FossSeparator: `Row(children: [a, FossSeparator(orientation: FossSeparatorOrientation.vertical), b])` -> `SizedBox(height: 24, child: Row(children: [a, FossSeparator(orientation: FossSeparatorOrientation.vertical), b]))`
- FossSkeleton: `FossSkeleton(style: FossSkeletonStyle(color: Colors.grey))` -> `FossSkeleton(width: 200, height: 16)`
- FossSkeleton: `FossSkeleton(width: 40, height: 40)` -> `FossSkeleton.circle(size: 40)`
- FossSkeleton: `FossSkeleton()` -> `FossSkeleton(width: 120, height: 20)`
- FossSlider: `FossSlider(value: v, onChanged: (x) {}, activeColor: Colors.blue)` -> `FossSlider(value: v, onChanged: (x) {}, style: const FossSliderStyle(rangeColor: Color(0xFF2563EB)))`
- FossSlider: `FossSlider(value: v, onChanged: (x) {}, divisions: 5.0)` -> `FossSlider(value: v, onChanged: (x) {}, divisions: 5)`
- FossSlider: `FossSlider(value: 40, onChanged: (x) {}, min: 100, max: 0)` -> `FossSlider(value: 40, onChanged: (x) {}, min: 0, max: 100)`
- FossSlider: `FossSlider(value: v, onChanged: null)  // meant to be interactive` -> `FossSlider(value: v, onChanged: (x) => setState(() => v = x))`
- FossSpinner: `FossSpinner(value: 0.4)` -> `FossProgress(value: 0.4)`
- FossSpinner: `FossSpinner(size: '18')` -> `const FossSpinner(size: 18)`
- FossSpinner: `FossSpinner(style: FossSpinnerStyle(color: Colors.white))` -> `const FossSpinner(color: Color(0xFFFFFFFF))`
- FossSwitch: `FossSwitch(value: on, onChanged: (v) {}, enabled: false)` -> `FossSwitch(value: on, onChanged: null)`
- FossSwitch: `FossSwitch(value: on, onChanged: (v) {}, activeColor: Colors.green)` -> `FossSwitch(value: on, onChanged: (v) {}, style: const FossSwitchStyle(activeTrackColor: Color(0xFF16A34A)))`
- FossSwitch: `FossSwitch(value: on, onChanged: (v) {}, label: 'Wi-Fi')` -> `Row(children: [const Text('Wi-Fi'), FossSwitch(value: on, semanticLabel: 'Wi-Fi', onChanged: (v) {})])`
- FossSwitch: `FossSwitch(onChanged: (v) {})` -> `FossSwitch(value: wifiOn, onChanged: (v) {})`
- FossTabs: `FossTabs(tabs: [Tab(text: 'Home'), Tab(text: 'Settings')])` -> `FossTabs<String>(tabs: const [FossTab(value: 'home', label: 'Home'), FossTab(value: 'settings', label: 'Settings')])`
- FossTabs: `FossTabs<String>(tabs: tabs, variant: 'underline')` -> `FossTabs<String>(tabs: tabs, variant: FossTabsVariant.underline)`
- FossTabs: `FossTabs<String>(value: selected, tabs: tabs)` -> `FossTabs<String>(value: selected, onChanged: (v) => setState(() => selected = v), tabs: tabs)`
- FossTabs: `FossTabs<String>(tabs: tabs, indicatorColor: Colors.green)` -> `FossTabs<String>(tabs: tabs, style: const FossTabsStyle(indicatorColor: Color(0xFF10B981)))`
- FossText: `FossText('Hello', size: 'lg', weight: 'bold')` -> `FossText('Hello', size: FossTextSize.lg, weight: FossTextWeight.bold)`
- FossText: `FossText.title('Title', color: Color(0xFF2563EB))` -> `FossText.title('Title', color: FossTextColor.primary)`
- FossText: `Text('Hello', style: context.fossTheme.typography.lg)` -> `FossText('Hello', size: FossTextSize.lg)`
- FossText: `FossText('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))` -> `FossText.display('Settings')`
- FossTextField: `FossTextField(decoration: InputDecoration(labelText: 'Email', hintText: 'you@x.com'))` -> `FossTextField(label: 'Email', hintText: 'you@x.com')`
- FossTextField: `FossTextField(size: 'lg', label: 'Name')` -> `FossTextField(size: FossTextFieldSize.lg, label: 'Name')`
- FossTextField: `FossTextField(maxLines: 5, leading: const Icon(LucideIcons.mail))` -> `FossTextField(maxLines: 5, minLines: 3)`
- FossTextField: `FossTextField(label: 'Search', borderRadius: 999)` -> `FossTextField(label: 'Search', style: const FossTextFieldStyle(borderRadius: 999))`
- FossTimePicker: `FossTimePicker(value: const TimeOfDay(hour: 9, minute: 30), onChanged: (t) {})` -> `FossTimePicker(value: const FossTimeOfDay(hour: 9, minute: 30), onChanged: (t) {})`
- FossTimePicker: `FossTimePicker(value: time, onChanged: (t) {}, onOpenChange: (open) => readWheel())` -> `FossTimePicker(value: time, onChanged: (t) => setState(() => time = t))`
- FossTimePicker: `FossTimePicker(value: time, onChanged: (t) {}, minuteStep: 7)` -> `FossTimePicker(value: time, onChanged: (t) {}, minuteStep: 5)`
- FossToast: `Widget build(BuildContext context) => const FossToast(title: Text('Saved'));` -> `showFossToast(context, const FossToast(title: Text('Saved')));`
- FossToast: `FossToast(variant: 'success', title: Text('Saved'))` -> `FossToast(variant: FossToastVariant.success, title: Text('Saved'))`
- FossToast: `const FossToast(title: Text('Saved'), color: Colors.green)` -> `const FossToast(variant: FossToastVariant.success, title: Text('Saved'))`
- FossToast: `showFossToast(context, const FossToast(variant: FossToastVariant.loading, duration: Duration(seconds: 2)))` -> `final id = showFossToast(context, const FossToast(variant: FossToastVariant.loading, title: Text('Saving'))); // later: FossToastScope.of(context).update(id, const FossToast(variant: FossToastVariant.success, title: Text('Saved')));`
- FossToaster: `showFossToast(context, const FossToast(title: Text('Saved'))); // no FossToaster mounted` -> `runApp(FossToaster(child: MyApp())); // then anywhere below: showFossToast(context, const FossToast(title: Text('Saved')));`
- FossToaster: `FossToaster(controller: myController, child: MyApp())` -> `FossToaster(child: MyApp())`
- FossToaster: `Scaffold(body: FossToaster(child: content)) // per-screen` -> `FossToaster(child: MaterialApp(home: HomeScreen()))`
- FossToggle: `FossToggle(pressed: bold, onPressedChanged: (v) {}, variant: 'outline')` -> `FossToggle(pressed: bold, onPressedChanged: (v) {}, variant: FossToggleVariant.outline)`
- FossToggle: `FossToggle(pressed: bold, onPressedChanged: (v) {}, enabled: false)` -> `FossToggle(pressed: bold, onPressedChanged: null)`
- FossToggle: `FossToggle(pressed: on, onPressedChanged: (v) {}, child: const Icon(LucideIcons.bold))` -> `FossToggle(pressed: on, onPressedChanged: (v) {}, semanticLabel: 'Bold', child: const Icon(LucideIcons.bold))`
- FossTooltip: `FossTooltip(message: 'Copy link') // no child` -> `FossTooltip(message: 'Copy link', child: FossButton(onPressed: copy, child: const Icon(LucideIcons.copy)))`
- FossTooltip: `FossTooltip(message: const Text('Copy'), child: button)` -> `FossTooltip(message: 'Copy', child: button)`
- FossTooltip: `FossTooltip(side: 'bottom', message: 'More', child: button)` -> `FossTooltip(side: FossTooltipSide.bottom, message: 'More', child: button)`
- FossTooltip: `FossTooltip(message: 'Undo', child: FossButton(onPressed: undo, child: const Text('Undo')))` -> `FossButton(onPressed: undo, child: const Text('Undo')) // a tappable action does not belong in a tooltip`

## Links

- Homepage: https://fossui.org
- License: MIT (see NOTICE for attribution)

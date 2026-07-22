import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/select/foss_select.dart';
import 'package:fossui/src/components/text_field/foss_text_field.dart';
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part '_foss_combobox_field.dart';
part '_foss_combobox_popup.dart';
part '_foss_multi_combobox_field.dart';
part 'foss_combobox_item.dart';
part 'foss_combobox_style.dart';

const double _disabledOpacity = 0.64;
const double _iconSize = 18;
const double _affixOpacity = 0.8;
const double _popupOffset = 4;
const double _popupMargin = 8;
const double _popupMaxHeight = 368;
const double _rowMinHeight = 32;
const double _indicatorColumn = 16;
const double _openScale = 0.96;
const double _removeGlyphSize = 16;

// Minimum touch region for the trailing affixes and the chip remove button.
// The region expands past the small glyph without growing its visual footprint.
const double _minHitTarget = 48;

/// Default empty-state caption when a query matches nothing.
const String _defaultEmptyText = 'No items found.';

// The chips input text selection uses the ring color at a low alpha, and the
// placeholder sits at 72% of the muted-foreground alpha.
const double _focusRingOpacity = 0.24;
const double _placeholderOpacity = 0.72;

// The chips label tightens its line height to 18px against the 16px base, to
// match the single-line field label.
const double _labelLineHeight = 18 / 16;

/// Default filter: a case-insensitive substring match of the query against the
/// option label.
bool _defaultFilter(String label, String query) =>
    label.toLowerCase().contains(query.toLowerCase());

/// {@category Inputs}
/// {@template foss.combobox.preview}
/// <img src="https://fossui.org/components/combobox/overview/light.png"
///   alt="FossCombobox, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/combobox/overview/dark.png"
///   alt="FossCombobox, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [combobox documentation ↗](https://fossui.org/docs/components/combobox) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/combobox/fosscombobox/playground).
/// {@endtemplate}
///
/// A text field whose dropdown filters a list of suggestions as you type.
///
/// The value is the field string, reported through [onChanged]; picking a
/// suggestion writes its text into the field. The [items] are hints, not a
/// constraint, so the field accepts any typed value. There is no selection
/// indicator and no multiple selection: for those, use [FossCombobox].
///
/// Colors, type, and metrics come from `context.fossTheme`; pass a
/// [FossComboboxStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// See also [FossSelect] for selection without typing.
///
/// ```dart
/// FossAutocomplete(
///   label: 'Fruit',
///   hintText: 'Type to filter',
///   items: const ['Apple', 'Banana', 'Cherry'],
///   onChanged: (value) => setState(() => fruit = value),
/// );
/// ```
class FossAutocomplete extends StatelessWidget {
  /// {@macro foss.combobox.preview}
  ///
  /// Creates an autocomplete over string [items].
  const FossAutocomplete({
    required this.items,
    this.controller,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.showTrigger = false,
    this.showClear = false,
    this.startAddon,
    this.filter,
    this.onChanged,
    this.emptyText = _defaultEmptyText,
    this.style,
    super.key,
  });

  /// The suggestions to filter as the user types.
  final List<String> items;

  /// Holds the editable text. Created and disposed internally when null.
  final TextEditingController? controller;

  /// Manages keyboard focus. Created and disposed internally when null.
  final FocusNode? focusNode;

  /// The field height and type scale.
  final FossTextFieldSize size;

  /// Optional label rendered above the field.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hintText;

  /// When non-null, marks the field invalid and recolors its border.
  final String? errorText;

  /// Whether the field accepts input. Disabled when false.
  final bool enabled;

  /// Whether to show the trailing chevron that opens the list. Hidden by
  /// default; the list also opens on focus and typing.
  final bool showTrigger;

  /// Whether to show a trailing clear button while the field is non-empty.
  final bool showClear;

  /// Optional leading widget, typically a search glyph. Icon-agnostic.
  final Widget? startAddon;

  /// Overrides the default case-insensitive substring match. Receives the
  /// option label and the current query.
  final bool Function(String label, String query)? filter;

  /// Called whenever the field text changes, including on a pick.
  final ValueChanged<String>? onChanged;

  /// Caption shown when the query matches no suggestion.
  final String emptyText;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossComboboxStyle? style;

  @override
  Widget build(BuildContext context) {
    return _FossComboboxField<String>(
      options: [
        for (final item in items) FossComboboxItem(value: item, label: item),
      ],
      controller: controller,
      focusNode: focusNode,
      size: size,
      label: label,
      hintText: hintText,
      errorText: errorText,
      enabled: enabled,
      showTrigger: showTrigger,
      showClear: showClear,
      startAddon: startAddon,
      showIndicator: false,
      emptyText: emptyText,
      filter: filter ?? _defaultFilter,
      isSelected: (_) => false,
      onPick: (item) => onChanged?.call(item.label),
      onTextChanged: (text) => onChanged?.call(text),
      style: style,
    );
  }
}

/// {@category Inputs}
/// {@macro foss.combobox.preview}
///
/// A text field with a filtered dropdown of predefined items, each carrying a
/// check when picked.
///
/// Unlike [FossAutocomplete], the value is the selected item, not the raw text:
/// pass [value] and rebuild on [onChanged]. Picking a row writes its label
/// into the field and closes the popup. A null [onChanged] (or
/// `enabled: false`) disables the field.
///
/// {@macro foss.customize}
///
/// See also [FossSelect] for selection without typing.
///
/// ```dart
/// FossCombobox<String>(
///   label: 'Team',
///   hintText: 'Search teams',
///   value: team,
///   onChanged: (v) => setState(() => team = v),
///   items: const [
///     FossComboboxItem(value: 'design', label: 'Design'),
///     FossComboboxItem(value: 'eng', label: 'Engineering'),
///   ],
/// );
/// ```
class FossCombobox<T> extends StatelessWidget {
  /// {@macro foss.combobox.preview}
  ///
  /// Creates a single-select combobox over [items].
  const FossCombobox({
    required this.items,
    this.value,
    this.onChanged,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.showClear = false,
    this.startAddon,
    this.filter,
    this.emptyText = _defaultEmptyText,
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossComboboxItem<T>> items;

  /// The picked value, or null when nothing is selected.
  final T? value;

  /// Called with the picked value when a row is chosen. A null callback
  /// disables the field.
  final ValueChanged<T?>? onChanged;

  /// Manages keyboard focus. Created and disposed internally when null.
  final FocusNode? focusNode;

  /// The field height and type scale.
  final FossTextFieldSize size;

  /// Optional label rendered above the field.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hintText;

  /// When non-null, marks the field invalid and recolors its border.
  final String? errorText;

  /// Whether the field accepts input. Disabled when false or [onChanged] is
  /// null.
  final bool enabled;

  /// Whether to show a trailing clear button while a value is selected.
  final bool showClear;

  /// Optional leading widget, typically a search glyph. Icon-agnostic.
  final Widget? startAddon;

  /// Overrides the default case-insensitive substring match.
  final bool Function(String label, String query)? filter;

  /// Caption shown when the query matches no option.
  final String emptyText;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossComboboxStyle? style;

  @override
  Widget build(BuildContext context) {
    return _FossComboboxField<T>(
      options: items,
      focusNode: focusNode,
      size: size,
      label: label,
      hintText: hintText,
      errorText: errorText,
      enabled: enabled && onChanged != null,
      showTrigger: true,
      showClear: showClear,
      startAddon: startAddon,
      showIndicator: true,
      resetOnBlur: true,
      initialText: _selectedLabel(),
      emptyText: emptyText,
      filter: filter ?? _defaultFilter,
      isSelected: (v) => v == value,
      onPick: (item) => onChanged?.call(item.value),
      onClear: () => onChanged?.call(null),
      style: style,
    );
  }

  String? _selectedLabel() {
    for (final item in items) {
      if (item.value == value) return item.label;
    }
    return null;
  }
}

/// {@category Inputs}
/// {@macro foss.combobox.preview}
///
/// A combobox that holds several picks at once, shown as removable chips.
///
/// The value is the set of selected items ([values]); rebuild on [onChanged].
/// Typing filters [items], picking toggles a chip and keeps the popup open, and
/// Backspace on the empty input removes the last chip. A null [onChanged] (or
/// `enabled: false`) disables the field.
///
/// {@macro foss.customize}
///
/// See also [FossSelect] for selection without typing.
///
/// ```dart
/// FossMultiCombobox<String>(
///   label: 'Tags',
///   hintText: 'Add tags',
///   values: tags,
///   onChanged: (v) => setState(() => tags = v),
///   items: const [
///     FossComboboxItem(value: 'design', label: 'Design'),
///     FossComboboxItem(value: 'eng', label: 'Engineering'),
///   ],
/// );
/// ```
class FossMultiCombobox<T> extends StatelessWidget {
  /// {@macro foss.combobox.preview}
  ///
  /// Creates a multi-select combobox over [items].
  const FossMultiCombobox({
    required this.items,
    this.values = const {},
    this.onChanged,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.startAddon,
    this.filter,
    this.emptyText = _defaultEmptyText,
    this.removeLabel = 'Remove',
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossComboboxItem<T>> items;

  /// The current picks.
  final Set<T> values;

  /// Called with the next set when a pick is toggled. A null callback disables
  /// the field.
  final ValueChanged<Set<T>>? onChanged;

  /// Manages keyboard focus. Created and disposed internally when null.
  final FocusNode? focusNode;

  /// The field height and type scale.
  final FossTextFieldSize size;

  /// Optional label rendered above the field.
  final String? label;

  /// Placeholder shown while no picks and the input is empty.
  final String? hintText;

  /// When non-null, marks the field invalid and recolors its border.
  final String? errorText;

  /// Whether the field accepts input. Disabled when false or [onChanged] is
  /// null.
  final bool enabled;

  /// Optional leading widget, typically a search glyph. Icon-agnostic.
  final Widget? startAddon;

  /// Overrides the default case-insensitive substring match.
  final bool Function(String label, String query)? filter;

  /// Caption shown when the query matches no option.
  final String emptyText;

  /// Accessible label for each chip's remove button.
  final String removeLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossComboboxStyle? style;

  @override
  Widget build(BuildContext context) {
    return _FossMultiComboboxField<T>(
      options: items,
      values: values,
      focusNode: focusNode,
      size: size,
      label: label,
      hintText: hintText,
      errorText: errorText,
      enabled: enabled && onChanged != null,
      startAddon: startAddon,
      emptyText: emptyText,
      removeLabel: removeLabel,
      filter: filter ?? _defaultFilter,
      onChanged: (next) => onChanged?.call(next),
      style: style,
    );
  }
}

/// Builds the popup and row appearance from the theme tokens for [size].
_ComboboxVisuals _resolve(FossThemeData theme, FossTextFieldSize size) {
  final c = theme.colors;
  final textStyle = switch (size) {
    FossTextFieldSize.sm => theme.typography.sm,
    FossTextFieldSize.md => theme.typography.base,
    FossTextFieldSize.lg => theme.typography.base,
  };
  return _ComboboxVisuals(
    foreground: c.foreground,
    mutedForeground: c.mutedForeground,
    borderRadius: theme.radii.lg,
    rowRadius: theme.radii.sm,
    textStyle: textStyle,
    iconSize: _iconSize,
    popupColor: c.popover,
    popupBorderColor: c.border,
    popupShadow: theme.shadows.lg,
    highlightColor: c.accent,
    highlightForeground: c.accentForeground,
  );
}

_ComboboxVisuals _apply(_ComboboxVisuals base, FossComboboxStyle? override) {
  if (override == null) return base;
  return base.copyWith(
    borderRadius: override.borderRadius,
    textStyle: override.textStyle,
    popupBorderColor: override.borderColor,
  );
}

/// The resolved popup and row appearance. The input box styling stays inside
/// the embedded [FossTextField]; this covers only the dropdown.
@immutable
class _ComboboxVisuals {
  const _ComboboxVisuals({
    required this.foreground,
    required this.mutedForeground,
    required this.borderRadius,
    required this.rowRadius,
    required this.textStyle,
    required this.iconSize,
    required this.popupColor,
    required this.popupBorderColor,
    required this.popupShadow,
    required this.highlightColor,
    required this.highlightForeground,
  });

  final Color foreground;
  final Color mutedForeground;
  final double borderRadius;
  final double rowRadius;
  final TextStyle textStyle;
  final double iconSize;
  final Color popupColor;
  final Color popupBorderColor;
  final List<BoxShadow> popupShadow;
  final Color highlightColor;
  final Color highlightForeground;

  _ComboboxVisuals copyWith({
    double? borderRadius,
    TextStyle? textStyle,
    Color? popupBorderColor,
  }) => _ComboboxVisuals(
    foreground: foreground,
    mutedForeground: mutedForeground,
    borderRadius: borderRadius ?? this.borderRadius,
    rowRadius: rowRadius,
    textStyle: textStyle ?? this.textStyle,
    iconSize: iconSize,
    popupColor: popupColor,
    popupBorderColor: popupBorderColor ?? this.popupBorderColor,
    popupShadow: popupShadow,
    highlightColor: highlightColor,
    highlightForeground: highlightForeground,
  );
}

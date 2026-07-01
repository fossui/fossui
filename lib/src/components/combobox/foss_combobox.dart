import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/components/text_field/foss_text_field.dart';
import 'package:foss_ui/src/theme/theme.dart';

part '_foss_combobox_field.dart';
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

// Chips field shell: the border deepens on focus and error, the ring stays
// faint, and the dark surface lifts the fill. Mirrors the field shell.
const double _ringWidth = 3;
const double _focusRingOpacity = 0.24;
const double _errorBorderOpacity = 0.36;
const double _errorBorderFocusedOpacity = 0.64;
const double _errorRingOpacityLight = 0.16;
const double _errorRingOpacityDark = 0.24;
const double _darkFillOpacity = 0.32;
const double _placeholderOpacity = 0.72;

bool _isDark(FossColors c) => c.background.computeLuminance() < 0.5;

/// Default filter: a case-insensitive substring match of the query against the
/// option label.
bool _defaultFilter(String label, String query) =>
    label.toLowerCase().contains(query.toLowerCase());

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
/// ```dart
/// FossAutocomplete(
///   label: 'Fruit',
///   hintText: 'Type to filter',
///   items: const ['Apple', 'Banana', 'Cherry'],
///   onChanged: (value) => setState(() => fruit = value),
/// );
/// ```
class FossAutocomplete extends StatelessWidget {
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
      filter: filter ?? _defaultFilter,
      isSelected: (_) => false,
      onPick: (item) => onChanged?.call(item.label),
      onTextChanged: (text) => onChanged?.call(text),
      style: style,
    );
  }
}

/// A text field with a filtered dropdown of predefined items, each carrying a
/// check when picked.
///
/// Unlike [FossAutocomplete], the value is the selected item, not the raw text:
/// pass [value] and rebuild on [onSelected]. Picking a row writes its label
/// into the field and closes the popup. A null [onSelected] (or
/// `enabled: false`) disables the field.
///
/// ```dart
/// FossCombobox<String>(
///   label: 'Team',
///   hintText: 'Search teams',
///   value: team,
///   onSelected: (v) => setState(() => team = v),
///   items: const [
///     FossComboboxItem(value: 'design', label: 'Design'),
///     FossComboboxItem(value: 'eng', label: 'Engineering'),
///   ],
/// );
/// ```
class FossCombobox<T> extends StatelessWidget {
  /// Creates a single-select combobox over [items].
  const FossCombobox({
    required this.items,
    this.value,
    this.onSelected,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.showClear = false,
    this.startAddon,
    this.filter,
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossComboboxItem<T>> items;

  /// The picked value, or null when nothing is selected.
  final T? value;

  /// Called with the picked value when a row is chosen. A null callback
  /// disables the field.
  final ValueChanged<T?>? onSelected;

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

  /// Whether the field accepts input. Disabled when false or [onSelected] is
  /// null.
  final bool enabled;

  /// Whether to show a trailing clear button while a value is selected.
  final bool showClear;

  /// Optional leading widget, typically a search glyph. Icon-agnostic.
  final Widget? startAddon;

  /// Overrides the default case-insensitive substring match.
  final bool Function(String label, String query)? filter;

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
      enabled: enabled && onSelected != null,
      showTrigger: true,
      showClear: showClear,
      startAddon: startAddon,
      showIndicator: true,
      initialText: _selectedLabel(),
      filter: filter ?? _defaultFilter,
      isSelected: (v) => v == value,
      onPick: (item) => onSelected?.call(item.value),
      onClear: () => onSelected?.call(null),
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

/// A combobox that holds several picks at once, shown as removable chips.
///
/// The value is the set of selected items ([values]); rebuild on [onSelected].
/// Typing filters [items], picking toggles a chip and keeps the popup open, and
/// Backspace on the empty input removes the last chip. A null [onSelected] (or
/// `enabled: false`) disables the field.
///
/// ```dart
/// FossMultiCombobox<String>(
///   label: 'Tags',
///   hintText: 'Add tags',
///   values: tags,
///   onSelected: (v) => setState(() => tags = v),
///   items: const [
///     FossComboboxItem(value: 'design', label: 'Design'),
///     FossComboboxItem(value: 'eng', label: 'Engineering'),
///   ],
/// );
/// ```
class FossMultiCombobox<T> extends StatelessWidget {
  /// Creates a multi-select combobox over [items].
  const FossMultiCombobox({
    required this.items,
    this.values = const {},
    this.onSelected,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.startAddon,
    this.filter,
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossComboboxItem<T>> items;

  /// The current picks.
  final Set<T> values;

  /// Called with the next set when a pick is toggled. A null callback disables
  /// the field.
  final ValueChanged<Set<T>>? onSelected;

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

  /// Whether the field accepts input. Disabled when false or [onSelected] is
  /// null.
  final bool enabled;

  /// Optional leading widget, typically a search glyph. Icon-agnostic.
  final Widget? startAddon;

  /// Overrides the default case-insensitive substring match.
  final bool Function(String label, String query)? filter;

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
      enabled: enabled && onSelected != null,
      startAddon: startAddon,
      filter: filter ?? _defaultFilter,
      onChanged: (next) => onSelected?.call(next),
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

  _ComboboxVisuals copyWith({double? borderRadius, TextStyle? textStyle}) =>
      _ComboboxVisuals(
        foreground: foreground,
        mutedForeground: mutedForeground,
        borderRadius: borderRadius ?? this.borderRadius,
        rowRadius: rowRadius,
        textStyle: textStyle ?? this.textStyle,
        iconSize: iconSize,
        popupColor: popupColor,
        popupBorderColor: popupBorderColor,
        popupShadow: popupShadow,
        highlightColor: highlightColor,
        highlightForeground: highlightForeground,
      );
}

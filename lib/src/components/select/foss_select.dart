import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/combobox/foss_combobox.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part '_foss_select_listbox.dart';
part 'foss_multi_select.dart';
part 'foss_select_item.dart';
part 'foss_select_style.dart';

const double _disabledOpacity = 0.64;
const double _placeholderOpacity = 0.72;
const double _darkFillOpacity = 0.32;
const double _minWidth = 144;
const double _minTapTarget = 48;
const double _indicatorColumn = 16;
const double _iconSize = 18;

const double _ringWidth = 3;
const double _ringOffset = 1;

const double _popupOffset = 4;
const double _popupMargin = 8;
const double _rowMinHeight = 32;
const double _openScale = 0.96;

// Error border and ring alphas: the border deepens when the trigger is focused,
// the ring lifts in dark mode.
const double _errorBorderOpacity = 0.36;
const double _errorBorderFocusedOpacity = 0.64;
const double _errorRingOpacityLight = 0.16;
const double _errorRingOpacityDark = 0.24;
const double _focusRingOpacity = 0.24;

// Inner top-lit rim at rest: a faint dark line in light mode, a faint white
// highlight in dark mode.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// {@category Inputs}
/// {@template foss.select.preview}
/// <img src="https://fossui.org/components/select/overview/light.png"
///   alt="FossSelect, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/select/overview/dark.png"
///   alt="FossSelect, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [select documentation ↗](https://fossui.org/docs/components/select) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/select/fossselect/playground).
/// {@endtemplate}
///
/// A pick-from-list control with no typing.
///
/// The trigger shows the current value or a [placeholder]; tapping it opens an
/// anchored popup listing the [items], and picking a row reports its value
/// through [onChanged] and closes the popup. Selection is controlled: pass
/// [value] and rebuild on [onChanged]. A null [onChanged] (or `enabled: false`)
/// disables the field.
///
/// Colors, type, and metrics come from `context.fossTheme`; pass a
/// [FossSelectStyle] to [style] for a one-off. For multiple selection without
/// typing, use [FossMultiSelect].
///
/// {@macro foss.customize}
///
/// See also [FossMultiSelect] for multiple selection and [FossCombobox] to
/// filter by typing.
///
/// ```dart
/// FossSelect<String>(
///   value: plan,
///   placeholder: 'Choose a plan',
///   onChanged: (v) => setState(() => plan = v),
///   items: const [
///     FossSelectItem(value: 'monthly', label: 'Monthly'),
///     FossSelectItem(value: 'yearly', label: 'Yearly'),
///   ],
/// );
/// ```
class FossSelect<T> extends StatelessWidget {
  /// {@macro foss.select.preview}
  ///
  /// Creates a single-select control over [items].
  const FossSelect({
    required this.items,
    this.value,
    this.onChanged,
    this.placeholder,
    this.label,
    this.errorText,
    this.size = FossSelectSize.md,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossSelectItem<T>> items;

  /// The picked value, or null when nothing is selected.
  final T? value;

  /// Called with the picked value when a row is chosen. A null callback
  /// disables the field. The field has no clear affordance, so this never
  /// fires with null.
  final ValueChanged<T>? onChanged;

  /// Text shown in the trigger when [value] is null.
  final String? placeholder;

  /// Optional label rendered above the trigger.
  final String? label;

  /// When non-null, marks the field invalid and recolors the trigger border.
  final String? errorText;

  /// The trigger height and type scale.
  final FossSelectSize size;

  /// Whether the field accepts input. Disabled when false or [onChanged] is
  /// null.
  final bool enabled;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossSelectStyle? style;

  @override
  Widget build(BuildContext context) {
    return _FossSelectField<T>(
      items: items,
      size: size,
      style: style,
      label: label,
      placeholder: placeholder,
      errorText: errorText,
      enabled: enabled && onChanged != null,
      triggerLabel: _selectedLabel(),
      indicator: _SelectIndicator.checkmark,
      isSelected: (v) => v == value,
      closeOnPick: true,
      onPick: (v) => onChanged?.call(v),
    );
  }

  String? _selectedLabel() {
    for (final item in items) {
      if (item.value == value) return item.label;
    }
    return null;
  }
}

/// Builds the default trigger appearance from the theme tokens for [size].
_SelectVisuals _resolve(FossThemeData theme, FossSelectSize size) {
  final c = theme.colors;
  final (minHeight, padding, textStyle, gap) = switch (size) {
    FossSelectSize.sm => (
      32.0,
      EdgeInsets.symmetric(horizontal: theme.spacing(2.5)),
      theme.typography.sm,
      theme.spacing(1.5),
    ),
    FossSelectSize.md => (
      36.0,
      EdgeInsets.symmetric(horizontal: theme.spacing(3)),
      theme.typography.base,
      theme.spacing(2),
    ),
    FossSelectSize.lg => (
      40.0,
      EdgeInsets.symmetric(horizontal: theme.spacing(3)),
      theme.typography.base,
      theme.spacing(2),
    ),
  };

  // Dark lifts the resting trigger fill by the input color at 32% of its alpha,
  // composited to opaque. Light is the bare surface.
  final background = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return _SelectVisuals(
    background: background,
    foreground: c.foreground,
    placeholderColor: c.mutedForeground.withValues(
      alpha: c.mutedForeground.a * _placeholderOpacity,
    ),
    borderColor: c.input,
    borderRadius: theme.radii.lg,
    rowRadius: theme.radii.sm,
    padding: padding,
    minHeight: minHeight,
    textStyle: textStyle,
    shadow: theme.shadows.xs,
    iconSize: _iconSize,
    gap: gap,
    popupColor: c.popover,
    popupBorderColor: c.border,
    popupShadow: theme.shadows.lg,
    highlightColor: c.accent,
    highlightForeground: c.accentForeground,
  );
}

/// Lays the trigger-facing fields of [override] over the resolved [base]. The
/// popup and row roles stay token-driven.
_SelectVisuals _apply(_SelectVisuals base, FossSelectStyle? override) {
  if (override == null) return base;
  return base.copyWith(
    background: override.backgroundColor,
    foreground: override.foregroundColor,
    placeholderColor: override.placeholderColor,
    borderColor: override.borderColor,
    borderRadius: override.borderRadius,
    padding: override.padding,
    minHeight: override.minHeight,
    textStyle: override.textStyle,
    shadow: override.shadow,
    iconSize: override.iconSize,
    gap: override.gap,
  );
}

/// The fully resolved, non-null trigger, popup, and row appearance.
@immutable
class _SelectVisuals {
  const _SelectVisuals({
    required this.background,
    required this.foreground,
    required this.placeholderColor,
    required this.borderColor,
    required this.borderRadius,
    required this.rowRadius,
    required this.padding,
    required this.minHeight,
    required this.textStyle,
    required this.shadow,
    required this.iconSize,
    required this.gap,
    required this.popupColor,
    required this.popupBorderColor,
    required this.popupShadow,
    required this.highlightColor,
    required this.highlightForeground,
  });

  final Color background;
  final Color foreground;
  final Color placeholderColor;
  final Color borderColor;
  final double borderRadius;
  final double rowRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final TextStyle textStyle;
  final List<BoxShadow> shadow;
  final double iconSize;
  final double gap;
  final Color popupColor;
  final Color popupBorderColor;
  final List<BoxShadow> popupShadow;
  final Color highlightColor;
  final Color highlightForeground;

  _SelectVisuals copyWith({
    Color? background,
    Color? foreground,
    Color? placeholderColor,
    Color? borderColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    double? minHeight,
    TextStyle? textStyle,
    List<BoxShadow>? shadow,
    double? iconSize,
    double? gap,
  }) => _SelectVisuals(
    background: background ?? this.background,
    foreground: foreground ?? this.foreground,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    borderColor: borderColor ?? this.borderColor,
    borderRadius: borderRadius ?? this.borderRadius,
    rowRadius: rowRadius,
    padding: padding ?? this.padding,
    minHeight: minHeight ?? this.minHeight,
    textStyle: textStyle ?? this.textStyle,
    shadow: shadow ?? this.shadow,
    iconSize: iconSize ?? this.iconSize,
    gap: gap ?? this.gap,
    popupColor: popupColor,
    popupBorderColor: popupBorderColor,
    popupShadow: popupShadow,
    highlightColor: highlightColor,
    highlightForeground: highlightForeground,
  );
}

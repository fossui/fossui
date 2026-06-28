import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/components/radio/foss_radio.dart';
import 'package:foss_ui/src/theme/theme.dart';

const double _disabledOpacity = 0.64;

/// The visual treatment of a [FossRadioGroup].
enum FossRadioGroupVariant {
  /// Bare circle with a label, options stacked in a column.
  plain,

  /// Each option wrapped in a full-width, selectable bordered card.
  card,
}

/// Lays out a set of [FossRadio] options as a single-choice group.
///
/// Holds the selected [groupValue] and the [onChanged] callback and shares them
/// with its [children] through an inherited scope, so each [FossRadio] reads
/// its own checked state and reports taps back to the group. Renders an
/// optional [label] above the options and an optional [errorText] below.
///
/// A non-null [errorText] marks every option invalid; `enabled: false` or a
/// null [onChanged] disables the whole group. Colors, type, and spacing come
/// from `context.fossTheme`.
///
/// ```dart
/// FossRadioGroup<String>(
///   label: 'Billing plan',
///   groupValue: plan,
///   onChanged: (value) => setState(() => plan = value),
///   children: const [
///     FossRadio(value: 'monthly', label: 'Monthly'),
///     FossRadio(value: 'yearly', label: 'Yearly', description: 'Save 16%'),
///   ],
/// );
/// ```
class FossRadioGroup<T> extends StatelessWidget {
  /// Creates a radio group. [children] are the [FossRadio] options, each of the
  /// same value type [T].
  const FossRadioGroup({
    required this.children,
    this.groupValue,
    this.onChanged,
    this.label,
    this.errorText,
    this.variant = FossRadioGroupVariant.plain,
    this.enabled = true,
    super.key,
  });

  /// The options, each a [FossRadio] of value type [T].
  final List<Widget> children;

  /// The selected value, or null when none is selected.
  final T? groupValue;

  /// Called with the tapped option's value. Null disables the group.
  final ValueChanged<T?>? onChanged;

  /// Optional label rendered above the options.
  final String? label;

  /// Error caption below the options. A non-null value marks the group invalid.
  final String? errorText;

  /// The visual treatment. Defaults to [FossRadioGroupVariant.plain].
  final FossRadioGroupVariant variant;

  /// Whether the group accepts input. When false it dims and stops responding.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final active = enabled && onChanged != null;
    final hasError = errorText != null;

    return FossRadioGroupScope<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      enabled: active,
      hasError: hasError,
      variant: variant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing(2),
        children: [
          if (label case final text?)
            Opacity(
              opacity: active ? 1 : _disabledOpacity,
              child: Text(
                text,
                style: theme.typography.base.medium.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.spacing(3),
            children: children,
          ),
          if (errorText case final text?)
            Semantics(
              liveRegion: true,
              child: Text(
                text,
                style: theme.typography.xs.copyWith(
                  color: colors.destructiveForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shares a [FossRadioGroup]'s selection state with its [FossRadio]
/// descendants. Read it with [FossRadioGroupScope.of].
class FossRadioGroupScope<T> extends InheritedWidget {
  /// Creates the scope. Provided by [FossRadioGroup]; not constructed directly.
  const FossRadioGroupScope({
    required this.groupValue,
    required this.onChanged,
    required this.enabled,
    required this.hasError,
    required this.variant,
    required super.child,
    super.key,
  });

  /// The group's selected value.
  final T? groupValue;

  /// The group's change callback, invoked with a tapped option's value.
  final ValueChanged<T?>? onChanged;

  /// Whether the group is interactive.
  final bool enabled;

  /// Whether the group is in its invalid state.
  final bool hasError;

  /// The group's visual treatment.
  final FossRadioGroupVariant variant;

  /// The nearest group scope of value type [T] above [context], or null when a
  /// [FossRadio] is used outside a [FossRadioGroup].
  static FossRadioGroupScope<T>? of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FossRadioGroupScope<T>>();

  @override
  bool updateShouldNotify(FossRadioGroupScope<T> oldWidget) =>
      groupValue != oldWidget.groupValue ||
      enabled != oldWidget.enabled ||
      hasError != oldWidget.hasError ||
      variant != oldWidget.variant ||
      onChanged != oldWidget.onChanged;
}

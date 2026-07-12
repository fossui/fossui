part of 'foss_radio.dart';

/// The visual treatment of a [FossRadioGroup].
enum FossRadioGroupVariant {
  /// Bare circle with a label, options stacked in a column.
  plain,

  /// Each option wrapped in a full-width, selectable bordered card.
  card,
}

/// {@category Inputs}
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
  final ValueChanged<T>? onChanged;

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

    // RadioGroup owns the selection, the roving arrow-key focus, and the
    // radiogroup semantics role; the scope carries the enabled, error, and
    // variant state each option reads.
    return RadioGroup<T>(
      groupValue: groupValue,
      // RadioGroup requires a callback; the group disables per option through
      // the scope's [enabled], so no option is interactive when inactive.
      onChanged: (value) {
        if (value != null) onChanged?.call(value);
      },
      child: FossRadioGroupScope<T>(
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
                    color: colors.destructive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shares a [FossRadioGroup]'s enabled, error, and variant state with its
/// [FossRadio] descendants. Selection and focus flow through the enclosing
/// [RadioGroup]; read this scope with [FossRadioGroupScope.of].
class FossRadioGroupScope<T> extends InheritedWidget {
  /// Creates the scope. Provided by [FossRadioGroup]; not constructed directly.
  const FossRadioGroupScope({
    required this.enabled,
    required this.hasError,
    required this.variant,
    required super.child,
    super.key,
  });

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
      enabled != oldWidget.enabled ||
      hasError != oldWidget.hasError ||
      variant != oldWidget.variant;
}

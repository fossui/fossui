part of 'foss_checkbox.dart';

/// The visual treatment of a [FossCheckboxGroup].
enum FossCheckboxGroupVariant {
  /// Bare box with a label, options stacked in a column.
  plain,

  /// Each option wrapped in a full-width, selectable bordered card.
  card,
}

/// {@category Inputs}
/// Lays out a set of [FossCheckboxItem] options as a multi-select group.
///
/// Holds the checked [values] and the [onChanged] callback and shares them with
/// its [children] through an inherited scope, so each [FossCheckboxItem] reads
/// its own checked state and reports taps back to the group. A tap adds or
/// removes the item's value and reports a new set, never mutating [values].
/// Renders an optional [label] above the options and an optional [errorText]
/// below.
///
/// A non-null [errorText] marks every option invalid; `enabled: false` or a
/// null [onChanged] disables the whole group. Colors, type, and spacing come
/// from `context.fossTheme`.
///
/// ```dart
/// FossCheckboxGroup<String>(
///   label: 'Frameworks',
///   values: selected,
///   onChanged: (next) => setState(() => selected = next),
///   children: const [
///     FossCheckboxItem(value: 'next', label: 'Next.js'),
///     FossCheckboxItem(value: 'vite', label: 'Vite'),
///   ],
/// );
/// ```
class FossCheckboxGroup<T> extends StatelessWidget {
  /// Creates a checkbox group. [children] are the [FossCheckboxItem] options,
  /// each of the same value type [T].
  const FossCheckboxGroup({
    required this.children,
    this.values = const {},
    this.onChanged,
    this.label,
    this.errorText,
    this.variant = FossCheckboxGroupVariant.plain,
    this.enabled = true,
    super.key,
  });

  /// The options, each a [FossCheckboxItem] of value type [T].
  final List<Widget> children;

  /// The set of checked values.
  final Set<T> values;

  /// Called with the new set when an option is toggled. Null disables the
  /// group.
  final ValueChanged<Set<T>>? onChanged;

  /// Optional label rendered above the options.
  final String? label;

  /// Error caption below the options. A non-null value marks the group invalid.
  final String? errorText;

  /// The visual treatment. Defaults to [FossCheckboxGroupVariant.plain].
  final FossCheckboxGroupVariant variant;

  /// Whether the group accepts input. When false it dims and stops responding.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final active = enabled && onChanged != null;
    final hasError = errorText != null;

    return FossCheckboxGroupScope<T>(
      values: values,
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
                  color: colors.destructive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single option within a [FossCheckboxGroup].
///
/// Renders a square box with an optional [label] and [description]. Reads its
/// checked, enabled, and invalid state from the enclosing [FossCheckboxGroup]
/// and reports a tap by toggling [value] in the group's set. A bare box (no
/// [label]) is valid. Setting `enabled: false` disables this option; disabling
/// the group disables every option.
///
/// Must be placed under a [FossCheckboxGroup] of the same value type [T]. For a
/// standalone toggle, use [FossCheckbox] instead.
///
/// ```dart
/// FossCheckboxItem<String>(
///   value: 'next',
///   label: 'Next.js',
///   description: 'React framework',
/// );
/// ```
class FossCheckboxItem<T> extends StatelessWidget {
  /// Creates a checkbox option. [value] identifies it within the group.
  const FossCheckboxItem({
    required this.value,
    this.label,
    this.description,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// The value this option contributes to the group, compared by `==`.
  final T value;

  /// Optional title beside the box.
  final String? label;

  /// Optional secondary line below the [label].
  final String? description;

  /// Whether this option accepts input. Disabled when false or when the group
  /// is disabled.
  final bool enabled;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossCheckboxStyle? style;

  @override
  Widget build(BuildContext context) {
    final group = FossCheckboxGroupScope.of<T>(context);
    if (group == null) {
      throw FlutterError(
        'FossCheckboxItem<$T> must be placed inside a FossCheckboxGroup<$T>.',
      );
    }

    final checked = group.values.contains(value);
    final enabled = this.enabled && group.enabled;

    void toggle() {
      final next = Set<T>.of(group.values);
      if (checked) {
        next.remove(value);
      } else {
        next.add(value);
      }
      group.onChanged?.call(next);
    }

    return _FossCheckboxControl(
      checked: checked,
      indeterminate: false,
      enabled: enabled,
      hasError: group.hasError,
      card: group.variant == FossCheckboxGroupVariant.card,
      standalone: false,
      label: label,
      description: description,
      style: style,
      onToggle: enabled ? toggle : null,
    );
  }
}

/// Shares a [FossCheckboxGroup]'s selection state with its [FossCheckboxItem]
/// descendants. Read it with [FossCheckboxGroupScope.of].
class FossCheckboxGroupScope<T> extends InheritedWidget {
  /// Creates the scope. Provided by [FossCheckboxGroup]; not constructed
  /// directly.
  const FossCheckboxGroupScope({
    required this.values,
    required this.onChanged,
    required this.enabled,
    required this.hasError,
    required this.variant,
    required super.child,
    super.key,
  });

  /// The group's checked values.
  final Set<T> values;

  /// The group's change callback, invoked with the new set on a toggle.
  final ValueChanged<Set<T>>? onChanged;

  /// Whether the group is interactive.
  final bool enabled;

  /// Whether the group is in its invalid state.
  final bool hasError;

  /// The group's visual treatment.
  final FossCheckboxGroupVariant variant;

  /// The nearest group scope of value type [T] above [context], or null when a
  /// [FossCheckboxItem] is used outside a [FossCheckboxGroup].
  static FossCheckboxGroupScope<T>? of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FossCheckboxGroupScope<T>>();

  @override
  bool updateShouldNotify(FossCheckboxGroupScope<T> oldWidget) =>
      !setEquals(values, oldWidget.values) ||
      enabled != oldWidget.enabled ||
      hasError != oldWidget.hasError ||
      variant != oldWidget.variant ||
      onChanged != oldWidget.onChanged;
}

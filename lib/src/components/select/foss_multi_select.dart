part of 'foss_select.dart';

/// {@category Inputs}
/// A pick-several-from-list control with no typing.
///
/// Like [FossSelect] but the value is a set: each row carries a checkbox, a
/// pick toggles the row in [values] and keeps the popup open, and the trigger
/// shows a count of picks rather than a single label. Selection is controlled:
/// pass [values] and rebuild on [onChanged]. A null [onChanged] (or
/// `enabled: false`) disables the field.
///
/// For a single choice, use [FossSelect]. To search a long list by typing, that
/// is a combobox, not a select.
///
/// ```dart
/// FossMultiSelect<String>(
///   values: tags,
///   placeholder: 'Choose tags',
///   onChanged: (next) => setState(() => tags = next),
///   items: const [
///     FossSelectItem(value: 'design', label: 'Design'),
///     FossSelectItem(value: 'eng', label: 'Engineering'),
///   ],
/// );
/// ```
class FossMultiSelect<T> extends StatelessWidget {
  /// Creates a multi-select control over [items].
  const FossMultiSelect({
    required this.items,
    this.values = const {},
    this.onChanged,
    this.placeholder,
    this.label,
    this.errorText,
    this.size = FossSelectSize.md,
    this.enabled = true,
    this.selectionLabel,
    this.style,
    super.key,
  });

  /// The options to choose from.
  final List<FossSelectItem<T>> items;

  /// The current set of picked values.
  final Set<T> values;

  /// Called with the next set when a row is toggled. A null callback disables
  /// the field.
  final ValueChanged<Set<T>>? onChanged;

  /// Text shown in the trigger when [values] is empty.
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

  /// Builds the trigger text from the number of picks. Defaults to
  /// "N selected"; override for a different wording or another language.
  final String Function(int count)? selectionLabel;

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
      triggerLabel: values.isEmpty ? null : _countLabel(values.length),
      indicator: _SelectIndicator.checkbox,
      isSelected: values.contains,
      closeOnPick: false,
      onPick: _toggle,
    );
  }

  String _countLabel(int count) =>
      selectionLabel?.call(count) ?? '$count selected';

  void _toggle(T value) {
    final next = {...values};
    if (!next.remove(value)) next.add(value);
    onChanged?.call(next);
  }
}

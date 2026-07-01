part of 'foss_combobox.dart';

/// One option in a [FossCombobox].
///
/// The [label] is the visible row text, the chip text when picked, and the
/// target the filter matches against. [value] is the identity reported through
/// the selection callback, compared by `==`. An optional [icon] renders before
/// the label; it takes any widget, so the package stays icon-agnostic.
///
/// ```dart
/// const FossComboboxItem(value: 'a', label: 'Design');
/// ```
@immutable
class FossComboboxItem<T> {
  /// Creates an option with a [value] and its visible [label].
  const FossComboboxItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// The identity reported when this option is picked, compared by `==`.
  final T value;

  /// The row and chip text, and the string the filter matches against.
  final String label;

  /// Optional leading glyph rendered before the label.
  final Widget? icon;

  /// Whether the option can be picked. A disabled option dims and ignores taps.
  final bool enabled;
}

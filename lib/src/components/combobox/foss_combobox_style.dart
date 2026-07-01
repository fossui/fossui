part of 'foss_combobox.dart';

/// Visual overrides for a [FossAutocomplete] or [FossCombobox]. Every field is
/// optional; a null field falls back to the theme-resolved value.
///
/// State-derived colors (the focus ring, the error border, the row highlight)
/// stay token-driven. To restyle those globally, retheme `FossColors`.
///
/// ```dart
/// FossCombobox<String>(
///   items: items,
///   style: const FossComboboxStyle(borderRadius: 12),
/// );
/// ```
@immutable
class FossComboboxStyle {
  /// Creates a set of overrides. All fields default to null (inherit).
  const FossComboboxStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.textStyle,
    this.shadow,
  });

  /// Fill color of the input box and chips field.
  final Color? backgroundColor;

  /// Resting border color, used when neither focused nor invalid.
  final Color? borderColor;

  /// Corner radius of the input, chips field, and popup in logical pixels.
  final double? borderRadius;

  /// Style of the value, placeholder, and row text. Its color is ignored;
  /// text colors stay token-driven.
  final TextStyle? textStyle;

  /// Drop shadow layers on the input at rest; empty for none.
  final List<BoxShadow>? shadow;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossComboboxStyle merge(FossComboboxStyle? other) {
    if (other == null) return this;
    return FossComboboxStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      shadow: other.shadow ?? shadow,
    );
  }
}

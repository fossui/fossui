part of 'foss_checkbox.dart';

/// Visual overrides for a single checkbox. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other checkbox.
///
/// State-derived colors (the focus ring, the invalid border, the indeterminate
/// minus) stay token-driven. To restyle those globally, retheme [FossColors].
///
/// A larger box with a custom checked fill:
///
/// ```dart
/// FossCheckbox(
///   value: true,
///   label: 'Pro',
///   style: const FossCheckboxStyle(
///     boxSize: 22,
///     checkedColor: Color(0xFF8A38F5),
///   ),
/// );
/// ```
@immutable
class FossCheckboxStyle {
  /// Creates a set of checkbox overrides. All fields default to null (inherit).
  const FossCheckboxStyle({
    this.backgroundColor,
    this.checkedColor,
    this.checkColor,
    this.borderColor,
    this.shadow,
    this.boxSize,
    this.glyphSize,
    this.gap,
    this.labelStyle,
    this.descriptionStyle,
  });

  /// Fill of the box when unchecked or indeterminate.
  final Color? backgroundColor;

  /// Fill of the box when checked.
  final Color? checkedColor;

  /// Color of the checkmark when checked.
  final Color? checkColor;

  /// Resting border color of the box.
  final Color? borderColor;

  /// Drop shadow layers on the resting box; empty for none.
  final List<BoxShadow>? shadow;

  /// Side length of the square box in logical pixels.
  final double? boxSize;

  /// Side length of the centered glyph in logical pixels.
  final double? glyphSize;

  /// Gap between the box and the texts in logical pixels.
  final double? gap;

  /// Style of the label. Its color is ignored; the title color stays
  /// token-driven.
  final TextStyle? labelStyle;

  /// Style of the description. Its color is ignored; the description color
  /// stays token-driven.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossCheckboxStyle(boxSize: 18, glyphSize: 14);
  /// const override = FossCheckboxStyle(glyphSize: 16);
  /// base.merge(override); // boxSize 18 kept, glyphSize becomes 16
  /// ```
  FossCheckboxStyle merge(FossCheckboxStyle? other) {
    if (other == null) return this;
    return FossCheckboxStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      checkedColor: other.checkedColor ?? checkedColor,
      checkColor: other.checkColor ?? checkColor,
      borderColor: other.borderColor ?? borderColor,
      shadow: other.shadow ?? shadow,
      boxSize: other.boxSize ?? boxSize,
      glyphSize: other.glyphSize ?? glyphSize,
      gap: other.gap ?? gap,
      labelStyle: other.labelStyle ?? labelStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

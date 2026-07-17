part of 'foss_number_field.dart';

/// Visual overrides for a [FossNumberField]. Every field is optional; a null
/// field falls back to the value the theme resolves for the size and state.
/// Pass one to a single control via `style:` to tweak a one-off, without
/// changing the theme for every other field.
///
/// State-derived colors (the focus ring and error border) stay token-driven.
/// To restyle those globally, retheme `FossColors`.
///
/// A wider, pill-cornered control with a warmer stepper hover:
///
/// ```dart
/// FossNumberField(
///   value: 3,
///   style: const FossNumberFieldStyle(
///     borderRadius: 999,
///     stepperHoverColor: Color(0xFFF1F5F9),
///   ),
/// );
/// ```
@FossSince('0.1.1')
@immutable
class FossNumberFieldStyle {
  /// Creates a set of overrides. All fields default to null (inherit).
  const FossNumberFieldStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.minHeight,
    this.textStyle,
    this.iconSize,
    this.stepperHoverColor,
    this.shadow,
  });

  /// Fill color of the field box.
  final Color? backgroundColor;

  /// Resting border color, used when neither focused nor invalid.
  final Color? borderColor;

  /// Corner radius in logical pixels.
  final double? borderRadius;

  /// Minimum box height in logical pixels; grows with text scale.
  final double? minHeight;

  /// Style of the numeric value and placeholder. Its color is ignored; the
  /// value and placeholder colors stay token-driven.
  final TextStyle? textStyle;

  /// Painted stepper glyph size in logical pixels.
  final double? iconSize;

  /// Fill painted under a stepper while it is hovered.
  final Color? stepperHoverColor;

  /// Drop shadow layers at rest; empty for none.
  final List<BoxShadow>? shadow;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossNumberFieldStyle(borderRadius: 8, minHeight: 34);
  /// const override = FossNumberFieldStyle(minHeight: 30);
  /// base.merge(override); // borderRadius 8 kept, minHeight becomes 30
  /// ```
  FossNumberFieldStyle merge(FossNumberFieldStyle? other) {
    if (other == null) return this;
    return FossNumberFieldStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      minHeight: other.minHeight ?? minHeight,
      textStyle: other.textStyle ?? textStyle,
      iconSize: other.iconSize ?? iconSize,
      stepperHoverColor: other.stepperHoverColor ?? stepperHoverColor,
      shadow: other.shadow ?? shadow,
    );
  }
}

part of 'foss_radio.dart';

/// Visual overrides for a single [FossRadio]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other radio.
///
/// State-derived colors (the focus ring and invalid border) stay token-driven.
/// To restyle those globally, retheme `FossColors`.
///
/// A larger circle with a custom checked fill:
///
/// ```dart
/// FossRadio<String>(
///   value: 'pro',
///   label: 'Pro',
///   style: const FossRadioStyle(
///     circleSize: 22,
///     dotSize: 10,
///     checkedColor: Color(0xFF8A38F5),
///   ),
/// );
/// ```
@immutable
class FossRadioStyle {
  /// Creates a set of radio overrides. All fields default to null (inherit).
  const FossRadioStyle({
    this.backgroundColor,
    this.checkedColor,
    this.dotColor,
    this.borderColor,
    this.shadow,
    this.circleSize,
    this.dotSize,
    this.gap,
    this.labelStyle,
    this.descriptionStyle,
  });

  /// Fill of the unchecked circle.
  final Color? backgroundColor;

  /// Fill of the circle when checked.
  final Color? checkedColor;

  /// Color of the inner dot when checked.
  final Color? dotColor;

  /// Resting border color of the unchecked circle.
  final Color? borderColor;

  /// Drop shadow layers on the unchecked circle; empty for none.
  final List<BoxShadow>? shadow;

  /// Diameter of the circle in logical pixels.
  final double? circleSize;

  /// Diameter of the inner dot in logical pixels.
  final double? dotSize;

  /// Gap between the circle and the texts in logical pixels.
  final double? gap;

  /// Style of the [FossRadio.label]. Its color is ignored; the title color
  /// stays token-driven.
  final TextStyle? labelStyle;

  /// Style of the [FossRadio.description]. Its color is ignored; the
  /// description color stays token-driven.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossRadioStyle(circleSize: 18, dotSize: 8);
  /// const override = FossRadioStyle(dotSize: 10);
  /// base.merge(override); // circleSize 18 kept, dotSize becomes 10
  /// ```
  FossRadioStyle merge(FossRadioStyle? other) {
    if (other == null) return this;
    return FossRadioStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      checkedColor: other.checkedColor ?? checkedColor,
      dotColor: other.dotColor ?? dotColor,
      borderColor: other.borderColor ?? borderColor,
      shadow: other.shadow ?? shadow,
      circleSize: other.circleSize ?? circleSize,
      dotSize: other.dotSize ?? dotSize,
      gap: other.gap ?? gap,
      labelStyle: other.labelStyle ?? labelStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

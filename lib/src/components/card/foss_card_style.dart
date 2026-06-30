part of 'foss_card.dart';

/// Visual overrides for a single [FossCard]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other card.
///
/// ```dart
/// FossCard(
///   content: const Text('Tinted'),
///   style: FossCardStyle(borderColor: Colors.transparent),
/// );
/// ```
@immutable
class FossCardStyle {
  /// Creates a set of card overrides. All fields default to null (inherit).
  const FossCardStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.shadows,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the card surface.
  final Color? backgroundColor;

  /// Color of the 1px surface border.
  final Color? borderColor;

  /// Corner radius of the surface in logical pixels.
  final double? borderRadius;

  /// Drop shadow layers under the surface; empty for none.
  final List<BoxShadow>? shadows;

  /// Style of the [FossCard.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossCard.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossCardStyle merge(FossCardStyle? other) {
    if (other == null) return this;
    return FossCardStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      shadows: other.shadows ?? shadows,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

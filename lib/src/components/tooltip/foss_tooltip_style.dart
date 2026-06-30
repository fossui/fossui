part of 'foss_tooltip.dart';

/// Visual overrides for a single [FossTooltip]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other tooltip.
///
/// ```dart
/// FossTooltip(
///   message: 'Copy link',
///   style: const FossTooltipStyle(borderRadius: 12),
///   child: FossButton(child: Text('Copy')),
/// );
/// ```
@immutable
class FossTooltipStyle {
  /// Creates a set of tooltip overrides. All fields default to null (inherit).
  const FossTooltipStyle({
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
    this.borderRadius,
    this.shadows,
    this.textStyle,
  });

  /// Fill of the popup surface.
  final Color? backgroundColor;

  /// Color of the 1px popup border.
  final Color? borderColor;

  /// Color of the message text.
  final Color? foregroundColor;

  /// Corner radius of the popup surface.
  final double? borderRadius;

  /// Drop shadow of the popup surface.
  final List<BoxShadow>? shadows;

  /// Style of the message text. Merged over the token default.
  final TextStyle? textStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossTooltipStyle merge(FossTooltipStyle? other) {
    if (other == null) return this;
    return FossTooltipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      shadows: other.shadows ?? shadows,
      textStyle: other.textStyle ?? textStyle,
    );
  }
}

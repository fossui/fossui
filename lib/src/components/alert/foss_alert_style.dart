part of 'foss_alert.dart';

/// Visual overrides for a single [FossAlert]. Every field is optional; a null
/// field falls back to the value the variant and theme resolve. Pass one via
/// `style:` to tweak a one-off without changing the theme.
///
/// ```dart
/// FossAlert(
///   title: const Text('Heads up'),
///   style: const FossAlertStyle(borderRadius: 8),
/// );
/// ```
@immutable
class FossAlertStyle {
  /// Creates a set of alert overrides. All fields default to null (inherit).
  const FossAlertStyle({
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.borderRadius,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the surface.
  final Color? backgroundColor;

  /// Color of the 1px border.
  final Color? borderColor;

  /// Color of the leading status glyph.
  final Color? iconColor;

  /// Corner radius in logical pixels.
  final double? borderRadius;

  /// Style of the [FossAlert.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossAlert.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossAlertStyle merge(FossAlertStyle? other) {
    if (other == null) return this;
    return FossAlertStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      iconColor: other.iconColor ?? iconColor,
      borderRadius: other.borderRadius ?? borderRadius,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

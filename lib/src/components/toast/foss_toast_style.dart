part of 'foss_toast.dart';

/// Visual overrides for a single [FossToast]. Every field is optional; a null
/// field falls back to the value the theme resolves.
///
/// ```dart
/// const FossToast(
///   title: Text('Saved'),
///   style: FossToastStyle(borderRadius: 8),
/// );
/// ```
@immutable
class FossToastStyle {
  /// Creates a set of toast overrides. All fields default to null (inherit).
  const FossToastStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the surface.
  final Color? backgroundColor;

  /// Color of the 1px border.
  final Color? borderColor;

  /// Corner radius in logical pixels.
  final double? borderRadius;

  /// Style of the [FossToast.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossToast.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossToastStyle merge(FossToastStyle? other) {
    if (other == null) return this;
    return FossToastStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

part of 'foss_dialog.dart';

/// Visual overrides for a single [FossDialog]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other dialog.
///
/// ```dart
/// FossDialog(
///   title: const Text('Wide'),
///   style: const FossDialogStyle(maxWidth: 640),
/// );
/// ```
@immutable
class FossDialogStyle {
  /// Creates a set of dialog overrides. All fields default to null (inherit).
  const FossDialogStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.maxWidth,
    this.shadows,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the dialog surface.
  final Color? backgroundColor;

  /// Color of the 1px surface border.
  final Color? borderColor;

  /// Corner radius of the surface in logical pixels.
  final double? borderRadius;

  /// Maximum width of the centered card in logical pixels.
  final double? maxWidth;

  /// Drop shadow layers under the surface; empty for none.
  final List<BoxShadow>? shadows;

  /// Style of the [FossDialog.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossDialog.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossDialogStyle merge(FossDialogStyle? other) {
    if (other == null) return this;
    return FossDialogStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      maxWidth: other.maxWidth ?? maxWidth,
      shadows: other.shadows ?? shadows,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

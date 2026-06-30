part of 'foss_alert_dialog.dart';

/// Visual overrides for a single [FossAlertDialog]. Every field is optional; a
/// null field falls back to the value the theme resolves. Pass one via `style:`
/// to tweak a one-off without changing the theme.
///
/// ```dart
/// FossAlertDialog(
///   title: const Text('Wide'),
///   actions: const [SizedBox()],
///   style: const FossAlertDialogStyle(maxWidth: 640),
/// );
/// ```
@immutable
class FossAlertDialogStyle {
  /// Creates a set of overrides. All fields default to null (inherit).
  const FossAlertDialogStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.maxWidth,
    this.shadows,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the surface.
  final Color? backgroundColor;

  /// Color of the 1px surface border.
  final Color? borderColor;

  /// Corner radius of the surface in logical pixels.
  final double? borderRadius;

  /// Maximum width of the centered card in logical pixels.
  final double? maxWidth;

  /// Drop shadow layers under the surface; empty for none.
  final List<BoxShadow>? shadows;

  /// Style of the [FossAlertDialog.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossAlertDialog.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossAlertDialogStyle merge(FossAlertDialogStyle? other) {
    if (other == null) return this;
    return FossAlertDialogStyle(
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

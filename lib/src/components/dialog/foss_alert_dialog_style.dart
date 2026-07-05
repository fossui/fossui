part of 'foss_dialog.dart';

/// Visual overrides for a single [FossAlertDialog]. An alert style is a
/// [FossDialogStyle]: it carries the same fields and the alert composes a
/// [FossDialog], so it passes its style straight through. Every field is
/// optional; a null field falls back to the value the theme resolves. Pass one
/// via `style:` to tweak a one-off without changing the theme.
///
/// ```dart
/// FossAlertDialog(
///   title: const Text('Wide'),
///   actions: [
///     FossButton(
///       onPressed: () => Navigator.pop(context),
///       child: const Text('OK'),
///     ),
///   ],
///   style: const FossAlertDialogStyle(maxWidth: 640),
/// );
/// ```
@immutable
class FossAlertDialogStyle extends FossDialogStyle {
  /// Creates a set of overrides. All fields default to null (inherit).
  const FossAlertDialogStyle({
    super.backgroundColor,
    super.borderColor,
    super.borderRadius,
    super.maxWidth,
    super.shadows,
    super.titleStyle,
    super.descriptionStyle,
  });

  /// Returns a copy with every non-null field of [other] laid over this one.
  @override
  FossAlertDialogStyle merge(covariant FossAlertDialogStyle? other) {
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

part of 'foss_avatar.dart';

/// Visual overrides for a single [FossAvatar]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other avatar.
///
/// ```dart
/// FossAvatar(
///   fallback: const Text('VL'),
///   style: const FossAvatarStyle(fallbackColor: Color(0xFFE5E7EB)),
/// );
/// ```
@immutable
class FossAvatarStyle {
  /// Creates a set of avatar overrides. All fields default to null (inherit).
  const FossAvatarStyle({
    this.backgroundColor,
    this.fallbackColor,
    this.fallbackTextStyle,
  });

  /// Fill of the circle behind the image.
  final Color? backgroundColor;

  /// Fill of the fallback layer shown when the image is absent or loading.
  final Color? fallbackColor;

  /// Style of the [FossAvatar.fallback] text. Merged over the token default.
  final TextStyle? fallbackTextStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossAvatarStyle merge(FossAvatarStyle? other) {
    if (other == null) return this;
    return FossAvatarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      fallbackColor: other.fallbackColor ?? fallbackColor,
      fallbackTextStyle: other.fallbackTextStyle ?? fallbackTextStyle,
    );
  }
}

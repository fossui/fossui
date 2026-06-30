part of 'foss_drawer.dart';

/// Visual overrides for a single [FossDrawer]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other drawer.
///
/// ```dart
/// FossDrawer(
///   title: const Text('Tinted'),
///   style: FossDrawerStyle(backgroundColor: const Color(0xFF101014)),
/// );
/// ```
@immutable
class FossDrawerStyle {
  /// Creates a set of drawer overrides. All fields default to null (inherit).
  const FossDrawerStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.shadows,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Fill of the drawer surface.
  final Color? backgroundColor;

  /// Color of the 1px surface border.
  final Color? borderColor;

  /// Radius of the exposed corners in logical pixels.
  final double? borderRadius;

  /// Drop shadow layers under the surface; empty for none.
  final List<BoxShadow>? shadows;

  /// Style of the [FossDrawer.title]. Merged over the token default.
  final TextStyle? titleStyle;

  /// Style of the [FossDrawer.description]. Merged over the token default.
  final TextStyle? descriptionStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossDrawerStyle merge(FossDrawerStyle? other) {
    if (other == null) return this;
    return FossDrawerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      shadows: other.shadows ?? shadows,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
    );
  }
}

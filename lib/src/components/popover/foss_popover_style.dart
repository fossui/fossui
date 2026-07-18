part of 'foss_popover.dart';

/// Visual overrides for a single [FossPopover] surface. Every field is
/// optional; a null field falls back to the value the theme resolves. Pass one
/// via `style:` to tweak a one-off without retheming every other popover.
///
/// Carries the surface knobs so a taller child can widen the corner and
/// tighten the padding, the way a calendar surface does.
///
/// ```dart
/// FossPopover(
///   style: FossPopoverStyle(
///     borderRadius: 14,
///     padding: const EdgeInsets.all(8),
///   ),
///   builder: (context) => const Calendar(),
///   child: const FossButton(child: Text('Pick a date')),
/// );
/// ```
@immutable
class FossPopoverStyle {
  /// Creates a set of surface overrides. All fields default to null (inherit).
  const FossPopoverStyle({
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.shadows,
  });

  /// Fill of the surface.
  final Color? backgroundColor;

  /// Color of the 1px surface border.
  final Color? borderColor;

  /// Default text color of the content.
  final Color? foregroundColor;

  /// Corner radius of the surface.
  final double? borderRadius;

  /// Padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Drop shadow of the surface.
  final List<BoxShadow>? shadows;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossPopoverStyle merge(FossPopoverStyle? other) {
    if (other == null) return this;
    return FossPopoverStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      shadows: other.shadows ?? shadows,
    );
  }
}

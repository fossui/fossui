part of 'foss_badge.dart';

/// Visual overrides for a single [FossBadge]. Every field is optional; a null
/// field falls back to the value the variant and theme resolve. Pass one via
/// `style:` to tweak a one-off without changing the theme.
///
/// ```dart
/// FossBadge(
///   label: const Text('Beta'),
///   style: const FossBadgeStyle(borderRadius: 10),
/// );
/// ```
@immutable
class FossBadgeStyle {
  /// Creates a set of badge overrides. All fields default to null (inherit).
  const FossBadgeStyle({
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
    this.borderRadius,
    this.labelStyle,
  });

  /// Fill of the pill.
  final Color? backgroundColor;

  /// Color of the 1px border. Null leaves the variant's border unchanged.
  final Color? borderColor;

  /// Color of the label text and the icon slots.
  final Color? foregroundColor;

  /// Corner radius in logical pixels.
  final double? borderRadius;

  /// Style of the [FossBadge.label]. Merged over the token default.
  final TextStyle? labelStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossBadgeStyle merge(FossBadgeStyle? other) {
    if (other == null) return this;
    return FossBadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      labelStyle: other.labelStyle ?? labelStyle,
    );
  }
}

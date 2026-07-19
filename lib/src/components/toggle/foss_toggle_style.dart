part of 'foss_toggle.dart';

/// Visual overrides for a [FossToggle]. Every field is optional; a null field
/// falls back to the value the theme resolves for the toggle's variant and
/// size. Pass one to a single toggle via `style:` to tweak a one-off, without
/// changing the theme for every other toggle.
///
/// Stateful fields ([backgroundColor], [foregroundColor]) are
/// [WidgetStateProperty]s resolved against the toggle's interactive state set
/// (selected, hovered, focused, disabled); the rest are plain values. The
/// pressed (on) state resolves as [WidgetState.selected].
///
/// A green pressed fill:
///
/// ```dart
/// FossToggle(
///   pressed: on,
///   onPressedChanged: (v) => setState(() => on = v),
///   style: FossToggleStyle(
///     backgroundColor: WidgetStateProperty.resolveWith((states) {
///       if (states.contains(WidgetState.selected)) {
///         return const Color(0xFF16A34A);
///       }
///       return const Color(0x00000000);
///     }),
///   ),
///   child: const Text('Live'),
/// );
/// ```
@immutable
class FossToggleStyle {
  /// Creates a set of toggle overrides. All fields default to null (inherit).
  const FossToggleStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.side,
    this.borderRadius,
    this.cornerRadius,
    this.padding,
    this.minHeight,
    this.textStyle,
    this.shadow,
    this.iconSize,
    this.gap,
    this.disabledOpacity,
  });

  /// Fill color per interactive state.
  final WidgetStateProperty<Color>? backgroundColor;

  /// Label and icon color per interactive state.
  final WidgetStateProperty<Color>? foregroundColor;

  /// Border drawn around the toggle, or [BorderSide.none] for none.
  final BorderSide? side;

  /// Uniform corner radius in logical pixels, applied to all four corners.
  final double? borderRadius;

  /// Per-corner radius. When set it wins over the uniform [borderRadius], so
  /// individual corners can round independently, as a segmented
  /// FossToggleGroup rounds only its outer ends.
  final BorderRadius? cornerRadius;

  /// Inner padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Minimum content height in logical pixels; grows with text scale.
  final double? minHeight;

  /// Label text style; its color is taken from [foregroundColor].
  final TextStyle? textStyle;

  /// Drop shadow layers; empty for none.
  final List<BoxShadow>? shadow;

  /// Leading icon size in logical pixels.
  final double? iconSize;

  /// Gap between icon and label in logical pixels.
  final double? gap;

  /// Opacity applied to the whole toggle when disabled.
  final double? disabledOpacity;

  /// Returns a copy with every non-null field of [other] laid over this one.
  /// Used to layer a per-instance override on the theme-resolved defaults.
  ///
  /// ```dart
  /// const base = FossToggleStyle(borderRadius: 10, minHeight: 36);
  /// const override = FossToggleStyle(minHeight: 32);
  /// base.merge(override); // borderRadius 10 kept, minHeight becomes 32
  /// ```
  FossToggleStyle merge(FossToggleStyle? other) {
    if (other == null) return this;
    return FossToggleStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      side: other.side ?? side,
      borderRadius: other.borderRadius ?? borderRadius,
      cornerRadius: other.cornerRadius ?? cornerRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      textStyle: other.textStyle ?? textStyle,
      shadow: other.shadow ?? shadow,
      iconSize: other.iconSize ?? iconSize,
      gap: other.gap ?? gap,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }
}

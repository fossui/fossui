part of 'foss_chip.dart';

/// Visual overrides for a [FossChip]. Every field is optional; a null field
/// falls back to the value the theme resolves for the chip's variant and size.
/// Pass one to a single chip via `style:` to tweak a one-off, without changing
/// the theme for every other chip.
///
/// Stateful fields ([backgroundColor], [foregroundColor]) are
/// [WidgetStateProperty]s resolved against the chip's interactive state set
/// (selected, hovered, disabled); the rest are plain values. Selection resolves
/// as [WidgetState.selected].
///
/// A green selected fill:
///
/// ```dart
/// FossChip(
///   label: const Text('Design'),
///   selected: on,
///   onSelected: (v) => setState(() => on = v),
///   style: FossChipStyle(
///     backgroundColor: WidgetStateProperty.resolveWith((states) {
///       if (states.contains(WidgetState.selected)) {
///         return const Color(0xFF16A34A);
///       }
///       return const Color(0x0A000000);
///     }),
///   ),
/// );
/// ```
@immutable
class FossChipStyle {
  /// Creates a set of chip overrides. All fields default to null (inherit).
  const FossChipStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.side,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.textStyle,
    this.iconSize,
    this.gap,
    this.disabledOpacity,
  });

  /// Fill color per interactive state.
  final WidgetStateProperty<Color>? backgroundColor;

  /// Label, icon, and close mark color per interactive state.
  final WidgetStateProperty<Color>? foregroundColor;

  /// Border drawn around the chip in every state, or [BorderSide.none] for
  /// none.
  final BorderSide? side;

  /// Uniform corner radius in logical pixels, applied to all four corners.
  final double? borderRadius;

  /// Horizontal inset between the pill edge and its content.
  final double? padding;

  /// Minimum pill height in logical pixels; grows with text scale.
  final double? minHeight;

  /// Label text style; its color is taken from [foregroundColor].
  final TextStyle? textStyle;

  /// Leading icon size in logical pixels.
  final double? iconSize;

  /// Gap between the leading icon and the label in logical pixels.
  final double? gap;

  /// Opacity applied to the whole chip when disabled.
  final double? disabledOpacity;

  /// Returns a copy with every non-null field of [other] laid over this one.
  /// Used to layer a per-instance override on the theme-resolved defaults.
  ///
  /// ```dart
  /// const base = FossChipStyle(borderRadius: 8, minHeight: 32);
  /// const override = FossChipStyle(minHeight: 24);
  /// base.merge(override); // borderRadius 8 kept, minHeight becomes 24
  /// ```
  FossChipStyle merge(FossChipStyle? other) {
    if (other == null) return this;
    return FossChipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      side: other.side ?? side,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      textStyle: other.textStyle ?? textStyle,
      iconSize: other.iconSize ?? iconSize,
      gap: other.gap ?? gap,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }
}

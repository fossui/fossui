part of 'foss_list_tile.dart';

/// Visual overrides for a [FossListTile]. Every field is optional; a null field
/// falls back to what the theme resolves. Pass one to a single tile via
/// `style:` to tweak a one-off, without changing the theme for every other row.
///
/// [backgroundColor] is a [WidgetStateProperty] resolved against the row's
/// interactive state set (hovered, pressed, focused, disabled); the rest are
/// plain values. [titleStyle] and [subtitleStyle] merge over the resolved text
/// styles, so setting only a size keeps the token color.
///
/// A roomier row with a tinted highlight:
///
/// ```dart
/// FossListTile(
///   title: const Text('Storage'),
///   onTap: openStorage,
///   style: FossListTileStyle(
///     minHeight: 56,
///     backgroundColor: WidgetStateProperty.resolveWith((states) {
///       if (states.contains(WidgetState.pressed)) {
///         return const Color(0x1416A34A);
///       }
///       return const Color(0x00000000);
///     }),
///   ),
/// );
/// ```
@immutable
class FossListTileStyle {
  /// Creates a set of tile overrides. All fields default to null (inherit).
  const FossListTileStyle({
    this.backgroundColor,
    this.padding,
    this.gap,
    this.minHeight,
    this.borderRadius,
    this.titleStyle,
    this.subtitleStyle,
    this.iconSize,
  });

  /// Fill color per interactive state. The row is transparent at rest.
  final WidgetStateProperty<Color>? backgroundColor;

  /// Inner padding around the slots.
  final EdgeInsetsGeometry? padding;

  /// Gap between the leading slot, the text column, and the trailing slot, in
  /// logical pixels.
  final double? gap;

  /// Minimum row height in logical pixels; the row grows past it for a
  /// two-line subtitle or a taller slot.
  final double? minHeight;

  /// Uniform corner radius of the highlight fill, in logical pixels.
  final double? borderRadius;

  /// Overrides merged over the resolved title style.
  final TextStyle? titleStyle;

  /// Overrides merged over the resolved subtitle style.
  final TextStyle? subtitleStyle;

  /// Icon size for the leading and trailing slots, in logical pixels.
  final double? iconSize;

  /// Returns a copy with every non-null field of [other] laid over this one.
  /// Used to layer a per-instance override on the theme-resolved defaults.
  ///
  /// ```dart
  /// const base = FossListTileStyle(minHeight: 48, gap: 16);
  /// const override = FossListTileStyle(gap: 12);
  /// base.merge(override); // minHeight 48 kept, gap becomes 12
  /// ```
  FossListTileStyle merge(FossListTileStyle? other) {
    if (other == null) return this;
    return FossListTileStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      minHeight: other.minHeight ?? minHeight,
      borderRadius: other.borderRadius ?? borderRadius,
      titleStyle: other.titleStyle ?? titleStyle,
      subtitleStyle: other.subtitleStyle ?? subtitleStyle,
      iconSize: other.iconSize ?? iconSize,
    );
  }
}

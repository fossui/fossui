part of 'foss_menu.dart';

/// Visual overrides for a [FossMenu]. Every field is optional; a null field
/// falls back to what the theme resolves. Pass one to a single menu via
/// `style:` to tweak a one-off, without changing the theme for every other
/// menu.
///
/// [textStyle] merges over the resolved row style, so setting only a size keeps
/// the token color.
///
/// A wider panel with tighter corners:
///
/// ```dart
/// FossMenu(
///   items: items,
///   style: const FossMenuStyle(minWidth: 220, borderRadius: 6),
///   child: const FossButton(child: Text('Open')),
/// );
/// ```
@immutable
@FossSince('0.1.3')
class FossMenuStyle {
  /// Creates a set of menu overrides. All fields default to null (inherit).
  const FossMenuStyle({
    this.minWidth,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.rowRadius,
    this.highlightColor,
    this.highlightForeground,
    this.foreground,
    this.iconSize,
    this.textStyle,
  });

  /// Smallest panel width in logical pixels. The panel grows past it to fit its
  /// widest row.
  final double? minWidth;

  /// Panel fill color.
  final Color? backgroundColor;

  /// Panel border color.
  final Color? borderColor;

  /// Uniform corner radius of the panel, in logical pixels.
  final double? borderRadius;

  /// Inner padding between the panel border and the rows.
  final EdgeInsetsGeometry? padding;

  /// Uniform corner radius of a row's highlight fill, in logical pixels.
  final double? rowRadius;

  /// Fill behind the highlighted row.
  final Color? highlightColor;

  /// Text and glyph color of the highlighted row.
  final Color? highlightForeground;

  /// Text and glyph color of a row at rest.
  final Color? foreground;

  /// Glyph size for a row's icon slot, in logical pixels.
  final double? iconSize;

  /// Overrides merged over the resolved row text style.
  final TextStyle? textStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  /// Used to layer a per-instance override on the theme-resolved defaults.
  ///
  /// ```dart
  /// const base = FossMenuStyle(minWidth: 200, iconSize: 18);
  /// const override = FossMenuStyle(iconSize: 20);
  /// base.merge(override); // minWidth 200 kept, iconSize becomes 20
  /// ```
  FossMenuStyle merge(FossMenuStyle? other) {
    if (other == null) return this;
    return FossMenuStyle(
      minWidth: other.minWidth ?? minWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      rowRadius: other.rowRadius ?? rowRadius,
      highlightColor: other.highlightColor ?? highlightColor,
      highlightForeground: other.highlightForeground ?? highlightForeground,
      foreground: other.foreground ?? foreground,
      iconSize: other.iconSize ?? iconSize,
      textStyle: other.textStyle == null
          ? textStyle
          : (textStyle?.merge(other.textStyle) ?? other.textStyle),
    );
  }
}

part of 'foss_bottom_nav_bar.dart';

/// Visual overrides for a single [FossBottomNavBar]. Every field is optional; a
/// null field falls back to the value the theme resolves. Pass one via `style:`
/// to tweak a one-off without changing the theme for every other bar.
///
/// A bar on the card surface with no top rule:
///
/// ```dart
/// FossBottomNavBar<String>(
///   items: items,
///   value: section,
///   onChanged: onChanged,
///   style: const FossBottomNavBarStyle(showTopBorder: false),
/// );
/// ```
@immutable
@FossSince('0.1.3')
class FossBottomNavBarStyle {
  /// Creates a set of bar overrides. All fields default to null (inherit).
  const FossBottomNavBarStyle({
    this.backgroundColor,
    this.borderColor,
    this.selectedColor,
    this.unselectedColor,
    this.labelStyle,
    this.iconSize,
    this.minHeight,
    this.showTopBorder,
  });

  /// Fill of the bar, painted through the bottom safe-area inset.
  final Color? backgroundColor;

  /// Color of the hairline along the bar's top edge.
  final Color? borderColor;

  /// Glyph and label color of the current destination.
  final Color? selectedColor;

  /// Glyph and label color of the other destinations.
  final Color? unselectedColor;

  /// Text style of every label. Color is applied per state.
  final TextStyle? labelStyle;

  /// Glyph size in logical pixels.
  final double? iconSize;

  /// Minimum height of a cell in logical pixels, excluding the safe-area inset.
  /// A cell grows past it when the text scaler does.
  final double? minHeight;

  /// Whether the hairline along the top edge is drawn.
  final bool? showTopBorder;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossBottomNavBarStyle(minHeight: 64);
  /// const override = FossBottomNavBarStyle(showTopBorder: false);
  /// base.merge(override); // minHeight kept, showTopBorder added
  /// ```
  FossBottomNavBarStyle merge(FossBottomNavBarStyle? other) {
    if (other == null) return this;
    return FossBottomNavBarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      labelStyle: other.labelStyle ?? labelStyle,
      iconSize: other.iconSize ?? iconSize,
      minHeight: other.minHeight ?? minHeight,
      showTopBorder: other.showTopBorder ?? showTopBorder,
    );
  }
}

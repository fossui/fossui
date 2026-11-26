part of 'foss_bottom_nav_bar.dart';

// The glyph is the primary target on a phone, a step up from the 18 a tab strip
// carries.
const double _iconSize = 24;

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_NavVisuals _resolve(FossThemeData theme, FossBottomNavBarStyle? override) {
  final c = theme.colors;
  return _NavVisuals(
    backgroundColor: override?.backgroundColor ?? c.background,
    borderColor: override?.borderColor ?? c.border,
    selectedColor: override?.selectedColor ?? c.foreground,
    unselectedColor: override?.unselectedColor ?? c.mutedForeground,
    labelStyle: override?.labelStyle ?? theme.typography.xs.medium,
    iconSize: override?.iconSize ?? _iconSize,
    minHeight: override?.minHeight ?? _minCellHeight,
    showTopBorder: override?.showTopBorder ?? true,
  );
}

/// The fully resolved, non-null appearance. A [FossBottomNavBarStyle] override
/// is laid over it by [_resolve], so the widget reads only non-null fields.
@immutable
class _NavVisuals {
  const _NavVisuals({
    required this.backgroundColor,
    required this.borderColor,
    required this.selectedColor,
    required this.unselectedColor,
    required this.labelStyle,
    required this.iconSize,
    required this.minHeight,
    required this.showTopBorder,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color selectedColor;
  final Color unselectedColor;
  final TextStyle labelStyle;
  final double iconSize;
  final double minHeight;
  final bool showTopBorder;
}

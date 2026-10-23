part of 'foss_menu.dart';

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_MenuVisuals _resolve(FossThemeData theme, FossMenuStyle? override) {
  final c = theme.colors;
  final rowStyle = theme.typography.base;
  return _MenuVisuals(
    minWidth: override?.minWidth ?? _minPanelWidth,
    backgroundColor: override?.backgroundColor ?? c.popover,
    borderColor: override?.borderColor ?? c.border,
    borderRadius: override?.borderRadius ?? theme.radii.lg,
    padding: override?.padding ?? EdgeInsets.all(theme.spacing(1)),
    rowPadding: theme.spacing(2),
    rowPaddingY: theme.spacing(1),
    labelPaddingY: theme.spacing(1.5),
    gap: theme.spacing(2),
    rowRadius: override?.rowRadius ?? theme.radii.sm,
    highlightColor: override?.highlightColor ?? c.accent,
    highlightForeground: override?.highlightForeground ?? c.accentForeground,
    foreground: override?.foreground ?? c.popoverForeground,
    destructiveForeground: c.destructiveForeground,
    separatorColor: c.border,
    iconSize: override?.iconSize ?? _iconSize,
    textStyle: rowStyle.merge(override?.textStyle),
    shortcutStyle: theme.typography.xs.medium.copyWith(
      color: c.mutedForeground.withValues(
        alpha: c.mutedForeground.a * _shortcutOpacity,
      ),
    ),
    labelStyle: theme.typography.xs.medium.copyWith(color: c.mutedForeground),
    shadows: overlaySoftShadow(theme.shadows.lg),
  );
}

/// The fully resolved, non-null appearance of one menu. A [FossMenuStyle]
/// override is laid over it by [_resolve], so the widget reads only non-null
/// fields.
@immutable
class _MenuVisuals {
  const _MenuVisuals({
    required this.minWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.padding,
    required this.rowPadding,
    required this.rowPaddingY,
    required this.labelPaddingY,
    required this.gap,
    required this.rowRadius,
    required this.highlightColor,
    required this.highlightForeground,
    required this.foreground,
    required this.destructiveForeground,
    required this.separatorColor,
    required this.iconSize,
    required this.textStyle,
    required this.shortcutStyle,
    required this.labelStyle,
    required this.shadows,
  });

  final double minWidth;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Horizontal inset inside a row, and the separator's side margin.
  final double rowPadding;

  /// Vertical inset inside an action row, and the separator's top and bottom
  /// margin.
  final double rowPaddingY;

  /// Vertical inset inside a group heading, which sits taller than an action
  /// row's.
  final double labelPaddingY;

  /// Gap between a row's glyph, its text, and its shortcut.
  final double gap;

  final double rowRadius;
  final Color highlightColor;
  final Color highlightForeground;
  final Color foreground;
  final Color destructiveForeground;
  final Color separatorColor;
  final double iconSize;
  final TextStyle textStyle;
  final TextStyle shortcutStyle;
  final TextStyle labelStyle;
  final List<BoxShadow> shadows;

  /// The text and glyph color of an action row, which the highlight and the
  /// destructive flag both move.
  Color rowColor({required bool highlighted, required bool destructive}) {
    if (destructive) return destructiveForeground;
    return highlighted ? highlightForeground : foreground;
  }
}

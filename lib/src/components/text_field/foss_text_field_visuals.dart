part of 'foss_text_field.dart';

const double _iconSize = 18;

// Leading and trailing icon glyphs sit at 80% of the text color so they read as
// quieter than the value.
const double _affixOpacity = 0.8;

// Placeholder text sits at 72% of the muted-foreground alpha.
const double _placeholderOpacity = 0.72;

// Dark surfaces lift the fill by the input color at 32% of its alpha.
const double _darkFillOpacity = 0.32;

// The label tightens its line height to 18px against the 16px base.
const double _labelLineHeight = 18 / 16;

/// The size-driven field geometry: resting fill, corner radius, minimum height,
/// and horizontal inset. Shared so every field surface (single-line input,
/// chips input) resolves the same box from the same [size].
({double minHeight, double padX, Color fill, double radius}) fieldMetrics(
  FossThemeData theme,
  FossTextFieldSize size,
) {
  final c = theme.colors;

  // Horizontal inset from the spacing scale: sm sits tighter than md and lg.
  // The border paints over the edge without consuming layout, so the inset is
  // the padding alone and needs no border compensation.
  final (minHeight, padX) = switch (size) {
    FossTextFieldSize.sm => (30.0, theme.spacing(2.5)),
    FossTextFieldSize.md => (34.0, theme.spacing(3)),
    FossTextFieldSize.lg => (38.0, theme.spacing(3)),
  };

  // Dark adds a faint lift over the surface: the input color at 32% of its
  // alpha, composited to opaque. Light is the bare surface.
  final fill = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return (minHeight: minHeight, padX: padX, fill: fill, radius: theme.radii.lg);
}

/// Builds the default appearance for a [size] from the theme tokens.
_FieldVisuals _resolve(FossThemeData theme, FossTextFieldSize size) {
  final c = theme.colors;
  final m = fieldMetrics(theme, size);

  return _FieldVisuals(
    background: m.fill,
    borderColor: c.input,
    textColor: c.foreground,
    hintColor: c.mutedForeground.withValues(alpha: _placeholderOpacity),
    labelColor: c.foreground,
    helperColor: c.mutedForeground,
    borderRadius: m.radius,
    padding: EdgeInsets.symmetric(horizontal: m.padX),
    minHeight: m.minHeight,
    textStyle: theme.typography.base,
    // The label uses the tightened 18px line height.
    labelStyle: theme.typography.base.medium.copyWith(height: _labelLineHeight),
    helperStyle: theme.typography.xs,
    iconSize: _iconSize,
    gap: theme.spacing(2),
    shadow: theme.shadows.xs,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_FieldVisuals _apply(_FieldVisuals base, FossTextFieldStyle? override) {
  if (override == null) return base;
  return _FieldVisuals(
    background: override.backgroundColor ?? base.background,
    borderColor: override.borderColor ?? base.borderColor,
    textColor: base.textColor,
    hintColor: base.hintColor,
    labelColor: base.labelColor,
    helperColor: base.helperColor,
    borderRadius: override.borderRadius ?? base.borderRadius,
    padding: override.contentPadding ?? base.padding,
    minHeight: override.minHeight ?? base.minHeight,
    textStyle: override.textStyle ?? base.textStyle,
    labelStyle: override.labelStyle ?? base.labelStyle,
    helperStyle: override.helperStyle ?? base.helperStyle,
    iconSize: override.iconSize ?? base.iconSize,
    gap: override.gap ?? base.gap,
    shadow: override.shadow ?? base.shadow,
  );
}

/// The fully resolved, non-null appearance for one size. A [FossTextFieldStyle]
/// override is laid over it by [_apply], so the widget reads only non-null
/// fields and never needs the null-assertion operator.
@immutable
class _FieldVisuals {
  const _FieldVisuals({
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
    required this.labelColor,
    required this.helperColor,
    required this.borderRadius,
    required this.padding,
    required this.minHeight,
    required this.textStyle,
    required this.labelStyle,
    required this.helperStyle,
    required this.iconSize,
    required this.gap,
    required this.shadow,
  });

  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;
  final Color labelColor;
  final Color helperColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final TextStyle textStyle;
  final TextStyle labelStyle;
  final TextStyle helperStyle;
  final double iconSize;
  final double gap;
  final List<BoxShadow> shadow;

  IconThemeData get iconTheme => IconThemeData(
    size: iconSize,
    color: textColor.withValues(alpha: textColor.a * _affixOpacity),
  );
}

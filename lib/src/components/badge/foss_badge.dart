import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/alert/foss_alert.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

part 'foss_badge_style.dart';

/// Uniform icon edge for every size, in logical pixels.
const double _iconSize = 14;

/// Opacity of a leading or trailing icon.
const double _iconOpacity = 0.8;

/// Soft fill alpha for the tinted variants: a fraction of the role's own alpha,
/// lifted on dark so the tint stays visible on a dark surface.
const double _softFillAlphaLight = 0.08;
const double _softFillAlphaDark = 0.16;

/// The outline pill lifts its fill on dark by the input color at 32% of its
/// alpha, composited to opaque, matching the field surface.
const double _outlineDarkFillAlpha = 0.32;

/// The color axis of a [FossBadge]. [primary] is the default solid pill;
/// [secondary], [outline], and [destructive] complete the solid set; [info],
/// [success], [warning], and [error] are soft, tinting the role at low alpha.
enum FossBadgeVariant {
  /// Solid primary pill (the default).
  primary,

  /// Subtle filled neutral pill.
  secondary,

  /// Bordered pill on the surface.
  outline,

  /// Solid pill for destructive states.
  destructive,

  /// Soft informational pill.
  info,

  /// Soft success pill.
  success,

  /// Soft warning pill.
  warning,

  /// Soft error pill.
  error,
}

/// The size axis of a [FossBadge]: the pill height, minimum width, horizontal
/// padding, and type step. [md] is the default.
enum FossBadgeSize {
  /// Compact: 20 logical pixels tall.
  sm._(height: 20, padding: 4, radius: 4),

  /// Default: 22 logical pixels tall.
  md._(height: 22, padding: 4),

  /// Prominent: 26 logical pixels tall.
  lg._(height: 26, padding: 6),
  ;

  const FossBadgeSize._({
    required this.height,
    required this.padding,
    this.radius,
  });

  /// Pill height, and the minimum width so a single glyph never reads narrower
  /// than it is tall.
  final double height;

  /// Horizontal padding inside the pill.
  final double padding;

  /// Corner radius override, or null to use `radii.sm`.
  final double? radius;

  TextStyle _type(FossTypography t) => switch (this) {
    FossBadgeSize.sm => t.xs,
    FossBadgeSize.md => t.sm,
    FossBadgeSize.lg => t.base,
  };
}

/// {@category Feedback}
/// {@template foss.badge.preview}
/// <img src="https://fossui.org/components/badge/overview/light.png"
///   alt="FossBadge, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/badge/overview/dark.png"
///   alt="FossBadge, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [badge documentation ↗](https://fossui.org/docs/components/badge) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/badge/fossbadge/playground).
/// {@endtemplate}
///
/// A compact status pill: a content-hugging, single-line label that tags a
/// count, a state, or a category. Static and non-interactive.
///
/// [label] is a [Widget] (usually [Text]); the badge applies the weight, color,
/// and type step through `DefaultTextStyle`, so a bare `Text('New')` inherits
/// them. [variant] picks the color (solid or soft tint); [size] the box.
/// [leading] and [trailing] are agnostic icon slots, sized and dimmed by the
/// badge. Colors, type, and radius come from `context.fossTheme`; pass a
/// [FossBadgeStyle] for a one-off override.
///
/// When the badge is the only carrier of meaning, pass [semanticLabel] so
/// assistive technology announces the state rather than the bare glyph.
///
/// {@macro foss.customize}
///
/// See also [FossAlert] for a full-width status message.
///
/// ```dart
/// FossBadge(
///   label: const Text('Active'),
///   variant: FossBadgeVariant.success,
///   leading: const Icon(LucideIcons.check),
/// );
/// ```
class FossBadge extends StatelessWidget {
  /// {@macro foss.badge.preview}
  ///
  /// Creates a badge. [label] is the pill content; the rest are optional.
  const FossBadge({
    required this.label,
    this.variant = FossBadgeVariant.primary,
    this.size = FossBadgeSize.md,
    this.leading,
    this.trailing,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// The pill content, usually [Text].
  final Widget label;

  /// The color variant. Defaults to [FossBadgeVariant.primary].
  final FossBadgeVariant variant;

  /// The size. Defaults to [FossBadgeSize.md].
  final FossBadgeSize size;

  /// Optional leading icon slot.
  final Widget? leading;

  /// Optional trailing icon slot.
  final Widget? trailing;

  /// Accessibility name that replaces the read-in-place content when set.
  final String? semanticLabel;

  /// Per-instance visual overrides.
  final FossBadgeStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;
    final v = _resolve(colors, variant);

    final foreground = s?.foregroundColor ?? v.foreground;
    final radius = s?.borderRadius ?? size.radius ?? theme.radii.sm;
    final border = s?.borderColor ?? v.border;

    final labelStyle = size
        ._type(theme.typography)
        .medium
        .copyWith(color: foreground, decoration: TextDecoration.none)
        .merge(s?.labelStyle);

    final pill = DefaultTextStyle.merge(
      style: labelStyle,
      softWrap: false,
      overflow: TextOverflow.clip,
      maxLines: 1,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: s?.backgroundColor ?? v.fill,
          shape: RoundedSuperellipseBorder(
            side: border == null ? BorderSide.none : BorderSide(color: border),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: size.height,
            minHeight: size.height,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: theme.spacing(1),
              children: [
                if (leading case final leading?) _icon(leading, foreground),
                label,
                if (trailing case final trailing?) _icon(trailing, foreground),
              ],
            ),
          ),
        ),
      ),
    );

    if (semanticLabel == null) return pill;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: pill),
    );
  }

  /// Wraps a decorative icon slot: excluded from semantics, sized to the
  /// uniform icon metric, colored to the foreground, and dimmed.
  Widget _icon(Widget child, Color color) => ExcludeSemantics(
    child: Opacity(
      opacity: _iconOpacity,
      child: IconTheme.merge(
        data: IconThemeData(size: _iconSize, color: color),
        child: child,
      ),
    ),
  );
}

({Color fill, Color foreground, Color? border}) _resolve(
  FossColors c,
  FossBadgeVariant variant,
) {
  Color soft(Color role) => role.withValues(
    alpha: role.a * (c.isDark ? _softFillAlphaDark : _softFillAlphaLight),
  );

  return switch (variant) {
    FossBadgeVariant.primary => (
      fill: c.primary,
      foreground: c.primaryForeground,
      border: null,
    ),
    FossBadgeVariant.secondary => (
      fill: c.secondary,
      foreground: c.secondaryForeground,
      border: null,
    ),
    FossBadgeVariant.outline => (
      fill: c.isDark
          ? Color.alphaBlend(
              c.input.withValues(alpha: c.input.a * _outlineDarkFillAlpha),
              c.background,
            )
          : c.background,
      foreground: c.foreground,
      border: c.border,
    ),
    FossBadgeVariant.destructive => (
      fill: c.destructive,
      foreground: c.destructiveForegroundOn,
      border: null,
    ),
    FossBadgeVariant.info => (
      fill: soft(c.info),
      foreground: c.infoForeground,
      border: null,
    ),
    FossBadgeVariant.success => (
      fill: soft(c.success),
      foreground: c.successForeground,
      border: null,
    ),
    FossBadgeVariant.warning => (
      fill: soft(c.warning),
      foreground: c.warningForeground,
      border: null,
    ),
    FossBadgeVariant.error => (
      fill: soft(c.destructive),
      foreground: c.destructiveForeground,
      border: null,
    ),
  };
}

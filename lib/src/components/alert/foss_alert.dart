import 'package:flutter/widgets.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

part 'foss_alert_style.dart';

/// Status border alpha (the border tint of a status variant).
const double _borderAlpha = 0.32;

/// Status fill alpha (the surface tint of a status variant).
const double _fillAlpha = 0.04;

/// Neutral dark fill: the input color at 32% of its alpha, lifted on dark.
const double _neutralDarkFillAlpha = 0.32;

/// The leading glyph extent. Centered in a box as tall as the title line so it
/// lands on the first line rather than the top of the row.
const double _iconSize = 16;

/// The status of a [FossAlert], driving its border, fill, and leading glyph.
enum FossAlertVariant {
  /// No status: a plain bordered callout.
  neutral,

  /// Informational.
  info,

  /// A successful outcome.
  success,

  /// A caution.
  warning,

  /// An error or failure.
  error,
}

/// A static inline callout: a leading status glyph, a title, an optional
/// description, and optional actions, on a bordered surface tinted by the
/// [variant].
///
/// The whole surface is an `alert` live region; the status glyph is semantic.
/// Colors, type, radius, and spacing come from `context.fossTheme`. Actions are
/// any widgets, typically `FossButton`s.
///
/// ```dart
/// FossAlert(
///   variant: FossAlertVariant.warning,
///   title: const Text('Storage almost full'),
///   description: const Text('Free up space to keep syncing.'),
/// );
/// ```
class FossAlert extends StatelessWidget {
  /// Creates an alert. [title] is effectively required; the rest are optional.
  const FossAlert({
    this.title,
    this.description,
    this.icon,
    this.actions = const <Widget>[],
    this.variant = FossAlertVariant.neutral,
    this.style,
    super.key,
  });

  /// The title line.
  final Widget? title;

  /// The description below the title.
  final Widget? description;

  /// Overrides the default leading glyph. A status variant paints its status
  /// glyph unless overridden here; [FossAlertVariant.neutral] has no default
  /// glyph, so its leading slot stays empty until an [icon] is given. A custom
  /// icon inherits the variant accent color and the glyph size.
  final Widget? icon;

  /// Action widgets, rendered below the text. Empty hides them.
  final List<Widget> actions;

  /// The status. Defaults to [FossAlertVariant.neutral].
  final FossAlertVariant variant;

  /// Per-instance visual overrides.
  final FossAlertStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
    final v = _resolve(colors, variant);
    final s = style;

    final titleStyle = theme.typography.sm.medium
        .copyWith(color: colors.foreground, decoration: TextDecoration.none)
        .merge(s?.titleStyle);
    final descriptionStyle = theme.typography.sm
        .copyWith(
          color: colors.mutedForeground,
          decoration: TextDecoration.none,
        )
        .merge(s?.descriptionStyle);

    final iconColor = s?.iconColor ?? v.accent;
    final leading = icon ?? v.glyph?.call(iconColor);
    // The box matches the title's line height so the glyph centers on the first
    // line instead of top-aligning to the row.
    final iconBox = (titleStyle.fontSize ?? 14) * (titleStyle.height ?? 1);

    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: s?.backgroundColor ?? v.fill,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: s?.borderColor ?? v.border),
            borderRadius: BorderRadius.circular(
              s?.borderRadius ?? theme.radii.xl,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: sp(3.5),
            vertical: sp(3),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: sp(2),
            children: [
              if (leading != null)
                SizedBox(
                  width: _iconSize,
                  height: iconBox,
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(color: iconColor, size: _iconSize),
                      child: leading,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: sp(1),
                  children: [
                    if (title case final title?)
                      DefaultTextStyle.merge(style: titleStyle, child: title),
                    if (description case final description?)
                      DefaultTextStyle.merge(
                        style: descriptionStyle,
                        child: description,
                      ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: sp(1)),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: sp(1),
                            runSpacing: sp(1),
                            children: actions,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The resolved per-variant appearance.
@immutable
class _AlertVisuals {
  const _AlertVisuals({
    required this.border,
    required this.fill,
    required this.accent,
    required this.glyph,
  });

  final Color border;
  final Color fill;
  final Color accent;

  /// Builds the leading status glyph in the given color. Null for the neutral
  /// variant, which has no status mark.
  final Widget Function(Color color)? glyph;
}

_AlertVisuals _resolve(FossColors c, FossAlertVariant variant) {
  Color tintBorder(Color role) => role.withValues(alpha: role.a * _borderAlpha);
  Color tintFill(Color role) => role.withValues(alpha: role.a * _fillAlpha);

  switch (variant) {
    case FossAlertVariant.neutral:
      final fill = c.isDark
          ? Color.alphaBlend(
              c.input.withValues(alpha: c.input.a * _neutralDarkFillAlpha),
              c.background,
            )
          : const Color(0x00000000);
      return _AlertVisuals(
        border: c.border,
        fill: fill,
        accent: c.mutedForeground,
        glyph: null,
      );
    case FossAlertVariant.info:
      return _AlertVisuals(
        border: tintBorder(c.info),
        fill: tintFill(c.info),
        accent: c.info,
        glyph: (color) => FossGlyphIcon(
          InfoGlyph(color),
          size: _iconSize,
          semanticLabel: 'info',
        ),
      );
    case FossAlertVariant.success:
      return _AlertVisuals(
        border: tintBorder(c.success),
        fill: tintFill(c.success),
        accent: c.success,
        glyph: (color) => FossGlyphIcon(
          SuccessGlyph(color),
          size: _iconSize,
          semanticLabel: 'success',
        ),
      );
    case FossAlertVariant.warning:
      return _AlertVisuals(
        border: tintBorder(c.warning),
        fill: tintFill(c.warning),
        accent: c.warning,
        glyph: (color) => FossGlyphIcon(
          WarningGlyph(color),
          size: _iconSize,
          semanticLabel: 'warning',
        ),
      );
    case FossAlertVariant.error:
      return _AlertVisuals(
        border: tintBorder(c.destructive),
        fill: tintFill(c.destructive),
        accent: c.destructive,
        glyph: (color) => FossGlyphIcon(
          ErrorGlyph(color),
          size: _iconSize,
          semanticLabel: 'error',
        ),
      );
  }
}

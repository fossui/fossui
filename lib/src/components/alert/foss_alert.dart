import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/foundation/foss_glyphs.dart';
import 'package:foss_ui/src/theme/colors/foss_colors.dart';
import 'package:foss_ui/src/theme/foss_theme.dart';
import 'package:foss_ui/src/theme/typography/foss_typography.dart';

part 'foss_alert_style.dart';

/// Status border alpha (the border tint of a status variant).
const double _borderAlpha = 0.32;

/// Status fill alpha (the surface tint of a status variant).
const double _fillAlpha = 0.04;

/// Neutral dark fill: the input color at 32% of its alpha, lifted on dark.
const double _neutralDarkFillAlpha = 0.32;

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
/// Colors, type, radius, and spacing come from `context.fossTheme`. Actions
/// reuse `FossButton`.
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

  /// Overrides the default leading glyph. Null hides the leading slot for
  /// [FossAlertVariant.neutral] and uses the painted status glyph otherwise.
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

    final leading = icon ?? v.glyph(s?.iconColor ?? v.accent);

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
              if (leading != null) SizedBox(width: 16, child: leading),
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
                        child: Row(spacing: sp(2), children: actions),
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
    required this.glyphKind,
  });

  final Color border;
  final Color fill;
  final Color accent;
  final FossGlyph? glyphKind;

  /// The leading glyph in [color], or null for the neutral variant.
  Widget? glyph(Color color) {
    final kind = glyphKind;
    if (kind == null) return null;
    return FossGlyphIcon(
      kind,
      size: 16,
      color: color,
      semanticLabel: kind.name,
    );
  }
}

bool _isDark(FossColors c) => c.background.computeLuminance() < 0.5;

_AlertVisuals _resolve(FossColors c, FossAlertVariant variant) {
  Color tintBorder(Color role) => role.withValues(alpha: role.a * _borderAlpha);
  Color tintFill(Color role) => role.withValues(alpha: role.a * _fillAlpha);

  switch (variant) {
    case FossAlertVariant.neutral:
      final fill = _isDark(c)
          ? Color.alphaBlend(
              c.input.withValues(alpha: c.input.a * _neutralDarkFillAlpha),
              c.background,
            )
          : const Color(0x00000000);
      return _AlertVisuals(
        border: c.border,
        fill: fill,
        accent: c.mutedForeground,
        glyphKind: null,
      );
    case FossAlertVariant.info:
      return _AlertVisuals(
        border: tintBorder(c.info),
        fill: tintFill(c.info),
        accent: c.info,
        glyphKind: FossGlyph.info,
      );
    case FossAlertVariant.success:
      return _AlertVisuals(
        border: tintBorder(c.success),
        fill: tintFill(c.success),
        accent: c.success,
        glyphKind: FossGlyph.success,
      );
    case FossAlertVariant.warning:
      return _AlertVisuals(
        border: tintBorder(c.warning),
        fill: tintFill(c.warning),
        accent: c.warning,
        glyphKind: FossGlyph.warning,
      );
    case FossAlertVariant.error:
      return _AlertVisuals(
        border: tintBorder(c.destructive),
        fill: tintFill(c.destructive),
        accent: c.destructive,
        glyphKind: FossGlyph.error,
      );
  }
}

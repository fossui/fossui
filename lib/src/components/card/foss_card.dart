import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/button/foss_button.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_card_style.dart';

// Inner top-lit rim at rest: a faint dark line in light mode, a faint white
// highlight in dark mode, the same rim the controls carry.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// {@category Layout}
/// {@template foss.card.preview}
/// <img src="https://fossui.org/components/card/overview/light.png"
///   alt="FossCard, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/card/overview/dark.png"
///   alt="FossCard, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [card documentation ↗](https://fossui.org/docs/components/card) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/card/fosscard/playground).
/// {@endtemplate}
///
/// A static content container: a bordered, rounded surface that groups an
/// optional header (title, description, trailing action), an optional content
/// body, and an optional footer. Every slot is optional and content-agnostic;
/// the surface renders, it does not respond.
///
/// The seam between two adjacent slots tightens so their paddings do not double
/// up: the outer edges keep the full inset while a shared seam reads as half.
/// Colors, type, radius, and shadow come from `context.fossTheme`; pass a
/// [FossCardStyle] for a one-off override.
///
/// {@macro foss.customize}
///
/// See also [FossButton] for the actions a card commonly holds.
///
/// ```dart
/// FossCard(
///   title: const Text('Project'),
///   description: const Text('Manage your settings.'),
///   action: FossButton(
///     variant: FossButtonVariant.outline,
///     onPressed: addProject,
///     child: const Text('Add'),
///   ),
///   content: const ProjectSummary(),
///   footer: Row(
///     mainAxisAlignment: MainAxisAlignment.end,
///     children: [FossButton(onPressed: save, child: const Text('Save'))],
///   ),
/// );
/// ```
class FossCard extends StatelessWidget {
  /// {@macro foss.card.preview}
  ///
  /// Creates a card. Every slot is optional; a card with only [content] is
  /// valid, as is a header with no footer.
  const FossCard({
    this.title,
    this.description,
    this.action,
    this.content,
    this.footer,
    this.style,
    super.key,
  });

  /// The title, rendered at the top of the header.
  final Widget? title;

  /// The description, rendered below the title.
  final Widget? description;

  /// A trailing header control (a button, a menu), pinned to the top corner.
  final Widget? action;

  /// The body of the card.
  final Widget? content;

  /// A trailing or leading row of actions or metadata.
  final Widget? footer;

  /// Per-instance visual overrides.
  final FossCardStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
    final s = style;

    final hasHeader = title != null || description != null || action != null;
    final hasContent = content != null;
    final hasFooter = footer != null;

    final radius = s?.borderRadius ?? theme.radii.xl2;
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: s?.borderColor ?? colors.border),
      borderRadius: BorderRadius.circular(radius),
    );

    // The seam between adjacent slots collapses to spacing(4): the header drops
    // its bottom pad when content follows, content drops its touching edges,
    // and the footer drops its top pad when content precedes. A lone slot keeps
    // full spacing(6) on every side.
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              sp(6),
              sp(6),
              sp(6),
              hasContent ? sp(4) : sp(6),
            ),
            child: _buildHeader(theme, colors, s),
          ),
        if (content case final content?)
          Padding(
            padding: EdgeInsets.fromLTRB(
              sp(6),
              hasHeader ? 0 : sp(6),
              sp(6),
              hasFooter ? 0 : sp(6),
            ),
            child: content,
          ),
        if (footer case final footer?)
          Padding(
            padding: EdgeInsets.fromLTRB(
              sp(6),
              hasContent ? sp(4) : sp(6),
              sp(6),
              sp(6),
            ),
            child: footer,
          ),
      ],
    );

    final dark = colors.isDark;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: s?.backgroundColor ?? colors.card,
        shape: shape,
        shadows: s?.shadows ?? theme.shadows.xs,
      ),
      // Every slot is inset, so nothing reaches the corners; the surface needs
      // no clip. Plain text in any slot inherits the card foreground.
      child: CustomPaint(
        foregroundPainter: _RimPainter(
          color: dark ? _rimDark : _rimLight,
          radius: math.max(radius - 1, 0),
          topLit: dark,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.cardForeground),
          child: column,
        ),
      ),
    );
  }

  Widget _buildHeader(
    FossThemeData theme,
    FossColors colors,
    FossCardStyle? s,
  ) {
    final titleStyle = theme.typography.lg.semibold
        .copyWith(color: colors.cardForeground, height: 1)
        .merge(s?.titleStyle);
    final descriptionStyle = theme.typography.sm
        .copyWith(color: colors.mutedForeground)
        .merge(s?.descriptionStyle);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing(1.5),
      children: [
        if (title case final title?)
          DefaultTextStyle.merge(style: titleStyle, child: title),
        if (description case final description?)
          DefaultTextStyle.merge(style: descriptionStyle, child: description),
      ],
    );

    if (action case final action?) {
      // The action pins to the top-trailing corner, spanning the text block;
      // Expanded mirrors it to the leading edge in RTL.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: theme.spacing(1.5),
        children: [
          Expanded(child: text),
          action,
        ],
      );
    }
    return text;
  }
}

/// Paints a 1px rim inside the surface: brightest along one edge, fading to
/// nothing by the middle. [topLit] lights the top edge; otherwise the bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.color,
    required this.radius,
    required this.topLit,
  });

  final Color color;
  final double radius;
  final bool topLit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final shape = RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );
    final shader = LinearGradient(
      begin: topLit ? Alignment.topCenter : Alignment.bottomCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRSuperellipse(shape, paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.topLit != topLit;
}

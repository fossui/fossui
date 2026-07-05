import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/spacing/foss_spacing.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

/// Inner top-lit rim on the surface: a faint dark line in light mode, a faint
/// white highlight in dark mode, the same rim the controls carry.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// Compact height of a footer action, so the bar hugs the controls rather than
/// reserving the full 48px tap target around each one.
const double _footerActionHeight = 36;

/// The footer treatment shared by the dialog and the alert dialog.
enum FossDialogFooterVariant {
  /// No bar: the actions sit on the plain surface.
  bare,

  /// A bordered bar tinted with the muted role behind the actions.
  filled,
}

/// How a modal presents: a centered card or a bottom-stuck sheet.
enum FossDialogPresentation {
  /// A card centered in the viewport, clamped to a max width.
  centered,

  /// A full-width sheet stuck to the bottom edge, slid up into view. The
  /// mobile-first default.
  bottomSheet,
}

/// The route label from a [Text] title, or null for any other title widget.
String? dialogRouteLabel(Widget? title) => switch (title) {
  Text(:final data?) => data,
  _ => null,
};

/// The header, body, and footer insets, with the seams between slots collapsed.
///
/// The slots share a 16 gutter (`spacing(4)`). Where two meet, the facing edges
/// tighten so an all-slots surface does not read looser than a bare one: the
/// body drops its top to 4 under a header and its bottom to 4 above a bare
/// footer, and a bare footer drops its top to 12 below a panel or 16 directly
/// under a header. A [filled] footer keeps the full gutters (its bar draws the
/// separation). [safeBottom], the system inset under a bottom sheet, is
/// absorbed into the footer bottom rather than stacked on it.
({EdgeInsets header, EdgeInsets body, EdgeInsets footer}) resolveDialogInsets({
  required FossSpacing spacing,
  required bool hasHeader,
  required bool hasContent,
  required bool hasActions,
  required bool filled,
  required double safeBottom,
}) {
  final gutter = spacing(4);
  final footerBase = filled ? spacing(3) : gutter;
  return (
    header: EdgeInsets.only(
      left: gutter,
      right: gutter,
      top: gutter,
      bottom: spacing(4),
    ),
    body: EdgeInsets.only(
      left: gutter,
      right: gutter,
      top: hasHeader ? spacing(1) : gutter,
      bottom: hasActions && !filled ? spacing(1) : gutter,
    ),
    footer: EdgeInsets.only(
      left: gutter,
      right: gutter,
      top: filled ? spacing(3) : (hasContent ? spacing(3) : spacing(4)),
      bottom: safeBottom > footerBase ? safeBottom : footerBase,
    ),
  );
}

/// Builds the shared title and description column, or null when both are
/// absent. The surface applies the padding (it collapses the seams against the
/// panel and footer), so this returns the unpadded column. The column aligns to
/// the start; overrides merge over the token defaults.
Widget? buildDialogHeader({
  required FossThemeData theme,
  required Widget? title,
  required Widget? description,
  required TextStyle? titleStyleOverride,
  required TextStyle? descriptionStyleOverride,
}) {
  if (title == null && description == null) return null;
  final colors = theme.colors;
  final titleStyle = theme.typography.xl.semibold
      .copyWith(color: colors.popoverForeground, height: 1)
      .merge(titleStyleOverride);
  final descriptionStyle = theme.typography.sm
      .copyWith(color: colors.mutedForeground)
      .merge(descriptionStyleOverride);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: theme.spacing(1),
    children: [
      if (title case final title?)
        DefaultTextStyle.merge(style: titleStyle, child: title),
      if (description case final description?)
        DefaultTextStyle.merge(style: descriptionStyle, child: description),
    ],
  );
}

/// The resolved surface visuals: the theme tokens after any per-instance style
/// overrides. Grouped so the surface takes one value rather than five loose
/// fields.
@immutable
class FossDialogVisual {
  /// Creates a resolved visual bundle. Every field is already resolved; there
  /// is no fallback here.
  const FossDialogVisual({
    required this.maxWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.shadows,
  });

  /// Maximum width of the card in logical pixels.
  final double maxWidth;

  /// Surface fill.
  final Color backgroundColor;

  /// 1px border color.
  final Color borderColor;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Shadow layers under the surface.
  final List<BoxShadow> shadows;
}

/// The centered card shared by the modal overlays: surface, optional header,
/// scrollable body, optional footer, and an optional close affordance. The
/// header is built by the caller (its alignment differs between the dialog and
/// the alert dialog); this widget owns the surface and the footer.
class FossDialogSurface extends StatelessWidget {
  /// Creates the surface. [header] and [content] are already-built slots;
  /// [actions] drive the footer; [closeButton] overlays the top corner.
  const FossDialogSurface({
    required this.header,
    required this.content,
    required this.actions,
    required this.footerVariant,
    required this.visual,
    this.presentation = FossDialogPresentation.centered,
    this.closeButton,
    this.semanticLabel,
    super.key,
  });

  /// The header slot (title and description), or null.
  final Widget? header;

  /// The scrollable body slot, or null.
  final Widget? content;

  /// The footer actions; empty hides the footer.
  final List<Widget> actions;

  /// The footer treatment.
  final FossDialogFooterVariant footerVariant;

  /// The resolved surface tokens (fill, border, radius, shadow, width).
  final FossDialogVisual visual;

  /// Whether the surface is a centered card or a bottom-stuck sheet.
  final FossDialogPresentation presentation;

  /// An optional close affordance, placed in the top corner.
  final Widget? closeButton;

  /// Names the modal route for assistive technology, usually the title text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final sheet = presentation == FossDialogPresentation.bottomSheet;
    final surface = sheet ? _buildSheet(context) : _buildCard(context);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: surface,
    );
  }

  /// The centered card: clamped width, full superellipse border, top-lit rim.
  Widget _buildCard(BuildContext context) {
    final theme = context.fossTheme;
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: visual.borderColor),
      borderRadius: BorderRadius.circular(visual.borderRadius),
    );

    final card = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: visual.maxWidth),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: visual.backgroundColor,
          shape: shape,
          shadows: visual.shadows,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: CustomPaint(
            foregroundPainter: _RimPainter(
              color: theme.colors.isDark ? _rimDark : _rimLight,
              radius: visual.borderRadius - 1,
              topLit: theme.colors.isDark,
            ),
            child: _slots(context, safeBottom: 0),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.all(theme.spacing(4)),
      child: Center(child: card),
    );
  }

  /// The bottom sheet: full width, squared, top border only, no rim, stuck to
  /// the bottom edge with the actions stacked full width.
  Widget _buildSheet(BuildContext context) {
    final theme = context.fossTheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        border: Border(top: BorderSide(color: visual.borderColor)),
        boxShadow: visual.shadows,
      ),
      child: _slots(context, safeBottom: safeBottom),
    );

    // Keep a gap above a full-height sheet so it never covers the whole screen.
    return Padding(
      padding: EdgeInsets.only(top: theme.spacing(12)),
      child: Align(alignment: Alignment.bottomCenter, child: sheet),
    );
  }

  /// The header / body / footer column with the close affordance overlaid. The
  /// seam collapse between the slots is resolved by [resolveDialogInsets].
  Widget _slots(BuildContext context, {required double safeBottom}) {
    final theme = context.fossTheme;
    final insets = resolveDialogInsets(
      spacing: theme.spacing,
      hasHeader: header != null,
      hasContent: content != null,
      hasActions: actions.isNotEmpty,
      filled: footerVariant == FossDialogFooterVariant.filled,
      safeBottom: safeBottom,
    );

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header case final header?)
              Padding(padding: insets.header, child: header),
            if (content case final content?)
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(padding: insets.body, child: content),
                ),
              ),
            if (actions.isNotEmpty)
              _Footer(
                variant: footerVariant,
                padding: insets.footer,
                actions: actions,
              ),
          ],
        ),
        if (closeButton case final button?)
          PositionedDirectional(
            top: theme.spacing(2),
            end: theme.spacing(2),
            child: button,
          ),
      ],
    );
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.variant,
    required this.padding,
    required this.actions,
  });

  final FossDialogFooterVariant variant;

  /// The footer inset, resolved with the slot seams by [resolveDialogInsets].
  final EdgeInsets padding;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final filled = variant == FossDialogFooterVariant.filled;

    // Actions always sit in a trailing-aligned row, never stacked. Each is
    // capped to the compact action height so the footer hugs the controls
    // instead of reserving each control's full tap-target box.
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: theme.spacing(2),
      children: [
        for (final action in actions)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _footerActionHeight),
            child: action,
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        // The bar is the muted role at 72% of its own opacity; muted is already
        // translucent, so multiply rather than replace its alpha.
        color: filled
            ? colors.muted.withValues(alpha: colors.muted.a * 0.72)
            : null,
        border: filled ? Border(top: BorderSide(color: colors.border)) : null,
      ),
      child: Padding(padding: padding, child: content),
    );
  }
}

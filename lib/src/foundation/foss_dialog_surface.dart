import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/foss_theme.dart';

/// The footer treatment shared by the dialog and the alert dialog.
enum FossDialogFooterVariant {
  /// No bar: the actions sit on the plain surface.
  bare,

  /// A bordered bar tinted with the muted role behind the actions.
  filled,
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
    required this.maxWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.shadows,
    this.closeButton,
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

  /// An optional close affordance, placed in the top corner.
  final Widget? closeButton;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: borderColor),
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final card = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: shape,
          shadows: shadows,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?header,
                  if (content case final content?)
                    Flexible(
                      child: SingleChildScrollView(child: content),
                    ),
                  if (actions.isNotEmpty)
                    _Footer(variant: footerVariant, actions: actions),
                ],
              ),
              if (closeButton case final button?)
                PositionedDirectional(
                  top: theme.spacing(2),
                  end: theme.spacing(2),
                  child: button,
                ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.all(theme.spacing(4)),
      child: Center(child: card),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.variant, required this.actions});

  final FossDialogFooterVariant variant;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
    final filled = variant == FossDialogFooterVariant.filled;

    // Actions sit in a trailing-aligned row (coss sm:flex-row justify-end),
    // each hugging its own content.
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: sp(2),
      children: actions,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? colors.muted.withValues(alpha: 0.72) : null,
        border: filled ? Border(top: BorderSide(color: colors.border)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: sp(6),
          right: sp(6),
          top: sp(4),
          bottom: filled ? sp(4) : sp(6),
        ),
        child: row,
      ),
    );
  }
}

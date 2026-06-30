import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/foundation/foss_dialog_surface.dart';
import 'package:foss_ui/src/foundation/foss_glyphs.dart';
import 'package:foss_ui/src/foundation/foss_modal_route.dart';
import 'package:foss_ui/src/theme/colors/foss_colors.dart';
import 'package:foss_ui/src/theme/foss_theme.dart';
import 'package:foss_ui/src/theme/typography/foss_typography.dart';

part 'foss_dialog_style.dart';

/// Default maximum width of the centered card in logical pixels.
const double _maxWidth = 512;

/// Opens a centered modal dialog and resolves to the value passed to
/// `Navigator.pop`.
///
/// The scrim, focus trap, and focus restoration come from the framework; the
/// active theme is captured and re-provided inside the route. Set
/// [barrierDismissible] to false to require an explicit action.
///
/// ```dart
/// final ok = await showFossDialog<bool>(
///   context: context,
///   builder: (context) => FossDialog(
///     title: const Text('Delete project'),
///     description: const Text('This cannot be undone.'),
///     actions: [
///       FossButton(
///         variant: FossButtonVariant.ghost,
///         onPressed: () => Navigator.pop(context, false),
///         child: const Text('Cancel'),
///       ),
///       FossButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: const Text('Delete'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showFossDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
}) => showFossModal<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
  useRootNavigator: useRootNavigator,
);

/// A centered modal surface with slots for a title, description, body, and
/// actions, plus a default close affordance.
///
/// Show it with [showFossDialog]. The header, body, and footer are each
/// optional; [actions] reuse `FossButton` and stack full width on the footer.
/// Colors, type, radius, and shadow come from `context.fossTheme`.
///
/// ```dart
/// showFossDialog<void>(
///   context: context,
///   builder: (context) => const FossDialog(
///     title: Text('Saved'),
///     description: Text('Your changes are live.'),
///   ),
/// );
/// ```
class FossDialog extends StatelessWidget {
  /// Creates a dialog surface. Build it inside a [showFossDialog] `builder`.
  const FossDialog({
    this.title,
    this.description,
    this.content,
    this.actions = const <Widget>[],
    this.footerVariant = FossDialogFooterVariant.bare,
    this.showCloseButton = true,
    this.closeIcon,
    this.style,
    super.key,
  });

  /// The title, rendered at the top of the header.
  final Widget? title;

  /// The description, rendered below the title.
  final Widget? description;

  /// The scrollable body between the header and the footer.
  final Widget? content;

  /// The footer actions; empty hides the footer.
  final List<Widget> actions;

  /// The footer treatment. Defaults to [FossDialogFooterVariant.bare].
  final FossDialogFooterVariant footerVariant;

  /// Whether to show the close affordance in the top corner.
  final bool showCloseButton;

  /// Overrides the default painted close glyph.
  final Widget? closeIcon;

  /// Per-instance visual overrides.
  final FossDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;

    final header = _buildHeader(theme, colors, s);

    return FossDialogSurface(
      header: header,
      content: content == null
          ? null
          : Padding(
              padding: EdgeInsets.all(theme.spacing(6)),
              child: content,
            ),
      actions: actions,
      footerVariant: footerVariant,
      maxWidth: s?.maxWidth ?? _maxWidth,
      backgroundColor: s?.backgroundColor ?? colors.popover,
      borderColor: s?.borderColor ?? colors.border,
      borderRadius: s?.borderRadius ?? theme.radii.xl2,
      shadows: s?.shadows ?? theme.shadows.lg,
      closeButton: showCloseButton
          ? _CloseButton(icon: closeIcon, color: colors.mutedForeground)
          : null,
    );
  }

  Widget? _buildHeader(
    FossThemeData theme,
    FossColors colors,
    FossDialogStyle? s,
  ) {
    if (title == null && description == null) return null;
    final titleStyle = theme.typography.xl.semibold
        .copyWith(color: colors.popoverForeground)
        .merge(s?.titleStyle);
    final descriptionStyle = theme.typography.sm
        .copyWith(color: colors.mutedForeground)
        .merge(s?.descriptionStyle);

    return Padding(
      padding: EdgeInsets.all(theme.spacing(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing(1),
        children: [
          if (title case final title?)
            DefaultTextStyle.merge(style: titleStyle, child: title),
          if (description case final description?)
            DefaultTextStyle.merge(style: descriptionStyle, child: description),
        ],
      ),
    );
  }
}

/// The default ghost close affordance: a painted cross in a 48px tap target.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.icon, required this.color});

  final Widget? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child:
                icon ?? FossGlyphIcon(FossGlyph.close, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

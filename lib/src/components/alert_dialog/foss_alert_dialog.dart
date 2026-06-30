import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/foundation/foss_dialog_surface.dart';
import 'package:foss_ui/src/foundation/foss_modal_route.dart';
import 'package:foss_ui/src/theme/colors/foss_colors.dart';
import 'package:foss_ui/src/theme/foss_theme.dart';
import 'package:foss_ui/src/theme/typography/foss_typography.dart';

part 'foss_alert_dialog_style.dart';

/// Default maximum width of the centered card in logical pixels.
const double _maxWidth = 512;

/// Opens a non-dismissible alert dialog and resolves to the value passed to
/// `Navigator.pop`.
///
/// Unlike a plain dialog, the scrim does not dismiss it: the user must pick an
/// action. Back or Esc pop the route with a null result, the cancel path.
///
/// ```dart
/// final confirmed = await showFossAlertDialog<bool>(
///   context: context,
///   builder: (context) => FossAlertDialog(
///     title: const Text('Delete account'),
///     description: const Text('This is permanent.'),
///     actions: [
///       FossButton(
///         variant: FossButtonVariant.ghost,
///         onPressed: () => Navigator.pop(context, false),
///         child: const Text('Cancel'),
///       ),
///       FossButton(
///         variant: FossButtonVariant.destructive,
///         onPressed: () => Navigator.pop(context, true),
///         child: const Text('Delete'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showFossAlertDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? barrierLabel,
  bool useRootNavigator = true,
}) => showFossModal<T>(
  context: context,
  builder: builder,
  barrierDismissible: false,
  barrierLabel: barrierLabel,
  useRootNavigator: useRootNavigator,
);

/// A centered, non-dismissible modal that interrupts to require a decision.
///
/// The dialog's stricter sibling: no close affordance, a centered header, and a
/// required, non-empty [actions] footer. Show it with [showFossAlertDialog].
/// Colors, type, radius, and shadow come from `context.fossTheme`.
///
/// ```dart
/// showFossAlertDialog<void>(
///   context: context,
///   builder: (context) => FossAlertDialog(
///     title: const Text('Session expired'),
///     actions: [
///       FossButton(
///         onPressed: () => Navigator.pop(context),
///         child: const Text('Sign in'),
///       ),
///     ],
///   ),
/// );
/// ```
class FossAlertDialog extends StatelessWidget {
  /// Creates an alert dialog. [actions] must be non-empty: a non-dismissible
  /// dialog needs a way out.
  const FossAlertDialog({
    required this.actions,
    this.title,
    this.description,
    this.content,
    this.footerVariant = FossDialogFooterVariant.bare,
    this.style,
    super.key,
  }) : assert(actions.length > 0, 'An alert dialog needs at least one action.');

  /// The footer actions; at least one is required.
  final List<Widget> actions;

  /// The title, centered at the top of the header.
  final Widget? title;

  /// The description, centered below the title.
  final Widget? description;

  /// An optional scrollable body between the header and the footer.
  final Widget? content;

  /// The footer treatment. Defaults to [FossDialogFooterVariant.bare].
  final FossDialogFooterVariant footerVariant;

  /// Per-instance visual overrides.
  final FossAlertDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: FossDialogSurface(
        header: _buildHeader(theme, colors, s),
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
      ),
    );
  }

  Widget? _buildHeader(
    FossThemeData theme,
    FossColors colors,
    FossAlertDialogStyle? s,
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
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing(1),
        children: [
          if (title case final title?)
            DefaultTextStyle.merge(
              style: titleStyle,
              textAlign: TextAlign.center,
              child: title,
            ),
          if (description case final description?)
            DefaultTextStyle.merge(
              style: descriptionStyle,
              textAlign: TextAlign.center,
              child: description,
            ),
        ],
      ),
    );
  }
}

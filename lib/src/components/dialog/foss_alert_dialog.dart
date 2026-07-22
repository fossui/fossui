part of 'foss_dialog.dart';

/// {@category Overlays}
/// {@template foss.alert-dialog.preview}
/// <img src="https://fossui.org/components/alert-dialog/overview/light.png"
///   alt="FossAlertDialog, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/alert-dialog/overview/dark.png"
///   alt="FossAlertDialog, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [alert dialog documentation ↗](https://fossui.org/docs/components/alert-dialog) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/dialog/fossalertdialog/playground).
/// {@endtemplate}
///
/// A non-dismissible modal that interrupts to require a decision.
///
/// The dialog's stricter sibling: it composes a [FossDialog] with the alert
/// configuration locked (no close affordance and a required, non-empty
/// [actions] footer). Show it with [showFossAlertDialog].
/// Colors, type, radius, and shadow come from `context.fossTheme`.
///
/// {@macro foss.customize}
///
/// See also [FossDialog] for a dismissible modal with the same slots.
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
  /// {@macro foss.alert-dialog.preview}
  ///
  /// Creates an alert dialog. [actions] must be non-empty: a non-dismissible
  /// dialog needs a way out.
  const FossAlertDialog({
    required this.actions,
    this.title,
    this.description,
    this.content,
    this.footerVariant = FossDialogFooterVariant.filled,
    this.semanticLabel,
    this.style,
    super.key,
    // isNotEmpty is not const-evaluable in a const constructor; length works.
  }) : assert(actions.length > 0, 'An alert dialog needs at least one action.');

  /// The footer actions; at least one is required.
  final List<Widget> actions;

  /// The title, at the top of the header.
  final Widget? title;

  /// The description, below the title.
  final Widget? description;

  /// An optional scrollable body between the header and the footer.
  final Widget? content;

  /// The footer treatment. Defaults to [FossDialogFooterVariant.filled].
  final FossDialogFooterVariant footerVariant;

  /// Names the modal route for assistive technology. Defaults to the [title]
  /// text when it is a [Text].
  final String? semanticLabel;

  /// Per-instance visual overrides.
  final FossAlertDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    return _buildDialogSurface(
      context,
      title: title,
      description: description,
      content: content,
      actions: actions,
      footerVariant: footerVariant,
      presentation: _DialogPresentationScope.of(context),
      semanticLabel: semanticLabel,
      style: style,
      closeButton: null,
    );
  }
}

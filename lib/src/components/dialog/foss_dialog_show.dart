part of 'foss_dialog.dart';

/// Opens a modal dialog and resolves to the value passed to `Navigator.pop`.
///
/// Defaults to a bottom sheet ([FossDialogPresentation.bottomSheet]) that
/// slides up from the bottom edge; pass [FossDialogPresentation.centered] for a
/// centered card. The scrim, focus trap, and focus restoration come from the
/// framework; the active theme is captured and re-provided in the route. Set
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
  FossDialogPresentation presentation = FossDialogPresentation.bottomSheet,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
}) => _showDialogRoute<T>(
  context: context,
  builder: builder,
  presentation: presentation,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
  useRootNavigator: useRootNavigator,
);

/// Opens a non-dismissible alert dialog and resolves to the value passed to
/// `Navigator.pop`.
///
/// Unlike a plain dialog, the scrim does not dismiss it: the user must pick an
/// action. System back pops the route with a null result, the cancel path.
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
  FossDialogPresentation presentation = FossDialogPresentation.bottomSheet,
  String? barrierLabel,
  bool useRootNavigator = true,
}) => _showDialogRoute<T>(
  context: context,
  builder: builder,
  presentation: presentation,
  barrierDismissible: false,
  barrierLabel: barrierLabel,
  useRootNavigator: useRootNavigator,
);

/// Opens [builder] as a modal dialog route: the shared body behind
/// [showFossDialog] and [showFossAlertDialog]. A bottom sheet slides up on the
/// drawer motion; a centered card rides the default fade and scale. The
/// presentation is set on the route once and read back by the surface through
/// [_DialogPresentationScope].
Future<T?> _showDialogRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required FossDialogPresentation presentation,
  required bool barrierDismissible,
  required String? barrierLabel,
  required bool useRootNavigator,
}) {
  final sheet = presentation == FossDialogPresentation.bottomSheet;
  return showFossModal<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    transitionDuration: sheet ? context.fossTheme.motion.drawer : null,
    transitionBuilder: sheet ? bottomSheetTransition : null,
    builder: (context) => _DialogPresentationScope(
      presentation: presentation,
      child: Builder(builder: builder),
    ),
  );
}

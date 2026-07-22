import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/drawer/foss_drawer.dart';
import 'package:fossui/src/foundation/foss_dialog_surface.dart';
import 'package:fossui/src/foundation/foss_modal_route.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/foss_theme.dart';

part 'foss_alert_dialog.dart';
part 'foss_alert_dialog_style.dart';
part 'foss_dialog_show.dart';
part 'foss_dialog_style.dart';

/// Default maximum width of the centered card in logical pixels.
const double _maxWidth = 512;

/// Carries the [FossDialogPresentation] from the show function down to the
/// surface, so the caller sets it once on the route and the widget reads it
/// back, the same handoff the drawer makes for its side.
class _DialogPresentationScope extends InheritedWidget {
  const _DialogPresentationScope({
    required this.presentation,
    required super.child,
  });

  final FossDialogPresentation presentation;

  static FossDialogPresentation of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DialogPresentationScope>()
          ?.presentation ??
      FossDialogPresentation.centered;

  @override
  bool updateShouldNotify(_DialogPresentationScope oldWidget) =>
      oldWidget.presentation != presentation;
}

/// {@category Overlays}
/// {@template foss.dialog.preview}
/// <img src="https://fossui.org/components/dialog/overview/light.png"
///   alt="FossDialog, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/dialog/overview/dark.png"
///   alt="FossDialog, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [dialog documentation ↗](https://fossui.org/docs/components/dialog) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/dialog/fossdialog/playground).
/// {@endtemplate}
///
/// A modal surface with slots for a title, description, body, and actions,
/// plus a default close affordance. Presents as a bottom sheet by default, or a
/// centered card via [presentation].
///
/// Show it with [showFossDialog]. The header, body, and footer are each
/// optional; [actions] reuse `FossButton` and sit in a trailing-aligned row.
/// Colors, type, radius, and shadow come from `context.fossTheme`.
///
/// {@macro foss.customize}
///
/// See also [FossDrawer] for an edge-anchored panel and [FossAlertDialog] for a
/// decision that cannot be dismissed.
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
  /// {@macro foss.dialog.preview}
  ///
  /// Creates a dialog surface. Build it inside a [showFossDialog] `builder`.
  const FossDialog({
    this.title,
    this.description,
    this.content,
    this.actions = const <Widget>[],
    this.footerVariant = FossDialogFooterVariant.filled,
    this.showCloseButton = true,
    this.closeIcon,
    this.closeLabel = 'Close',
    this.semanticLabel,
    this.presentation,
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

  /// The footer treatment. Defaults to [FossDialogFooterVariant.filled].
  final FossDialogFooterVariant footerVariant;

  /// Whether to show the close affordance in the top corner.
  final bool showCloseButton;

  /// Overrides the default painted close glyph.
  final Widget? closeIcon;

  /// Semantic label for the close affordance.
  final String closeLabel;

  /// Names the modal route for assistive technology. Defaults to the [title]
  /// text when it is a [Text].
  final String? semanticLabel;

  /// How the dialog presents. Null inherits the value the show function set
  /// (bottom sheet by default); pass one to override for a standalone surface.
  final FossDialogPresentation? presentation;

  /// Per-instance visual overrides.
  final FossDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.fossTheme.colors;
    return _buildDialogSurface(
      context,
      title: title,
      description: description,
      content: content,
      actions: actions,
      footerVariant: footerVariant,
      presentation: presentation ?? _DialogPresentationScope.of(context),
      semanticLabel: semanticLabel,
      style: style,
      closeButton: showCloseButton
          ? _CloseButton(
              icon: closeIcon,
              color: colors.foreground.withValues(alpha: 0.8),
              label: closeLabel,
            )
          : null,
    );
  }
}

/// Resolves the theme tokens under the optional [style] and builds the shared
/// [FossDialogSurface]. Both [FossDialog] and [FossAlertDialog] route through
/// here; [closeButton] is present only for the plain dialog.
Widget _buildDialogSurface(
  BuildContext context, {
  required Widget? title,
  required Widget? description,
  required Widget? content,
  required List<Widget> actions,
  required FossDialogFooterVariant footerVariant,
  required FossDialogPresentation presentation,
  required String? semanticLabel,
  required FossDialogStyle? style,
  required Widget? closeButton,
}) {
  final theme = context.fossTheme;
  final colors = theme.colors;
  return FossDialogSurface(
    presentation: presentation,
    semanticLabel: semanticLabel ?? dialogRouteLabel(title),
    header: buildDialogHeader(
      theme: theme,
      title: title,
      description: description,
      titleStyleOverride: style?.titleStyle,
      descriptionStyleOverride: style?.descriptionStyle,
    ),
    content: content,
    actions: actions,
    footerVariant: footerVariant,
    visual: FossDialogVisual(
      maxWidth: style?.maxWidth ?? _maxWidth,
      backgroundColor: style?.backgroundColor ?? colors.popover,
      borderColor: style?.borderColor ?? colors.border,
      borderRadius: style?.borderRadius ?? theme.radii.xl2,
      shadows: style?.shadows ?? theme.shadows.lg,
    ),
    closeButton: closeButton,
  );
}

/// The default ghost close affordance: a painted cross that tints on press,
/// inside a 48px tap target.
class _CloseButton extends StatefulWidget {
  const _CloseButton({
    required this.icon,
    required this.color,
    required this.label,
  });

  final Widget? icon;
  final Color color;
  final String label;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: _pressed ? theme.colors.accent : null,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(theme.radii.md),
              ),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child:
                    widget.icon ??
                    FossGlyphIcon(CloseGlyph(widget.color), size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

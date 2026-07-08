import 'dart:async' show unawaited;

import 'package:flutter/semantics.dart' show Assertiveness, SemanticsService;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/spinner/foss_spinner.dart';
import 'package:fossui/src/components/toast/foss_toast.dart';
import 'package:fossui/src/components/toast/foss_toast_controller.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

/// Maximum width of a toast surface in logical pixels.
const double _maxWidth = 360;

/// The leading glyph extent. Centered in a box as tall as the first text line
/// so it lands on that line rather than the top of the row.
const double _iconSize = 16;

/// The slide curve for a toast entering or leaving.
const Cubic _slideCurve = Cubic(0.22, 1, 0.36, 1);

/// Shares a [FossToastController] with the subtree. Read it with
/// [FossToastScope.of]; provided by a [FossToaster].
class FossToastScope extends InheritedNotifier<FossToastController> {
  /// Creates the scope around [child], backed by [controller].
  const FossToastScope({
    required FossToastController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The nearest controller above [context]. Throws when no [FossToaster] is an
  /// ancestor.
  static FossToastController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FossToastScope>();
    if (scope?.notifier case final controller?) return controller;
    throw FlutterError(
      'showFossToast requires a FossToaster ancestor in the widget tree.',
    );
  }
}

/// Hosts transient toasts over its [child]. Mount it once near the app root,
/// above everything that needs to raise a toast.
///
/// ```dart
/// FossToaster(child: MyApp());
/// ```
class FossToaster extends StatefulWidget {
  /// Creates a toaster around [child].
  const FossToaster({required this.child, super.key});

  /// The app subtree below the toasts.
  final Widget child;

  @override
  State<FossToaster> createState() => _FossToasterState();
}

class _FossToasterState extends State<FossToaster> {
  final FossToastController _controller = FossToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FossToastScope(
      controller: _controller,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          widget.child,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ToastViewport(controller: _controller),
          ),
        ],
      ),
    );
  }
}

/// Raises [toast] on the nearest [FossToaster] and returns its id, usable with
/// `FossToastScope.of(context).update`/`dismiss`.
int showFossToast(BuildContext context, FossToast toast) =>
    FossToastScope.of(context).show(toast);

class _ToastViewport extends StatelessWidget {
  const _ToastViewport({required this.controller});

  final FossToastController controller;

  @override
  Widget build(BuildContext context) {
    final sp = context.fossTheme.spacing;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final entries = controller.entries;
        final visible = entries.length > FossToastController.maxVisible
            ? entries.sublist(entries.length - FossToastController.maxVisible)
            : entries;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(sp(4)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: sp(3),
              children: [
                for (final entry in visible)
                  _FossToastView(
                    key: ValueKey<int>(entry.id),
                    id: entry.id,
                    toast: entry.toast,
                    onDismiss: () => controller.dismiss(entry.id),
                    onPressChange: (pressed) =>
                        controller.setPressed(entry.id, pressed: pressed),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FossToastView extends StatefulWidget {
  const _FossToastView({
    required this.id,
    required this.toast,
    required this.onDismiss,
    required this.onPressChange,
    super.key,
  });

  final int id;
  final FossToast toast;
  final VoidCallback onDismiss;
  final ValueChanged<bool> onPressChange;

  @override
  State<_FossToastView> createState() => _FossToastViewState();
}

class _FossToastViewState extends State<_FossToastView> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _shown = true);
      // Error toasts interrupt assertively; other types ride the surface's
      // polite live region. Only a plain-text message can be announced.
      if (widget.toast.type == FossToastType.error) {
        final message = _announcement(widget.toast);
        if (message != null) {
          unawaited(
            SemanticsService.sendAnnouncement(
              View.of(context),
              message,
              Directionality.of(context),
              assertiveness: Assertiveness.assertive,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion ? Duration.zero : theme.motion.toast;
    final shown = reduceMotion || _shown;

    // A single Dismissible tracks one axis, so a horizontal one (the default)
    // nests over a downward one to let the toast be flung left, right, or down.
    return Dismissible(
      key: ValueKey<String>('foss-toast-h-${widget.id}'),
      onDismissed: (_) => widget.onDismiss(),
      child: Dismissible(
        key: ValueKey<String>('foss-toast-v-${widget.id}'),
        direction: DismissDirection.down,
        onDismissed: (_) => widget.onDismiss(),
        child: AnimatedSlide(
          offset: shown ? Offset.zero : const Offset(0, 0.5),
          duration: duration,
          curve: _slideCurve,
          child: AnimatedOpacity(
            opacity: shown ? 1 : 0,
            duration: duration,
            // A press holds the toast open; the countdown resumes on release.
            // The raw pointer listener sits inside the slide so it tracks the
            // surface as it animates, and fires on down regardless of arena.
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => widget.onPressChange(true),
              onPointerUp: (_) => widget.onPressChange(false),
              onPointerCancel: (_) => widget.onPressChange(false),
              child: _surface(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _surface(FossThemeData theme) {
    final colors = theme.colors;
    final sp = theme.spacing;
    final toast = widget.toast;
    final s = toast.style;

    final titleStyle = theme.typography.sm.medium
        .copyWith(
          color: colors.popoverForeground,
          decoration: TextDecoration.none,
        )
        .merge(s?.titleStyle);
    final descriptionStyle = theme.typography.sm
        .copyWith(
          color: colors.mutedForeground,
          decoration: TextDecoration.none,
        )
        .merge(s?.descriptionStyle);

    final leading = toast.icon ?? _leadingFor(toast.type, colors);
    // The leading box matches the first text line's height so the glyph centers
    // on the line instead of top-aligning to the row.
    final firstLineStyle = toast.title != null ? titleStyle : descriptionStyle;
    final leadingBox =
        (firstLineStyle.fontSize ?? 14) * (firstLineStyle.height ?? 1);

    return Semantics(
      // Non-error toasts announce politely through the live region; an error is
      // announced assertively from initState, so it stays off the live region
      // to avoid a double read.
      liveRegion: toast.type != FossToastType.error,
      container: true,
      child: DefaultTextStyle(
        style: theme.typography.sm.copyWith(
          color: colors.popoverForeground,
          decoration: TextDecoration.none,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: s?.backgroundColor ?? colors.popover,
              shape: RoundedSuperellipseBorder(
                side: BorderSide(color: s?.borderColor ?? colors.border),
                borderRadius: BorderRadius.circular(
                  s?.borderRadius ?? theme.radii.lg,
                ),
              ),
              shadows: theme.shadows.lg,
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
                      height: leadingBox,
                      child: Center(child: leading),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: sp(1),
                      children: [
                        if (toast.title case final title?)
                          DefaultTextStyle.merge(
                            style: titleStyle,
                            child: title,
                          ),
                        if (toast.description case final description?)
                          DefaultTextStyle.merge(
                            style: descriptionStyle,
                            child: description,
                          ),
                      ],
                    ),
                  ),
                  ?toast.action,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The plain-text message of [toast] for an assertive announcement: the title
/// then the description, taken from simple [Text] widgets. Null when neither is
/// plain text, since a rich widget carries no string to announce.
String? _announcement(FossToast toast) {
  String? textOf(Widget? widget) => widget is Text ? widget.data : null;
  final parts = <String>[
    ?textOf(toast.title),
    ?textOf(toast.description),
  ];
  return parts.isEmpty ? null : parts.join('. ');
}

/// The default leading slot for [type], or null for [FossToastType.normal].
Widget? _leadingFor(FossToastType type, FossColors colors) {
  switch (type) {
    case FossToastType.normal:
      return null;
    case FossToastType.loading:
      return FossSpinner(size: _iconSize, color: colors.mutedForeground);
    case FossToastType.info:
      return FossGlyphIcon(
        InfoGlyph(colors.info),
        size: _iconSize,
        semanticLabel: 'info',
      );
    case FossToastType.success:
      return FossGlyphIcon(
        SuccessGlyph(colors.success),
        size: _iconSize,
        semanticLabel: 'success',
      );
    case FossToastType.warning:
      return FossGlyphIcon(
        WarningGlyph(colors.warning),
        size: _iconSize,
        semanticLabel: 'warning',
      );
    case FossToastType.error:
      return FossGlyphIcon(
        ErrorGlyph(colors.destructive),
        size: _iconSize,
        semanticLabel: 'error',
      );
  }
}

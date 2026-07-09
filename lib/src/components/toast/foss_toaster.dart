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

/// How much each rear card in the pile shrinks per step behind the front.
const double _rearScaleStep = 0.1;

/// Depth tint blended over the popover fill per rear card index, so the cards
/// behind read as set back.
const double _rearDarken = 0.04;

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

class _ToastViewport extends StatefulWidget {
  const _ToastViewport({required this.controller});

  final FossToastController controller;

  @override
  State<_ToastViewport> createState() => _ToastViewportState();
}

class _ToastViewportState extends State<_ToastViewport> {
  // A stable key per toast id, so a card keeps its element (and its running
  // animations) as it moves forward through the pile, even as it changes from a
  // filled rear into the sizing front. Without this the promotion would remount
  // and replay the entrance, which reads as a flicker.
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};

  GlobalKey _keyFor(int id) => _keys.putIfAbsent(id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final sp = context.fossTheme.spacing;
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final entries = controller.entries;
        _keys.removeWhere((id, _) => entries.every((e) => e.id != id));
        final visible = entries.length > FossToastController.maxVisible
            ? entries.sublist(entries.length - FossToastController.maxVisible)
            : entries;
        if (visible.isEmpty) return const SizedBox.shrink();
        final front = visible.last;

        Widget cardFor(FossToastEntry entry, int depth) => _PileToast(
          key: _keyFor(entry.id),
          toast: entry.toast,
          depth: depth,
          peek: sp(3),
          onDismiss: () => controller.dismiss(entry.id),
          onPressChange: (pressed) =>
              controller.setPressed(entry.id, pressed: pressed),
        );

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(sp(4)),
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // The cards behind fill the front's box so they share its size;
                // the newest is the non-positioned front that sizes the stack
                // and paints on top.
                for (var p = 0; p < visible.length - 1; p++)
                  Positioned.fill(
                    child: cardFor(visible[p], visible.length - 1 - p),
                  ),
                cardFor(front, 0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One card in the toast pile, placed by [depth] (0 is the front): scaling down
/// and lifting by [peek] per step, so the cards behind peek out by a uniform
/// sliver. Only the front shows its content and takes input; the same element
/// carries a toast from the back to the front, so a promotion animates rather
/// than remounting.
class _PileToast extends StatefulWidget {
  const _PileToast({
    required this.toast,
    required this.depth,
    required this.peek,
    required this.onDismiss,
    required this.onPressChange,
    super.key,
  });

  final FossToast toast;
  final int depth;
  final double peek;
  final VoidCallback onDismiss;
  final ValueChanged<bool> onPressChange;

  @override
  State<_PileToast> createState() => _PileToastState();
}

class _PileToastState extends State<_PileToast> {
  bool _shown = false;

  bool get _isFront => widget.depth == 0;

  @override
  void initState() {
    super.initState();
    // A toast is always enqueued as the front, so its first frame runs the
    // entrance slide. A toast promoted from behind kept its element, so it
    // never reaches here again; its move forward rides the pile transform.
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
    final depth = widget.depth;

    // The front carries the message and sizes the stack; the cards behind are
    // blank surfaces filling that box, so the pile shows one toast over a set
    // back stack and a promotion reveals the message without a second surface.
    Widget card = _isFront
        ? _ToastSurface(toast: widget.toast)
        : _RearSurface(depth: depth);

    // A press holds the toast open; the countdown resumes on release. The raw
    // pointer listener fires on down regardless of the gesture arena.
    card = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => widget.onPressChange(true),
      onPointerUp: (_) => widget.onPressChange(false),
      onPointerCancel: (_) => widget.onPressChange(false),
      child: card,
    );

    // Entrance: a newly enqueued front slides up and fades in.
    card = AnimatedSlide(
      offset: shown ? Offset.zero : const Offset(0, 0.5),
      duration: duration,
      curve: _slideCurve,
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: duration,
        child: card,
      ),
    );

    // Pile placement, animated so a change of depth glides between positions.
    card = AnimatedScale(
      scale: 1 - _rearScaleStep * depth,
      alignment: Alignment.topCenter,
      duration: duration,
      curve: _slideCurve,
      child: card,
    );
    card = AnimatedContainer(
      duration: duration,
      curve: _slideCurve,
      transform: Matrix4.translationValues(0, -widget.peek * depth, 0),
      child: card,
    );

    // Only the front takes input and is read out; the rest peek behind it.
    card = IgnorePointer(ignoring: !_isFront, child: card);
    card = ExcludeSemantics(excluding: !_isFront, child: card);

    // A single Dismissible tracks one axis, so a horizontal one nests over a
    // downward one to let the front be flung left, right, or down. The
    // directions relax to none behind the front, keeping the tree shape stable
    // across a promotion so no element is torn down.
    return Dismissible(
      key: const ValueKey<String>('foss-toast-h'),
      direction: _isFront ? DismissDirection.horizontal : DismissDirection.none,
      resizeDuration: null,
      onDismissed: (_) => widget.onDismiss(),
      child: Dismissible(
        key: const ValueKey<String>('foss-toast-v'),
        direction: _isFront ? DismissDirection.down : DismissDirection.none,
        resizeDuration: null,
        onDismissed: (_) => widget.onDismiss(),
        child: card,
      ),
    );
  }
}

/// A blank surface for a toast behind the front. It fills the front's box, and
/// its [_PileToast] scales and lifts it by [depth] to peek out; the fill
/// darkens by depth so the pile reads as one message over a set-back stack.
class _RearSurface extends StatelessWidget {
  const _RearSurface({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: _toastDecoration(
        theme,
        fill: Color.alphaBlend(
          colors.foreground.withValues(alpha: _rearDarken * depth),
          colors.popover,
        ),
        border: colors.border,
        radius: theme.radii.lg,
      ),
    );
  }
}

/// The front toast surface: the superelliptical card, its leading glyph, and
/// its title, description, and action.
class _ToastSurface extends StatelessWidget {
  const _ToastSurface({required this.toast});

  final FossToast toast;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
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
            decoration: _toastDecoration(
              theme,
              fill: s?.backgroundColor ?? colors.popover,
              border: s?.borderColor ?? colors.border,
              radius: s?.borderRadius ?? theme.radii.lg,
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

/// The shared toast surface decoration: a superelliptical border over [fill]
/// with the large shadow. Used by the front toast and each rear pile card so
/// their shapes stay in lockstep.
ShapeDecoration _toastDecoration(
  FossThemeData theme, {
  required Color fill,
  required Color border,
  required double radius,
}) {
  return ShapeDecoration(
    color: fill,
    shape: RoundedSuperellipseBorder(
      side: BorderSide(color: border),
      borderRadius: BorderRadius.circular(radius),
    ),
    shadows: theme.shadows.lg,
  );
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

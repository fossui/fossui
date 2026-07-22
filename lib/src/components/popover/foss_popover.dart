import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/foss_theme.dart';

part 'foss_popover_style.dart';

/// Scale the surface grows from on open.
const double _openScale = 0.98;

/// The scrim tint behind a modal surface: black at 32% opacity, matching the
/// dialog and drawer barrier.
const Color _scrimColor = Color(0x52000000);

/// The side of the trigger a [FossPopover] prefers to open on. The surface
/// flips to the opposite side when it would overflow the viewport.
enum FossPopoverSide {
  /// Above the trigger.
  top,

  /// Below the trigger.
  bottom,

  /// The start side of the trigger; mirrors to the right under RTL.
  left,

  /// The end side of the trigger; mirrors to the left under RTL.
  right,
}

/// How the surface aligns to the trigger along the cross axis of its
/// [FossPopoverSide].
enum FossPopoverAlign {
  /// Flush with the trigger's leading edge.
  start,

  /// Centered on the trigger.
  center,

  /// Flush with the trigger's trailing edge.
  end,
}

/// Drives a [FossPopover] imperatively, so content inside the surface can open,
/// close, or toggle it without threading callbacks through the tree. Works in
/// both the controlled and uncontrolled modes.
///
/// The controller holds no disposable resources; create one per popover and let
/// it go out of scope with the widget.
///
/// ```dart
/// final controller = FossPopoverController();
/// // Inside the content builder:
/// FossButton(onPressed: controller.close, child: const Text('Done'));
/// ```
class FossPopoverController {
  _FossPopoverState? _state;

  void _detach(_FossPopoverState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Whether the popover is currently open.
  bool get isOpen => _state?._isOpen ?? false;

  /// Opens the popover.
  void open() => _state?._setOpen(true);

  /// Closes the popover.
  void close() => _state?._setOpen(false);

  /// Toggles the popover between open and closed.
  void toggle() => _state?._toggle();
}

/// {@category Overlays}
/// {@template foss.popover.preview}
/// <img src="https://fossui.org/components/popover/overview/light.png"
///   alt="FossPopover, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/popover/overview/dark.png"
///   alt="FossPopover, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [popover documentation ↗](https://fossui.org/docs/components/popover) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/popover/fosspopover/playground).
/// {@endtemplate}
///
/// An interactive floating panel anchored to a [child] trigger. Tapping the
/// trigger opens a surface built by [builder] on the preferred [side] and
/// [align]; the surface flips and clamps to stay on screen, and an outside tap
/// or `Escape` dismisses it (when [dismissible]).
///
/// Drive the open state in one of three ways: leave it uncontrolled and let the
/// popover manage itself, control it with [open] plus [onOpenChange], or reach
/// for a [FossPopoverController]. The [controller] works in either mode, so
/// content can close the surface itself.
///
/// Non-modal by default: focus moves into the surface and the background stays
/// interactive. Set [modal] for a scrim and a focus trap. Colors, radius, and
/// shadow resolve from the theme; pass a [style] for a one-off override.
///
/// {@macro foss.customize}
///
/// See also `FossTooltip` for a small, non-interactive hint.
///
/// ```dart
/// FossPopover(
///   builder: (context) => const Padding(
///     padding: EdgeInsets.all(8),
///     child: Text('Anchored content'),
///   ),
///   child: FossButton(child: const Text('Open')),
/// );
/// ```
@FossSince('0.1.1')
class FossPopover extends StatefulWidget {
  /// {@macro foss.popover.preview}
  ///
  /// Creates a popover anchored to [child], showing [builder] when open.
  const FossPopover({
    required this.builder,
    required this.child,
    this.controller,
    this.open,
    this.onOpenChange,
    this.side = FossPopoverSide.bottom,
    this.align = FossPopoverAlign.center,
    this.sideOffset = kAnchorSideOffset,
    this.alignOffset = 0,
    this.modal = false,
    this.dismissible = true,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// Builds the surface content, lazily when open. Free to call [controller] to
  /// close the popover.
  final WidgetBuilder builder;

  /// The trigger. Rendered as-is and used as the anchor; tapping it toggles the
  /// popover.
  final Widget child;

  /// Imperative handle for open, close, and toggle. Optional.
  final FossPopoverController? controller;

  /// The controlled open state. Non-null puts the popover in controlled mode:
  /// pair it with [onOpenChange] and rebuild on change. Null is uncontrolled.
  final bool? open;

  /// Called with the requested open state on every open or close, including
  /// dismissals. Required to observe changes in controlled mode.
  final ValueChanged<bool>? onOpenChange;

  /// The preferred side to open on. Defaults to [FossPopoverSide.bottom].
  final FossPopoverSide side;

  /// The cross-axis alignment to the trigger. Defaults to
  /// [FossPopoverAlign.center].
  final FossPopoverAlign align;

  /// The gap from the trigger along the main axis, in logical pixels.
  final double sideOffset;

  /// The shift along the cross axis, in logical pixels.
  final double alignOffset;

  /// Whether to draw a scrim behind the surface and trap focus inside it.
  /// Defaults to false (non-modal).
  final bool modal;

  /// Whether an outside tap or `Escape` dismisses the popover. Default true.
  final bool dismissible;

  /// Accessible name for the surface. Announced with its dialog role.
  final String? semanticsLabel;

  /// Per-instance visual overrides for the surface.
  final FossPopoverStyle? style;

  @override
  State<FossPopover> createState() => _FossPopoverState();
}

class _FossPopoverState extends State<FossPopover>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'FossPopover trigger');
  final FocusScopeNode _surfaceScope = FocusScopeNode(
    debugLabel: 'FossPopover surface',
  );
  final Object _tapGroup = Object();
  final List<ScrollPosition> _scrollPositions = <ScrollPosition>[];

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  /// The uncontrolled open state; ignored when [FossPopover.open] is non-null.
  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._state = this;
    // Duration is set from the motion token on every forward/reverse.
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: _openScale, end: 1).animate(_curve);
    if (widget.open ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _show();
      });
    }
  }

  @override
  void didUpdateWidget(FossPopover old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._detach(this);
      widget.controller?._state = this;
    }
    // In controlled mode the parent owns the state; sync the surface to it
    // after the frame, since driving the overlay during a build is unsafe.
    final target = widget.open;
    if (target != null && target != old.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isOpen != target) return;
        target ? _show() : _hide();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(this);
    _detachScrollDismiss();
    _curve.dispose();
    _animation.dispose();
    _triggerFocus.dispose();
    _surfaceScope.dispose();
    super.dispose();
  }

  // The Android system back closes the popover rather than popping the route.
  @override
  Future<bool> didPopRoute() async {
    if (!_isOpen) return false;
    _dismiss();
    return true;
  }

  bool get _isOpen => widget.open ?? _open;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _duration => context.fossTheme.motion.overlay;

  void _toggle() => _setOpen(!_isOpen);

  /// The single entry point for every open and close request. Fires
  /// [FossPopover.onOpenChange]; in controlled mode the parent drives the
  /// surface through [didUpdateWidget], otherwise this owns the state.
  void _setOpen(bool next) {
    if (next == _isOpen) return;
    widget.onOpenChange?.call(next);
    if (widget.open != null) return;
    setState(() => _open = next);
    next ? _show() : _hide();
  }

  /// Closes on an outside tap, `Escape`, or a scroll, when dismissible.
  void _dismiss() {
    if (widget.dismissible) _setOpen(false);
  }

  void _show() {
    if (_portal.isShowing) return;
    _portal.show();
    _attachScrollDismiss();
    _animation.duration = _reduceMotion ? Duration.zero : _duration;
    unawaited(_animation.forward(from: _reduceMotion ? 1 : 0));
    // Move focus into the surface once it has mounted: the first focusable
    // content, or the surface scope itself when the content has none.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_portal.isShowing) return;
      final focusable = _surfaceScope.traversalDescendants.where(
        (node) => node.canRequestFocus && !node.skipTraversal,
      );
      (focusable.isEmpty ? _surfaceScope : focusable.first).requestFocus();
    });
  }

  void _hide() {
    _detachScrollDismiss();
    // Only pull focus back to the trigger when it still lives in the surface;
    // a programmatic close must not steal focus the user moved elsewhere.
    if (_surfaceScope.hasFocus) _triggerFocus.requestFocus();
    if (_reduceMotion) {
      _animation.value = 0;
      _portal.hide();
      return;
    }
    _animation.duration = _duration;
    unawaited(
      _animation.reverse().whenComplete(() {
        if (mounted && _animation.status == AnimationStatus.dismissed) {
          _portal.hide();
        }
      }),
    );
  }

  // React when any enclosing scrollable moves, so the surface never floats
  // detached from its trigger: a dismissible popover closes, a non-dismissible
  // one follows the trigger. Every ancestor is tracked, not just the nearest.
  void _onScroll() {
    if (!_isOpen) return;
    if (widget.dismissible) {
      _setOpen(false);
    } else {
      // Reposition against the moved anchor.
      setState(() {});
    }
  }

  void _attachScrollDismiss() {
    for (
      var scrollable = Scrollable.maybeOf(context);
      scrollable != null;
      scrollable = Scrollable.maybeOf(scrollable.context)
    ) {
      scrollable.position.addListener(_onScroll);
      _scrollPositions.add(scrollable.position);
    }
  }

  void _detachScrollDismiss() {
    for (final position in _scrollPositions) {
      position.removeListener(_onScroll);
    }
    _scrollPositions.clear();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !_isOpen) {
      return KeyEventResult.ignored;
    }
    if (widget.dismissible) {
      _dismiss();
      return KeyEventResult.handled;
    }
    // A modal traps Escape behind its scrim, so it never reaches the app; a
    // non-modal, non-dismissible popover lets Escape propagate.
    return widget.modal ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  Rect? _anchorRect(BuildContext overlayContext) {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(overlayContext).context.findRenderObject();
    if (anchor is! RenderBox || overlay is! RenderBox || !anchor.attached) {
      return null;
    }
    return anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
  }

  Widget _buildOverlay(BuildContext context) {
    final anchor = _anchorRect(context);
    if (anchor == null) return const SizedBox.shrink();
    final direction = Directionality.of(context);
    final side = _anchorSide(widget.side, direction);
    // Only the horizontal cross axis (top/bottom sides) mirrors under RTL.
    final mirror =
        direction == TextDirection.rtl &&
        (side == AnchorSide.top || side == AnchorSide.bottom);

    final surface = Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: AnchoredLayout(
          anchor: anchor,
          side: side,
          align: mirror ? _flipAlign(widget.align) : _anchorAlign(widget.align),
          sideOffset: widget.sideOffset,
          alignOffset: mirror ? -widget.alignOffset : widget.alignOffset,
        ),
        child: FadeTransition(
          opacity: _curve,
          child: ScaleTransition(scale: _scale, child: _surfaceContent()),
        ),
      ),
    );

    if (!widget.modal) return surface;
    return Stack(
      children: [
        const Positioned.fill(child: BlockSemantics()),
        Positioned.fill(
          child: _Scrim(animation: _curve, onTap: _dismiss),
        ),
        surface,
      ],
    );
  }

  Widget _surfaceContent() {
    // The FocusScope traps Tab inside the surface for a modal popover; a
    // non-modal one leaves the background interactive, so Tab can exit.
    // Non-modal dismisses on an outside tap via TapRegion.
    _surfaceScope.traversalEdgeBehavior = widget.modal
        ? TraversalEdgeBehavior.closedLoop
        : TraversalEdgeBehavior.leaveFlutterView;
    return FocusScope(
      node: _surfaceScope,
      onKeyEvent: _onKey,
      child: TapRegion(
        groupId: _tapGroup,
        onTapOutside: widget.modal ? null : (_) => _dismiss(),
        child: _PopoverSurface(
          builder: widget.builder,
          style: widget.style,
          semanticsLabel: widget.semanticsLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: KeyedSubtree(key: _anchorKey, child: widget.child),
    );
    // Membership in the same tap group as the surface so a tap on the trigger
    // is never treated as an outside tap by the surface's TapRegion.
    trigger = TapRegion(groupId: _tapGroup, child: trigger);
    trigger = Focus(focusNode: _triggerFocus, child: trigger);

    return Semantics(
      button: true,
      expanded: _isOpen,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildOverlay,
        child: trigger,
      ),
    );
  }
}

/// The floating surface: popover fill, 1px border, softened drop shadow, an
/// inset highlight ring, and the [builder] content under a padded, clipped box.
class _PopoverSurface extends StatelessWidget {
  const _PopoverSurface({
    required this.builder,
    required this.style,
    required this.semanticsLabel,
  });

  final WidgetBuilder builder;
  final FossPopoverStyle? style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: s?.borderColor ?? colors.border),
      borderRadius: BorderRadius.circular(s?.borderRadius ?? theme.radii.lg),
    );

    return Semantics(
      role: SemanticsRole.dialog,
      container: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: s?.backgroundColor ?? colors.popover,
          shape: shape,
          shadows: s?.shadows ?? overlaySoftShadow(theme.shadows.lg),
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: shape,
            textDirection: Directionality.of(context),
          ),
          child: Stack(
            children: [
              Padding(
                padding: s?.padding ?? EdgeInsets.all(theme.spacing(4)),
                child: DefaultTextStyle.merge(
                  style: theme.typography.sm.copyWith(
                    color: s?.foregroundColor ?? colors.popoverForeground,
                  ),
                  child: Builder(builder: builder),
                ),
              ),
              // Purely decorative, and above the content, so it must not
              // intercept taps meant for interactive children.
              Positioned.fill(
                child: IgnorePointer(child: OverlayInnerRing(colors: colors)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tinted, tap-dismissable scrim behind a modal surface, fading on the open
/// animation. Opaque to pointers so the background never takes a stray tap.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.animation, required this.onTap});

  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FadeTransition(
        opacity: animation,
        child: const ColoredBox(color: _scrimColor),
      ),
    );
  }
}

/// Maps the directional [FossPopoverSide] to a physical [AnchorSide], mirroring
/// [FossPopoverSide.left] and [FossPopoverSide.right] under RTL.
AnchorSide _anchorSide(FossPopoverSide side, TextDirection direction) {
  final mirror = direction == TextDirection.rtl;
  return switch (side) {
    FossPopoverSide.top => AnchorSide.top,
    FossPopoverSide.bottom => AnchorSide.bottom,
    FossPopoverSide.left => mirror ? AnchorSide.right : AnchorSide.left,
    FossPopoverSide.right => mirror ? AnchorSide.left : AnchorSide.right,
  };
}

AnchorAlign _anchorAlign(FossPopoverAlign align) => switch (align) {
  FossPopoverAlign.start => AnchorAlign.start,
  FossPopoverAlign.center => AnchorAlign.center,
  FossPopoverAlign.end => AnchorAlign.end,
};

AnchorAlign _flipAlign(FossPopoverAlign align) => switch (align) {
  FossPopoverAlign.start => AnchorAlign.end,
  FossPopoverAlign.center => AnchorAlign.center,
  FossPopoverAlign.end => AnchorAlign.start,
};

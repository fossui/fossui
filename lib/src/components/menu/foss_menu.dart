import 'dart:async';

import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part '_foss_menu_panel.dart';
part 'foss_menu_item.dart';
part 'foss_menu_style.dart';
part 'foss_menu_visuals.dart';

/// Smallest panel width. The panel grows past it to fit its widest row.
const double _minPanelWidth = 128;

/// Row height floor. A row grows past it at a larger text scale.
const double _rowMinHeight = 32;

/// Glyph size in a row's icon slot.
const double _iconSize = 18;

/// Start inset of a row that lines its text up with the glyph rows above it.
const double _insetStart = 32;

/// Start inset of a group heading, a step wider than a row's so the heading
/// sits above the text rather than above the glyph.
const double _labelInsetStart = 36;

const double _separatorThickness = 1;

const double _disabledOpacity = 0.64;

/// A row glyph reads a step quieter than the label beside it.
const double _iconOpacity = 0.8;

/// A shortcut reads quieter again, behind the label it belongs to.
const double _shortcutOpacity = 0.72;

/// Scale the panel grows from on open.
const double _openScale = 0.98;

/// The side of the trigger a [FossMenu] prefers to open on. The panel flips to
/// the opposite side when it would overflow the viewport.
enum FossMenuSide {
  /// Above the trigger.
  top,

  /// Below the trigger.
  bottom,

  /// The start side of the trigger; mirrors to the right under RTL.
  left,

  /// The end side of the trigger; mirrors to the left under RTL.
  right,
}

/// How the panel aligns to the trigger along the cross axis of its
/// [FossMenuSide].
enum FossMenuAlign {
  /// Flush with the trigger's leading edge.
  start,

  /// Centered on the trigger.
  center,

  /// Flush with the trigger's trailing edge.
  end,
}

/// Drives a [FossMenu] imperatively, so a trigger that handles its own taps can
/// still open the panel. A `FossButton` is the common case: its `onPressed`
/// wins the tap, so wire that callback to [toggle] instead of relying on the
/// menu's own trigger gesture.
///
/// The controller holds no disposable resources; create one per menu and let it
/// go out of scope with the widget.
///
/// ```dart
/// final controller = FossMenuController();
/// FossMenu(
///   controller: controller,
///   items: items,
///   child: FossButton(
///     onPressed: controller.toggle,
///     child: const Text('Actions'),
///   ),
/// );
/// ```
@FossSince('0.1.3')
class FossMenuController {
  _FossMenuState? _state;

  void _detach(_FossMenuState state) {
    if (identical(_state, state)) _state = null;
  }

  /// Whether the panel is currently open.
  bool get isOpen => _state?._open ?? false;

  /// Opens the panel.
  void open() => _state?._openPanel();

  /// Closes the panel.
  void close() => _state?._close();

  /// Opens the panel when it is closed, closes it when it is open.
  void toggle() => isOpen ? close() : open();
}

/// {@category Overlays}
/// {@template foss.menu.preview}
/// <img src="https://fossui.org/components/menu/overview/light.png"
///   alt="FossMenu, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/menu/overview/dark.png"
///   alt="FossMenu, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [menu documentation ↗](https://fossui.org/docs/components/menu) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/menu/fossmenu/playground).
/// {@endtemplate}
///
/// A dropdown menu: a [child] trigger that opens a panel of [items] over the
/// page, each a label with an optional glyph and an optional shortcut, under a
/// highlight that follows the pointer and the arrow keys.
///
/// The panel opens below the trigger and flush with its start edge, flips above
/// when there is no room, clamps inside the viewport, and scrolls internally
/// when a long list still does not fit. Tapping a row runs its
/// [FossMenuItem.onSelected] and closes the panel; a row without one does
/// nothing and stays open. `ArrowUp` and `ArrowDown` move the highlight and
/// wrap, `Enter` and `Space` select, and `Escape` or a tap outside closes and
/// returns focus to the trigger.
///
/// A trigger that handles its own taps, a `FossButton` with an `onPressed` for
/// instance, wins the gesture, so the menu never sees it. Give the menu a
/// [FossMenuController] and point that callback at [FossMenuController.toggle].
/// A trigger that takes no input of its own needs no controller.
///
/// Pass [FossMenuItem.separator] and [FossMenuItem.label] inside [items] to
/// divide and head groups of rows. Colors, radius, and type come from
/// `context.fossTheme`; pass a [FossMenuStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// See also FossPopover for a panel of arbitrary content rather than rows.
///
/// ```dart
/// final controller = FossMenuController();
///
/// FossMenu(
///   controller: controller,
///   items: [
///     FossMenuItem(label: 'New file', shortcut: 'Ctrl N', onSelected: create),
///     const FossMenuItem.separator(),
///     FossMenuItem(label: 'Delete', destructive: true, onSelected: remove),
///   ],
///   child: FossButton(
///     onPressed: controller.toggle,
///     child: const Text('Actions'),
///   ),
/// );
/// ```
@FossSince('0.1.3')
class FossMenu extends StatefulWidget {
  /// {@macro foss.menu.preview}
  ///
  /// Creates a menu anchored to [child], showing [items] when open.
  const FossMenu({
    required this.items,
    required this.child,
    this.controller,
    this.side = FossMenuSide.bottom,
    this.align = FossMenuAlign.start,
    this.onOpenChange,
    this.style,
    super.key,
  });

  /// The rows, in order. Action rows, separators, and group headings all live
  /// in this one list.
  final List<FossMenuItem> items;

  /// The trigger. Rendered as-is and used as the anchor; tapping it opens the
  /// panel, unless the trigger handles the tap itself.
  ///
  /// The panel anchors to the box this widget occupies, not to what it paints
  /// inside it. A trigger stretched by its parent, a list child for instance,
  /// anchors the panel to the full width; wrap it in an `Align` to anchor to
  /// the trigger itself.
  final Widget child;

  /// Imperative handle for open, close, and toggle. Needed when [child]
  /// consumes its own taps.
  final FossMenuController? controller;

  /// The preferred side to open on. Defaults to [FossMenuSide.bottom].
  final FossMenuSide side;

  /// The cross-axis alignment to the trigger. Defaults to
  /// [FossMenuAlign.start], because rows of start-aligned text read wrong
  /// centered under a trigger.
  final FossMenuAlign align;

  /// Called with the new state on every open and close, including dismissals.
  final ValueChanged<bool>? onOpenChange;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossMenuStyle? style;

  @override
  State<FossMenu> createState() => _FossMenuState();
}

class _FossMenuState extends State<FossMenu>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'FossMenu trigger');
  final FocusScopeNode _panelScope = FocusScopeNode(
    debugLabel: 'FossMenu panel scope',
  );
  final List<ScrollPosition> _scrollPositions = <ScrollPosition>[];

  late final AnimationController _animation;
  late final CurvedAnimation _curve;

  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._state = this;
    // Duration is set from the motion token on every forward and reverse.
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(FossMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._state = this;
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
    _panelScope.dispose();
    super.dispose();
  }

  // The Android system back closes the panel rather than popping the route.
  @override
  Future<bool> didPopRoute() async {
    if (!_open) return false;
    _close();
    return true;
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _duration => context.fossTheme.motion.overlay;

  void _openPanel() {
    if (_open) return;
    setState(() => _open = true);
    widget.onOpenChange?.call(true);
    _portal.show();
    _attachScrollDismiss();
    _animation.duration = _reduceMotion ? Duration.zero : _duration;
    _animation.forward(from: _reduceMotion ? 1 : 0);
  }

  void _close() {
    if (!_open) return;
    _detachScrollDismiss();
    setState(() => _open = false);
    widget.onOpenChange?.call(false);
    // Only pull focus back when it still sits in the panel, so a programmatic
    // close never steals focus the user moved elsewhere.
    if (_panelScope.hasFocus) _triggerFocus.requestFocus();
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

  /// Runs a selected row's action, then closes. A row without an action leaves
  /// the panel open: closing on a row that did nothing reads as a cancel the
  /// caller never asked for.
  void _selected(int index) {
    final action = widget.items[index].onSelected;
    if (action == null) return;
    action();
    _close();
  }

  // Close when any enclosing scrollable moves, so the panel never floats
  // detached from its trigger. Every ancestor is tracked, not just the
  // nearest, so a page swipe dismisses it even inside a nested scroll view.
  void _attachScrollDismiss() {
    for (
      var scrollable = Scrollable.maybeOf(context);
      scrollable != null;
      scrollable = Scrollable.maybeOf(scrollable.context)
    ) {
      scrollable.position.addListener(_close);
      _scrollPositions.add(scrollable.position);
    }
  }

  void _detachScrollDismiss() {
    for (final position in _scrollPositions) {
      position.removeListener(_close);
    }
    _scrollPositions.clear();
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
    // Only the horizontal cross axis (the top and bottom sides) mirrors.
    final mirror =
        direction == TextDirection.rtl &&
        (side == AnchorSide.top || side == AnchorSide.bottom);

    // Positioned.fill on the outside, so the stack is laid out against the
    // overlay rather than against its own children. An overlay that hands out
    // loose constraints would otherwise collapse a bare stack of positioned
    // children to nothing, and the panel would land on the trigger.
    return Positioned.fill(
      child: Stack(
        children: [
          // The barrier takes the tap that dismisses the panel, including a
          // second tap on the trigger underneath it.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          FocusScope(
            node: _panelScope,
            child: _FossMenuPanel(
              items: widget.items,
              anchor: anchor,
              side: side,
              align: mirror
                  ? _flipAlign(widget.align)
                  : _anchorAlign(widget.align),
              animation: _curve,
              sideOffset: kAnchorSideOffset,
              onSelected: _selected,
              onDismiss: _close,
              style: widget.style,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = Focus(
      focusNode: _triggerFocus,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openPanel,
        child: KeyedSubtree(key: _anchorKey, child: widget.child),
      ),
    );

    return Semantics(
      button: true,
      expanded: _open,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildOverlay,
        child: trigger,
      ),
    );
  }
}

/// Maps the directional [FossMenuSide] to a physical [AnchorSide], mirroring
/// [FossMenuSide.left] and [FossMenuSide.right] under RTL.
AnchorSide _anchorSide(FossMenuSide side, TextDirection direction) {
  final mirror = direction == TextDirection.rtl;
  return switch (side) {
    FossMenuSide.top => AnchorSide.top,
    FossMenuSide.bottom => AnchorSide.bottom,
    FossMenuSide.left => mirror ? AnchorSide.right : AnchorSide.left,
    FossMenuSide.right => mirror ? AnchorSide.left : AnchorSide.right,
  };
}

AnchorAlign _anchorAlign(FossMenuAlign align) => switch (align) {
  FossMenuAlign.start => AnchorAlign.start,
  FossMenuAlign.center => AnchorAlign.center,
  FossMenuAlign.end => AnchorAlign.end,
};

AnchorAlign _flipAlign(FossMenuAlign align) => switch (align) {
  FossMenuAlign.start => AnchorAlign.end,
  FossMenuAlign.center => AnchorAlign.center,
  FossMenuAlign.end => AnchorAlign.start,
};

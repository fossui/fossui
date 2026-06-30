import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/colors/foss_colors.dart';
import 'package:foss_ui/src/theme/foss_theme.dart';

part 'foss_tooltip_style.dart';

/// Gap between the popup and the anchor, in logical pixels.
const double _sideOffset = 4;

/// Keeps the popup this far off the viewport edge when it would overflow.
const double _viewportMargin = 8;

/// Vertical padding inside the popup (coss `py-1`).
const double _verticalPadding = 4;

/// Scale the popup grows from on open (coss `scale-98`).
const double _openScale = 0.98;

/// The side of the anchor a [FossTooltip] prefers to open on. The popup flips
/// to the opposite side when it would overflow the viewport.
enum FossTooltipSide {
  /// Above the anchor.
  top,

  /// Below the anchor.
  bottom,

  /// The start side of the anchor; mirrors to the right edge under RTL.
  left,

  /// The end side of the anchor; mirrors to the left edge under RTL.
  right,
}

/// Wraps a [child] trigger and shows a small floating hint next to it on hover,
/// keyboard focus, or long-press, dismissing on exit, blur, `Escape`, or after
/// [hideDelay].
///
/// The hint is text only ([message]) and non-interactive: it never blocks
/// pointer input and is announced through the trigger's tooltip semantics, so
/// the visible popup stays out of the semantics tree. The popup opens on [side]
/// and flips to the opposite side to stay on screen. Colors, type, radius, and
/// shadow resolve from the theme; pass a [style] for a one-off override.
///
/// ```dart
/// FossTooltip(
///   message: 'Copy link',
///   child: FossButton(
///     onPressed: copy,
///     child: const Icon(LucideIcons.copy),
///   ),
/// );
/// ```
class FossTooltip extends StatefulWidget {
  /// Creates a tooltip wrapping [child] that shows [message] on demand.
  const FossTooltip({
    required this.message,
    required this.child,
    this.side = FossTooltipSide.top,
    this.showDelay = const Duration(milliseconds: 500),
    this.hideDelay = Duration.zero,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The hint text shown in the popup.
  final String message;

  /// The trigger. Rendered as-is; the tooltip adds no visual to it.
  final Widget child;

  /// The preferred side to open on. Defaults to [FossTooltipSide.top].
  final FossTooltipSide side;

  /// Delay before the popup appears after the trigger activates.
  final Duration showDelay;

  /// Delay before the popup dismisses after the trigger ends.
  final Duration hideDelay;

  /// Overrides the announced text when it should differ from [message].
  final String? semanticsLabel;

  /// Per-instance visual overrides.
  final FossTooltipStyle? style;

  @override
  State<FossTooltip> createState() => _FossTooltipState();
}

class _FossTooltipState extends State<FossTooltip>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: _openScale, end: 1).animate(_curve);
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  Duration get _duration {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return reduceMotion ? Duration.zero : context.fossTheme.motion.overlay;
  }

  void _requestShow() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_portal.isShowing) {
      _animation.duration = _duration;
      unawaited(_animation.forward());
      return;
    }
    _showTimer ??= Timer(widget.showDelay, () {
      _showTimer = null;
      if (!mounted) return;
      _portal.show();
      _animation.duration = _duration;
      unawaited(_animation.forward(from: 0));
    });
  }

  void _requestHide() {
    _showTimer?.cancel();
    _showTimer = null;
    if (!_portal.isShowing) return;
    _hideTimer ??= Timer(widget.hideDelay, _close);
  }

  /// Dismisses immediately, bypassing the hide delay (the `Escape` path).
  void _dismiss() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_portal.isShowing) _close();
  }

  void _close() {
    _hideTimer = null;
    if (!mounted) return;
    _animation.duration = _duration;
    unawaited(
      _animation.reverse().whenComplete(() {
        if (mounted && _animation.status == AnimationStatus.dismissed) {
          _portal.hide();
        }
      }),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _portal.isShowing) {
      _dismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
    return Positioned.fill(
      // The hint never intercepts input; it floats above the page.
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipLayout(
            anchor: anchor,
            side: _physicalSide(widget.side, Directionality.of(context)),
          ),
          child: FadeTransition(
            opacity: _curve,
            child: ScaleTransition(
              scale: _scale,
              child: _TooltipPopup(
                message: widget.message,
                style: widget.style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = GestureDetector(
      onLongPress: _requestShow,
      child: widget.child,
    );
    trigger = MouseRegion(
      onEnter: (_) => _requestShow(),
      onExit: (_) => _requestHide(),
      child: trigger,
    );
    trigger = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) => hasFocus ? _requestShow() : _requestHide(),
      onKeyEvent: _onKey,
      child: KeyedSubtree(key: _anchorKey, child: trigger),
    );

    return Semantics(
      tooltip: widget.semanticsLabel ?? widget.message,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildOverlay,
        child: trigger,
      ),
    );
  }
}

/// Positions the popup against the anchor, flipping to the opposite side and
/// clamping into the viewport so it never overflows the screen.
class _TooltipLayout extends SingleChildLayoutDelegate {
  _TooltipLayout({required this.anchor, required this.side});

  final Rect anchor;
  final FossTooltipSide side;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - _viewportMargin * 2,
        maxHeight: constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final position = _place(child, _resolveSide(size, child));
    return Offset(
      _clamp(position.dx, size.width - child.width),
      _clamp(position.dy, size.height - child.height),
    );
  }

  /// Keeps [value] within `[margin, upper]`, collapsing to the margin when the
  /// child is larger than the available room.
  double _clamp(double value, double upper) {
    final hi = upper - _viewportMargin;
    return hi < _viewportMargin
        ? _viewportMargin
        : value.clamp(_viewportMargin, hi);
  }

  Offset _place(Size child, FossTooltipSide side) => switch (side) {
    FossTooltipSide.top => Offset(
      anchor.center.dx - child.width / 2,
      anchor.top - _sideOffset - child.height,
    ),
    FossTooltipSide.bottom => Offset(
      anchor.center.dx - child.width / 2,
      anchor.bottom + _sideOffset,
    ),
    FossTooltipSide.left => Offset(
      anchor.left - _sideOffset - child.width,
      anchor.center.dy - child.height / 2,
    ),
    FossTooltipSide.right => Offset(
      anchor.right + _sideOffset,
      anchor.center.dy - child.height / 2,
    ),
  };

  FossTooltipSide _resolveSide(Size size, Size child) {
    bool fitsTop() =>
        anchor.top - _sideOffset - child.height >= _viewportMargin;
    bool fitsBottom() =>
        anchor.bottom + _sideOffset + child.height <=
        size.height - _viewportMargin;
    bool fitsLeft() =>
        anchor.left - _sideOffset - child.width >= _viewportMargin;
    bool fitsRight() =>
        anchor.right + _sideOffset + child.width <=
        size.width - _viewportMargin;

    return switch (side) {
      FossTooltipSide.top when !fitsTop() && fitsBottom() =>
        FossTooltipSide.bottom,
      FossTooltipSide.bottom when !fitsBottom() && fitsTop() =>
        FossTooltipSide.top,
      FossTooltipSide.left when !fitsLeft() && fitsRight() =>
        FossTooltipSide.right,
      FossTooltipSide.right when !fitsRight() && fitsLeft() =>
        FossTooltipSide.left,
      _ => side,
    };
  }

  @override
  bool shouldRelayout(_TooltipLayout old) =>
      old.anchor != anchor || old.side != side;
}

/// The resting popup: popover surface, 1px border, drop shadow, an inset
/// highlight ring, and the centered hint text.
class _TooltipPopup extends StatelessWidget {
  const _TooltipPopup({required this.message, required this.style});

  final String message;
  final FossTooltipStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: s?.borderColor ?? colors.border),
      borderRadius: BorderRadius.circular(s?.borderRadius ?? theme.radii.md),
    );
    final textStyle = theme.typography.xs
        .copyWith(color: s?.foregroundColor ?? colors.popoverForeground)
        .merge(s?.textStyle);

    // The text is announced on the trigger; the popup stays out of semantics.
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: s?.backgroundColor ?? colors.popover,
          shape: shape,
          shadows: s?.shadows ?? theme.shadows.md,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: shape,
            textDirection: Directionality.of(context),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: _verticalPadding,
                  horizontal: theme.spacing(2),
                ),
                child: Text(
                  message,
                  style: textStyle,
                  textAlign: TextAlign.center,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
              ),
              Positioned.fill(child: _InnerRing(colors: colors)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised-edge highlight inside the border: a top line in light mode, a
/// bottom line in dark mode, derived from the foreground role at low alpha.
class _InnerRing extends StatelessWidget {
  const _InnerRing({required this.colors});

  final FossColors colors;

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(colors);
    final highlight = colors.foreground.withValues(alpha: dark ? 0.06 : 0.04);
    final edge = BorderSide(color: highlight);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: dark ? BorderSide.none : edge,
          bottom: dark ? edge : BorderSide.none,
        ),
      ),
    );
  }
}

/// Maps the directional [FossTooltipSide] to a physical side, mirroring
/// [FossTooltipSide.left] and [FossTooltipSide.right] under RTL.
FossTooltipSide _physicalSide(FossTooltipSide side, TextDirection direction) {
  if (direction == TextDirection.ltr) return side;
  return switch (side) {
    FossTooltipSide.left => FossTooltipSide.right,
    FossTooltipSide.right => FossTooltipSide.left,
    FossTooltipSide.top || FossTooltipSide.bottom => side,
  };
}

bool _isDark(FossColors c) => c.background.computeLuminance() < 0.5;

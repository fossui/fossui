import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/dialog/foss_dialog.dart';
import 'package:fossui/src/foundation/foss_dialog_surface.dart'
    show dialogRouteLabel;
import 'package:fossui/src/foundation/foss_modal_route.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/radii/foss_radii.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

part 'foss_drawer_style.dart';

/// Maximum width of a side panel in logical pixels.
const double _sidePanelMaxWidth = 448;

/// Pill dimensions of the drag handle, long axis by short axis.
const double _handleLong = 48;
const double _handleShort = 4;

/// A release past this fraction of the panel extent dismisses it.
const double _dismissFraction = 0.5;

/// An outward fling at or above this velocity (px/s) dismisses regardless of
/// how far the panel has travelled.
const double _flingVelocity = 700;

/// The edge a [FossDrawer] anchors to and slides in from.
enum FossDrawerSide {
  /// The bottom edge: full width, slides up. The primary mobile shape.
  bottom,

  /// The top edge: full width, slides down.
  top,

  /// The leading edge: a side panel that slides in from the start.
  left,

  /// The trailing edge: a side panel that slides in from the end.
  right,
}

/// The corner treatment of a [FossDrawer] surface.
enum FossDrawerVariant {
  /// Rounded exposed corners (the edge that meets the page).
  rounded,

  /// Square corners on every edge.
  straight,
}

/// The footer treatment of a [FossDrawer].
enum FossDrawerFooterVariant {
  /// No bar: the actions sit on the plain surface.
  bare,

  /// A bordered bar tinted with the muted role behind the actions.
  filled,
}

/// Opens an edge [FossDrawer] and resolves to the value passed to
/// `Navigator.pop`.
///
/// Slides the surface in from [side] over the drawer motion duration, draws the
/// scrim, traps focus, and restores it to the opener on close, all from the
/// shared modal foundation. The active theme is captured and re-provided inside
/// the route. The surface can be dragged back off its edge to dismiss.
///
/// ```dart
/// final applied = await showFossDrawer<bool>(
///   context: context,
///   builder: (context) => FossDrawer(
///     showHandle: true,
///     title: const Text('Filters'),
///     content: const FilterForm(),
///     actions: [
///       FossButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: const Text('Apply'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showFossDrawer<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  FossDrawerSide side = FossDrawerSide.bottom,
  bool barrierDismissible = true,
  String? barrierLabel,
  bool useRootNavigator = true,
}) => showFossModal<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
  useRootNavigator: useRootNavigator,
  transitionDuration: context.fossTheme.motion.drawer,
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      _DrawerSlide(side: side, animation: animation, child: child),
  builder: (context) => _DrawerScope(
    side: side,
    child: Builder(builder: builder),
  ),
);

/// {@category Overlays}
/// {@template foss.drawer.preview}
/// <img src="https://fossui.org/components/drawer/overview/light.png"
///   alt="FossDrawer, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/drawer/overview/dark.png"
///   alt="FossDrawer, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [drawer documentation ↗](https://fossui.org/docs/components/drawer) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/#/?path=components/drawer/fossdrawer/playground).
/// {@endtemplate}
///
/// An edge-anchored modal panel with slots for a title, description, body, and
/// actions, plus an optional drag handle and close affordance.
///
/// Show it with [showFossDrawer], which sets the [FossDrawerSide]; the surface
/// reads the side back from context so its corners, border edge, and drag axis
/// match. The header, body, and footer are each optional; [actions] reuse
/// `FossButton`. Colors, type, radius, and shadow resolve from the theme.
///
/// {@macro foss.customize}
///
/// See also [FossDialog] for a centered or bottom-sheet modal.
///
/// ```dart
/// showFossDrawer<void>(
///   context: context,
///   builder: (context) => const FossDrawer(
///     showHandle: true,
///     title: Text('Details'),
///     content: Text('A panel that slides up from the bottom edge.'),
///   ),
/// );
/// ```
class FossDrawer extends StatelessWidget {
  /// {@macro foss.drawer.preview}
  ///
  /// Creates a drawer surface. Build it inside a [showFossDrawer] `builder`.
  const FossDrawer({
    this.title,
    this.description,
    this.content,
    this.actions = const <Widget>[],
    this.variant = FossDrawerVariant.rounded,
    this.footerVariant = FossDrawerFooterVariant.bare,
    this.showHandle = false,
    this.showCloseButton = false,
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

  /// The corner treatment. Defaults to [FossDrawerVariant.rounded].
  final FossDrawerVariant variant;

  /// The footer treatment. Defaults to [FossDrawerFooterVariant.bare].
  final FossDrawerFooterVariant footerVariant;

  /// Whether to show the drag handle on the exposed edge.
  final bool showHandle;

  /// Whether to show the close affordance in the top corner.
  final bool showCloseButton;

  /// Overrides the default painted close glyph.
  final Widget? closeIcon;

  /// Per-instance visual overrides.
  final FossDrawerStyle? style;

  @override
  Widget build(BuildContext context) {
    final side = _DrawerScope.of(context);
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
    final s = style;

    // Adjacent slots collapse their touching insets so the seam reads as one
    // spacing(4) gap, not two stacked spacing(6) pads: the header drops its
    // bottom pad above content, content drops its touching edges, and the
    // footer keeps its own top pad. A lone slot keeps the full inset.
    final hasHeader = title != null || description != null;
    final hasContent = content != null;
    final hasFooter = actions.isNotEmpty;

    return _DrawerSurface(
      side: side,
      variant: variant,
      footerVariant: footerVariant,
      backgroundColor: s?.backgroundColor ?? colors.popover,
      borderColor: s?.borderColor ?? colors.border,
      borderRadius: s?.borderRadius ?? theme.radii.xl2,
      shadows: s?.shadows ?? theme.shadows.lg,
      showHandle: showHandle,
      semanticLabel: dialogRouteLabel(title),
      header: _buildHeader(theme, colors, s, tightenBottom: hasContent),
      content: content == null
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(
                sp(6),
                hasHeader ? 0 : sp(6),
                sp(6),
                hasFooter ? 0 : sp(6),
              ),
              child: content,
            ),
      actions: actions,
      closeButton: showCloseButton
          ? _CloseButton(icon: closeIcon, color: colors.mutedForeground)
          : null,
    );
  }

  Widget? _buildHeader(
    FossThemeData theme,
    FossColors colors,
    FossDrawerStyle? s, {
    required bool tightenBottom,
  }) {
    if (title == null && description == null) return null;
    final titleStyle = theme.typography.xl.semibold
        .copyWith(color: colors.popoverForeground)
        .merge(s?.titleStyle);
    final descriptionStyle = theme.typography.sm
        .copyWith(color: colors.mutedForeground)
        .merge(s?.descriptionStyle);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing(6),
        theme.spacing(6),
        theme.spacing(6),
        tightenBottom ? theme.spacing(4) : theme.spacing(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing(2),
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

/// Carries the [FossDrawerSide] from [showFossDrawer] down to the [FossDrawer]
/// surface, so the side is set in one place and read in another.
class _DrawerScope extends InheritedWidget {
  const _DrawerScope({required this.side, required super.child});

  final FossDrawerSide side;

  static FossDrawerSide of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DrawerScope>()?.side ??
      FossDrawerSide.bottom;

  @override
  bool updateShouldNotify(_DrawerScope oldWidget) => oldWidget.side != side;
}

/// Slides [child] in from [side] on the route animation, on the drawer curve.
class _DrawerSlide extends StatelessWidget {
  const _DrawerSlide({
    required this.side,
    required this.animation,
    required this.child,
  });

  final FossDrawerSide side;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = switch (side) {
      FossDrawerSide.bottom => const Offset(0, 1),
      FossDrawerSide.top => const Offset(0, -1),
      FossDrawerSide.left => const Offset(-1, 0),
      FossDrawerSide.right => const Offset(1, 0),
    };
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: kSheetCurve),
      ),
      child: child,
    );
  }
}

/// The anchored, drag-dismissable panel: shape, shadow, slots, and the gesture
/// that tracks the finger off the edge.
class _DrawerSurface extends StatefulWidget {
  const _DrawerSurface({
    required this.side,
    required this.variant,
    required this.footerVariant,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.shadows,
    required this.showHandle,
    required this.semanticLabel,
    required this.header,
    required this.content,
    required this.actions,
    required this.closeButton,
  });

  final FossDrawerSide side;
  final FossDrawerVariant variant;
  final FossDrawerFooterVariant footerVariant;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final List<BoxShadow> shadows;
  final bool showHandle;

  /// Names the modal route for assistive technology, from the title text.
  final String? semanticLabel;
  final Widget? header;
  final Widget? content;
  final List<Widget> actions;
  final Widget? closeButton;

  @override
  State<_DrawerSurface> createState() => _DrawerSurfaceState();
}

class _DrawerSurfaceState extends State<_DrawerSurface>
    with SingleTickerProviderStateMixin {
  final GlobalKey _panelKey = GlobalKey();
  late final AnimationController _settle;

  /// Distance the panel has been dragged off its edge, in logical pixels. Held
  /// in a notifier so the drag drives the translate alone, without rebuilding
  /// the panel each frame.
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  double _settleFrom = 0;
  double _settleTo = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this)..addListener(_onSettleTick);
  }

  void _onSettleTick() {
    final t = kSheetCurve.transform(_settle.value);
    _offset.value = _settleFrom + (_settleTo - _settleFrom) * t;
  }

  @override
  void dispose() {
    _settle.dispose();
    _offset.dispose();
    super.dispose();
  }

  /// Maps a positive primary drag delta (down / end) to outward travel.
  double get _outwardSign {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (widget.side) {
      FossDrawerSide.bottom => 1,
      FossDrawerSide.top => -1,
      FossDrawerSide.left => rtl ? 1 : -1,
      FossDrawerSide.right => rtl ? -1 : 1,
    };
  }

  double get _panelExtent {
    final box = _panelKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return 0;
    return _axisOf(widget.side) == Axis.vertical
        ? box.size.height
        : box.size.width;
  }

  void _onDragStart(DragStartDetails _) => _settle.stop();

  void _onDragUpdate(double primaryDelta) {
    final next = _offset.value + primaryDelta * _outwardSign;
    _offset.value = next < 0 ? 0 : next;
  }

  void _onDragEnd(double primaryVelocity) {
    final extent = _panelExtent;
    final outwardVelocity = primaryVelocity * _outwardSign;
    // A non-positive extent means the panel could not be measured; fail safe to
    // spring-back rather than dismissing on any release.
    final offset = _offset.value;
    final dismiss =
        extent > 0 &&
        (offset >= extent * _dismissFraction ||
            outwardVelocity >= _flingVelocity);
    if (dismiss) {
      // Continue off the edge (never animate back inward), then pop.
      final target = offset > extent ? offset : extent;
      _animateTo(target, then: () => Navigator.of(context).maybePop());
    } else {
      _animateTo(0);
    }
  }

  void _animateTo(double target, {VoidCallback? then}) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _settleFrom = _offset.value;
    _settleTo = target;
    _settle
      ..duration = reduceMotion
          ? Duration.zero
          : context.fossTheme.motion.drawer
      ..reset();
    final done = _settle.forward();
    unawaited(then == null ? done : done.whenComplete(then));
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.side;
    final axis = _axisOf(side);
    final ltrSign = _ltrSign;

    Widget panel = ValueListenableBuilder<double>(
      valueListenable: _offset,
      builder: (context, offset, child) {
        final translation = switch (side) {
          FossDrawerSide.bottom => Offset(0, offset),
          FossDrawerSide.top => Offset(0, -offset),
          FossDrawerSide.left => Offset(-offset * ltrSign, 0),
          FossDrawerSide.right => Offset(offset * ltrSign, 0),
        };
        return Transform.translate(offset: translation, child: child);
      },
      child: _buildPanel(context),
    );

    panel = GestureDetector(
      onVerticalDragStart: axis == Axis.vertical ? _onDragStart : null,
      onVerticalDragUpdate: axis == Axis.vertical
          ? (d) => _onDragUpdate(d.primaryDelta ?? 0)
          : null,
      onVerticalDragEnd: axis == Axis.vertical
          ? (d) => _onDragEnd(d.primaryVelocity ?? 0)
          : null,
      onHorizontalDragStart: axis == Axis.horizontal ? _onDragStart : null,
      onHorizontalDragUpdate: axis == Axis.horizontal
          ? (d) => _onDragUpdate(d.primaryDelta ?? 0)
          : null,
      onHorizontalDragEnd: axis == Axis.horizontal
          ? (d) => _onDragEnd(d.primaryVelocity ?? 0)
          : null,
      child: panel,
    );

    return Align(alignment: _alignmentOf(side), child: panel);
  }

  /// The translate axis sign for a side panel, before the RTL flip handled by
  /// the directional anchor: start-anchored panels travel toward lower x.
  double get _ltrSign =>
      Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  /// The system insets the panel must clear on the edges it touches the screen:
  /// the top for every side but bottom, the bottom for every side but top.
  EdgeInsets get _safeInsets {
    final padding = MediaQuery.paddingOf(context);
    return EdgeInsets.only(
      top: widget.side == FossDrawerSide.bottom ? 0 : padding.top,
      bottom: widget.side == FossDrawerSide.top ? 0 : padding.bottom,
    );
  }

  Widget _buildPanel(BuildContext context) {
    final theme = context.fossTheme;
    final side = widget.side;
    final corners = widget.variant == FossDrawerVariant.straight
        ? BorderRadius.zero
        : _exposedCorners(side, widget.borderRadius);
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: widget.borderColor),
      borderRadius: corners,
    );

    final body = ClipPath(
      clipper: ShapeBorderClipper(
        shape: shape,
        textDirection: Directionality.of(context),
      ),
      // Name the route for assistive tech, and keep the title, body, and close
      // affordance as distinct nodes rather than merging into one panel node.
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: widget.semanticLabel,
        explicitChildNodes: true,
        child: Stack(
          children: [
            _buildColumn(theme),
            if (widget.showHandle && _axisOf(side) == Axis.horizontal)
              Align(
                alignment: _exposedEdgeAlignment(side),
                child: _handle(theme, side),
              ),
            if (widget.closeButton case final button?)
              PositionedDirectional(
                top: theme.spacing(2) + _safeInsets.top,
                end: theme.spacing(2),
                child: button,
              ),
          ],
        ),
      ),
    );

    final decorated = DecoratedBox(
      decoration: ShapeDecoration(
        color: widget.backgroundColor,
        shape: shape,
        shadows: widget.shadows,
      ),
      child: body,
    );

    return KeyedSubtree(
      key: _panelKey,
      child: _axisOf(side) == Axis.vertical
          ? decorated
          : LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth - theme.spacing(12);
                final width = available < _sidePanelMaxWidth
                    ? available
                    : _sidePanelMaxWidth;
                return SizedBox(width: width, child: decorated);
              },
            ),
    );
  }

  Widget _buildColumn(FossThemeData theme) {
    final side = widget.side;
    final vertical = _axisOf(side) == Axis.vertical;
    final handleInline = widget.showHandle && vertical;
    final insets = _safeInsets;

    return Column(
      mainAxisSize: vertical ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (insets.top > 0) SizedBox(height: insets.top),
        if (handleInline && side == FossDrawerSide.bottom) _handle(theme, side),
        ?widget.header,
        if (widget.content case final content?)
          Flexible(child: SingleChildScrollView(child: content)),
        if (widget.actions.isNotEmpty)
          _Footer(
            variant: widget.footerVariant,
            safeBottom: insets.bottom,
            actions: widget.actions,
          )
        else if (insets.bottom > 0)
          SizedBox(height: insets.bottom),
        if (handleInline && side == FossDrawerSide.top) _handle(theme, side),
      ],
    );
  }

  Widget _handle(FossThemeData theme, FossDrawerSide side) {
    final vertical = _axisOf(side) == Axis.vertical;
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing(3)),
        child: Align(
          child: SizedBox(
            width: vertical ? _handleLong : _handleShort,
            height: vertical ? _handleShort : _handleLong,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.input,
                borderRadius: BorderRadius.circular(FossRadii.full),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.variant,
    required this.safeBottom,
    required this.actions,
  });

  final FossDrawerFooterVariant variant;
  final double safeBottom;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final sp = theme.spacing;
    final filled = variant == FossDrawerFooterVariant.filled;
    final basePad = filled ? sp(4) : sp(6);
    // Absorb the system inset rather than stacking it on the base padding.
    final bottom = safeBottom > basePad ? safeBottom : basePad;

    return DecoratedBox(
      decoration: BoxDecoration(
        // The bar is the muted role at 72% of its own opacity; muted is already
        // translucent, so multiply rather than replace its alpha.
        color: filled
            ? colors.muted.withValues(alpha: colors.muted.a * 0.72)
            : null,
        border: filled ? Border(top: BorderSide(color: colors.border)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: sp(6),
          right: sp(6),
          top: sp(4),
          bottom: bottom,
        ),
        // Trailing-aligned row, each action hugging its content.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: sp(2),
          children: actions,
        ),
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
            child: icon ?? FossGlyphIcon(CloseGlyph(color), size: 16),
          ),
        ),
      ),
    );
  }
}

Axis _axisOf(FossDrawerSide side) => switch (side) {
  FossDrawerSide.bottom || FossDrawerSide.top => Axis.vertical,
  FossDrawerSide.left || FossDrawerSide.right => Axis.horizontal,
};

AlignmentGeometry _alignmentOf(FossDrawerSide side) => switch (side) {
  FossDrawerSide.bottom => Alignment.bottomCenter,
  FossDrawerSide.top => Alignment.topCenter,
  FossDrawerSide.left => AlignmentDirectional.centerStart,
  FossDrawerSide.right => AlignmentDirectional.centerEnd,
};

/// Where the drag handle sits for a side panel (its inner, exposed edge).
AlignmentGeometry _exposedEdgeAlignment(FossDrawerSide side) => switch (side) {
  FossDrawerSide.bottom => Alignment.topCenter,
  FossDrawerSide.top => Alignment.bottomCenter,
  FossDrawerSide.left => AlignmentDirectional.centerEnd,
  FossDrawerSide.right => AlignmentDirectional.centerStart,
};

BorderRadiusGeometry _exposedCorners(FossDrawerSide side, double r) {
  final radius = Radius.circular(r);
  return switch (side) {
    FossDrawerSide.bottom => BorderRadius.only(
      topLeft: radius,
      topRight: radius,
    ),
    FossDrawerSide.top => BorderRadius.only(
      bottomLeft: radius,
      bottomRight: radius,
    ),
    FossDrawerSide.left => BorderRadiusDirectional.only(
      topEnd: radius,
      bottomEnd: radius,
    ),
    FossDrawerSide.right => BorderRadiusDirectional.only(
      topStart: radius,
      bottomStart: radius,
    ),
  };
}

import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_list_tile_style.dart';

const double _iconSize = 18;
const double _disabledOpacity = 0.64;

/// Minimum row height, the tap-target floor. A one-line row lands on it
/// exactly; a second subtitle line grows past it.
const double _minHeight = 48;

const double _ringWidth = 2;
const double _ringOffset = 1;

const Color _transparent = Color(0x00000000);

/// Fill opacity of the filled row under the pointer: the input color at 64%,
/// composited so it lands darker than the 4% rest fill in both themes.
const double _hoverFillOpacity = 0.64;

/// The surface a [FossListTile] paints at rest.
enum FossListTileVariant {
  /// Tinted, rounded surface of its own. The default: a row in a plain list
  /// reads as its own band without a separator.
  filled,

  /// Transparent at rest, so the row inherits the surface under it. Use inside
  /// a FossCard or any container that already paints, where a second
  /// rectangle would double-draw.
  plain,
}

/// {@category Layout}
/// {@template foss.listTile.preview}
/// <img src="https://fossui.org/components/list-tile/overview/light.png"
///   alt="FossListTile, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/list-tile/overview/dark.png"
///   alt="FossListTile, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [list tile documentation ↗](https://fossui.org/docs/components/list-tile)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/list-tile/fosslisttile/playground).
/// {@endtemplate}
///
/// A row in a list: an optional [leading] widget, a [title] over an optional
/// [subtitle], and an optional [trailing] widget. A settings screen or an
/// account list is mostly this one row repeated.
///
/// Only [title] is required, and every gap collapses with the slot it belongs
/// to. By default the row paints its own tinted, rounded surface, so a plain
/// list reads as a stack of bands; pass [FossListTileVariant.plain] for a row
/// inside a FossCard, where a second rectangle would double-draw.
///
/// Pass [onTap] to make the whole row one target, which adds hover, pressed,
/// and keyboard activation; leaving it null keeps the row inert at full
/// opacity. That is a different state from `enabled: false`, which dims the row
/// and blocks it.
///
/// Two rules govern an interactive [trailing] widget, such as a FossSwitch.
/// The trailing widget wins its own hit area, so a tap on it never reaches
/// [onTap]; wire the two to different callbacks. Focus lands on the row first
/// and the trailing control second, which is the order assistive tech announces
/// them.
///
/// The tile draws no separator and carries no outer margin, so it stays a row
/// rather than a card: space filled rows from the list, and put a
/// FossSeparator between plain ones.
///
/// {@macro foss.customize}
///
/// See also FossCard for the surface a group of plain rows usually sits on.
///
/// ```dart
/// FossListTile(
///   leading: const Icon(LucideIcons.bell),
///   title: const Text('Notifications'),
///   subtitle: const Text('Push and email'),
///   trailing: FossSwitch(
///     value: notify,
///     onChanged: (v) => setState(() => notify = v),
///   ),
///   onTap: openNotificationSettings,
/// );
/// ```
@FossSince('0.2.0')
class FossListTile extends StatefulWidget {
  /// {@macro foss.listTile.preview}
  ///
  /// Creates a list row showing [title]. Every other slot is optional; a null
  /// [onTap] leaves the row inert rather than disabled.
  const FossListTile({
    required this.title,
    this.subtitle,
    this.variant = FossListTileVariant.filled,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.style,
    super.key,
  });

  /// The primary line, typically a [Text]. Color, weight, and type step are
  /// applied through `DefaultTextStyle`. Clamped to one line.
  final Widget title;

  /// The secondary line below [title], typically a [Text]. Clamped to two
  /// lines.
  final Widget? subtitle;

  /// The surface the row paints at rest. Defaults to
  /// [FossListTileVariant.filled]; pass [FossListTileVariant.plain] for a row
  /// that sits inside a container which already paints its own surface.
  final FossListTileVariant variant;

  /// A widget at the start of the row (an icon, an avatar), themed as an icon
  /// and rendered at its own size.
  final Widget? leading;

  /// A widget at the end of the row (a switch, a chevron, a badge). An
  /// interactive one keeps its own gestures and its own focus stop.
  final Widget? trailing;

  /// Called when the row is tapped or activated with Enter or Space. Null
  /// leaves the row inert: no hover, no cursor change, and no focus stop.
  ///
  /// A tap on an interactive [trailing] widget goes to that widget and does not
  /// call this.
  final VoidCallback? onTap;

  /// Whether the row is interactive. False dims it to 64% and blocks both the
  /// pointer and the keyboard.
  final bool enabled;

  /// Accessibility name announced instead of [title] and [subtitle], for a row
  /// whose visible text does not read well on its own.
  final String? semanticLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossListTileStyle? style;

  @override
  State<FossListTile> createState() => _FossListTileState();
}

class _FossListTileState extends State<FossListTile> {
  final WidgetStatesController _states = WidgetStatesController();

  /// Whether the row itself responds: it has a callback and is not disabled.
  bool get _interactive => widget.onTap != null && widget.enabled;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(FossListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Mirrors the disabled flag into the state set and drops any live pointer or
  /// focus state with it. A row that stops responding mid-press never gets the
  /// matching release, so the highlight would otherwise stick.
  void _sync() {
    _states.update(WidgetState.disabled, !widget.enabled);
    if (_interactive) return;
    _states
      ..update(WidgetState.pressed, false)
      ..update(WidgetState.hovered, false)
      ..update(WidgetState.focused, false);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  void _setPressed(bool value) => _states.update(WidgetState.pressed, value);

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _resolve(theme, widget.variant).merge(widget.style);
    // Built once per build and reused across state changes, so a hover or a
    // press repaints the fill without rebuilding the slots.
    final content = _content(visuals);

    return MergeSemantics(
      child: Semantics(
        button: widget.onTap != null,
        enabled: widget.onTap == null ? null : widget.enabled,
        label: widget.semanticLabel,
        child: FocusableActionDetector(
          enabled: _interactive,
          mouseCursor: _interactive
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          onShowHoverHighlight: (v) => _states.update(WidgetState.hovered, v),
          onShowFocusHighlight: (v) => _states.update(WidgetState.focused, v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _interactive ? widget.onTap : null,
            onTapDown: _interactive ? (_) => _setPressed(true) : null,
            onTapUp: _interactive ? (_) => _setPressed(false) : null,
            onTapCancel: _interactive ? () => _setPressed(false) : null,
            child: ListenableBuilder(
              listenable: _states,
              builder: (context, _) => _paint(visuals, content),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paint(_TileVisuals visuals, Widget content) {
    final states = _states.value;

    Widget row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: visuals.minHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: visuals.background.resolve(states),
          shape: RoundedSuperellipseBorder(borderRadius: visuals.radius),
        ),
        child: Padding(padding: visuals.padding, child: content),
      ),
    );

    if (!widget.enabled) {
      row = Opacity(opacity: _disabledOpacity, child: row);
    }

    return CustomPaint(
      foregroundPainter: states.contains(WidgetState.focused)
          ? _FocusRingPainter(
              color: visuals.ring,
              offsetColor: visuals.ringOffset,
              radius: visuals.radius,
            )
          : null,
      child: row,
    );
  }

  /// Builds the slot row. Each gap belongs to the slot next to it, so a
  /// title-only tile carries no stray spacing.
  Widget _content(_TileVisuals visuals) {
    final icon = IconThemeData(
      size: visuals.iconSize,
      color: visuals.iconColor,
    );

    Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: visuals.textGap,
      children: [
        DefaultTextStyle.merge(
          style: visuals.titleStyle,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          child: widget.title,
        ),
        if (widget.subtitle case final subtitle?)
          DefaultTextStyle.merge(
            style: visuals.subtitleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            child: subtitle,
          ),
      ],
    );

    // A semantic label replaces the row's text rather than adding to it, so the
    // lines it stands in for are dropped from the tree.
    if (widget.semanticLabel != null) {
      text = ExcludeSemantics(child: text);
    }

    return Row(
      spacing: visuals.gap,
      children: [
        if (widget.leading case final leading?)
          IconTheme.merge(data: icon, child: leading),
        // The text column takes the slack, so a long title ellipsizes instead
        // of pushing the trailing slot off the row.
        Expanded(child: text),
        if (widget.trailing case final trailing?)
          IconTheme.merge(data: icon, child: trailing),
      ],
    );
  }
}

/// Composites [base] at [opacity] of its own alpha over a fixed [surface],
/// baking an opaque color for the filled row's lit state.
Color _overlay(Color base, double opacity, Color surface) =>
    Color.alphaBlend(base.withValues(alpha: base.a * opacity), surface);

/// Builds the default appearance for a variant from the theme tokens.
_TileVisuals _resolve(FossThemeData theme, FossListTileVariant variant) {
  final c = theme.colors;
  final sp = theme.spacing;

  // A filled row already sits at the 4% tint, so its lit state has to step
  // past it; a plain row is transparent and lights to that same 4%. Pressed
  // matches hover either way: a band this wide does not need a third step.
  final (rest, lit, radius) = switch (variant) {
    FossListTileVariant.filled => (
      c.accent,
      _overlay(c.input, _hoverFillOpacity, c.background),
      theme.radii.lg,
    ),
    FossListTileVariant.plain => (_transparent, c.accent, theme.radii.sm),
  };

  return _TileVisuals(
    background: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)
          ? lit
          : rest,
    ),
    padding: EdgeInsets.symmetric(horizontal: sp(4), vertical: sp(3)),
    gap: sp(4),
    textGap: sp(1),
    minHeight: _minHeight,
    radius: BorderRadius.all(Radius.circular(radius)),
    titleStyle: theme.typography.base.semibold.copyWith(color: c.foreground),
    subtitleStyle: theme.typography.sm.copyWith(color: c.mutedForeground),
    iconColor: c.foreground,
    iconSize: _iconSize,
    ring: c.ring,
    ringOffset: c.background,
  );
}

/// The fully resolved, non-null appearance of one tile. A public
/// [FossListTileStyle] override is laid over it by [merge], so the widget reads
/// only non-null fields.
@immutable
class _TileVisuals {
  const _TileVisuals({
    required this.background,
    required this.padding,
    required this.gap,
    required this.textGap,
    required this.minHeight,
    required this.radius,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.iconColor,
    required this.iconSize,
    required this.ring,
    required this.ringOffset,
  });

  final WidgetStateProperty<Color> background;
  final EdgeInsetsGeometry padding;
  final double gap;
  final double textGap;
  final double minHeight;
  final BorderRadius radius;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color iconColor;
  final double iconSize;
  final Color ring;
  final Color ringOffset;

  /// Lays a per-instance [override] over this resolved base, field by field.
  _TileVisuals merge(FossListTileStyle? override) {
    if (override == null) return this;
    final radius = override.borderRadius;
    return _TileVisuals(
      background: override.backgroundColor ?? background,
      padding: override.padding ?? padding,
      gap: override.gap ?? gap,
      textGap: textGap,
      minHeight: override.minHeight ?? minHeight,
      radius: radius != null
          ? BorderRadius.all(Radius.circular(radius))
          : this.radius,
      titleStyle: titleStyle.merge(override.titleStyle),
      subtitleStyle: subtitleStyle.merge(override.subtitleStyle),
      iconColor: iconColor,
      iconSize: override.iconSize ?? iconSize,
      ring: ring,
      ringOffset: ringOffset,
    );
  }
}

/// Paints the focus ring: a 2px superellipse outset just past the row edge,
/// with a 1px offset gap filled with [offsetColor] so the ring reads as
/// detached, matching the corner shape rather than a circular arc.
class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.offsetColor,
    required this.radius,
  });

  final Color color;
  final Color offsetColor;
  final BorderRadius radius;

  RSuperellipse _shape(Rect box, double inflate, double grow) =>
      RSuperellipse.fromRectAndCorners(
        box.inflate(inflate),
        topLeft: Radius.circular(radius.topLeft.x + grow),
        topRight: Radius.circular(radius.topRight.x + grow),
        bottomLeft: Radius.circular(radius.bottomLeft.x + grow),
        bottomRight: Radius.circular(radius.bottomRight.x + grow),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..drawRSuperellipse(
        _shape(box, _ringOffset / 2, _ringOffset / 2),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawRSuperellipse(
        _shape(box, _ringOffset + _ringWidth / 2, _ringOffset + _ringWidth / 2),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.color != color ||
      old.offsetColor != offsetColor ||
      old.radius != radius;
}

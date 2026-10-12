part of 'foss_combobox.dart';

/// Frames the popup [body] in the shared surface: a superellipse border, fill,
/// and shadow, clipped to the same superellipse so a highlighted first or last
/// row never pokes past the corner.
Widget _popupChrome(_ComboboxVisuals v, Widget body) {
  final radius = BorderRadius.circular(v.borderRadius);
  return DecoratedBox(
    decoration: ShapeDecoration(
      color: v.popupColor,
      shape: RoundedSuperellipseBorder(
        side: BorderSide(color: v.popupBorderColor),
        borderRadius: radius,
      ),
      shadows: v.popupShadow,
    ),
    child: ClipPath(
      clipper: ShapeBorderClipper(
        shape: RoundedSuperellipseBorder(borderRadius: radius),
      ),
      child: body,
    ),
  );
}

/// The shared overlay machinery behind every combobox field: the anchored popup
/// portal, its open and close animation, the roving highlight and keyboard
/// navigation, the query-driven highlight reset, and dismiss-on-scroll. The
/// single-select, autocomplete, and multi-select fields mix this in and differ
/// only in the hooks below.
mixin _ComboboxPopup<T, W extends StatefulWidget>
    on State<W>, SingleTickerProviderStateMixin<W> {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  final List<ScrollPosition> _scrollPositions = [];

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  bool _open = false;
  int _highlight = -1;

  /// Whether the field accepts interaction; a disabled field never opens.
  bool get popupEnabled;

  /// The options currently visible, after the active query filter.
  List<FossComboboxItem<T>> get filteredOptions;

  /// The row to highlight when the popup opens.
  int initialHighlight();

  /// Commits an item: a select for the single field, a toggle for the multi.
  void onActivate(FossComboboxItem<T> item);

  /// Builds the decorated popup surface, its rows or the empty state.
  Widget buildPopupSurface(BuildContext context);

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: _openScale, end: 1).animate(_curve);
  }

  @override
  void dispose() {
    _detachScrollDismiss();
    _animation.dispose();
    _curve.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _duration => context.fossTheme.motion.overlay;

  int _firstEnabled(List<FossComboboxItem<T>> options) =>
      options.indexWhere((o) => o.enabled);

  void _openPopup() {
    if (!popupEnabled || _open) return;
    setState(() {
      _open = true;
      _highlight = initialHighlight();
    });
    _portal.show();
    _attachScrollDismiss();
    _animation.duration = _reduceMotion ? Duration.zero : _duration;
    _animation.forward(from: _reduceMotion ? 1 : 0);
  }

  void _closePopup() {
    if (!_open) return;
    _detachScrollDismiss();
    setState(() => _open = false);
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

  // Close the popup when any enclosing scrollable moves, so it never floats
  // detached from its field. Every ancestor is tracked, not just the nearest,
  // so a page swipe dismisses it even when the page has its own scroll view.
  void _attachScrollDismiss() {
    for (
      var scrollable = Scrollable.maybeOf(context);
      scrollable != null;
      scrollable = Scrollable.maybeOf(scrollable.context)
    ) {
      scrollable.position.addListener(_closePopup);
      _scrollPositions.add(scrollable.position);
    }
  }

  void _detachScrollDismiss() {
    for (final position in _scrollPositions) {
      position.removeListener(_closePopup);
    }
    _scrollPositions.clear();
  }

  void _moveHighlight(int delta) {
    final options = filteredOptions;
    final count = options.length;
    if (count == 0) return;
    var next = _highlight;
    for (var step = 0; step < count; step++) {
      next = (next + delta) % count;
      if (next < 0) next += count;
      if (options[next].enabled) {
        setState(() => _highlight = next);
        return;
      }
    }
  }

  // On a query change, drop the highlight back to the first enabled match.
  void _resetHighlight() {
    if (_open) setState(() => _highlight = _firstEnabled(filteredOptions));
  }

  void _highlightRow(int index) {
    if (_highlight != index) setState(() => _highlight = index);
  }

  void _activateHighlighted() {
    final options = filteredOptions;
    if (_highlight >= 0 && _highlight < options.length) {
      onActivate(options[_highlight]);
    }
  }

  KeyEventResult _handlePopupKey(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (!_open) return KeyEventResult.ignored;
      _closePopup();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _open ? _moveHighlight(1) : _openPopup();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_open) _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildOverlay(BuildContext context) {
    final anchor = _anchorRect(context);
    if (anchor == null) return const SizedBox.shrink();
    // The on-screen keyboard eats the bottom of the overlay; subtract it so the
    // popup lays out against the visible area, not behind the keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return TextFieldTapRegion(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _PopupLayout(anchor: anchor, bottomInset: bottomInset),
              child: FadeTransition(
                opacity: _curve,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: Alignment.topCenter,
                  child: buildPopupSurface(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect? _anchorRect(BuildContext overlayContext) {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(overlayContext).context.findRenderObject();
    if (anchor is! RenderBox || overlay is! RenderBox || !anchor.attached) {
      return null;
    }
    return anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
  }
}

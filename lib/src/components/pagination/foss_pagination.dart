import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/button/foss_button.dart';
import 'package:fossui/src/components/pagination/pagination_window.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_pagination_style.dart';

/// The width one slot occupies at rest: a [FossButton]'s minimum tap extent.
/// Only a large text scale pushes a page number past it.
const double _minSlot = 48;

/// The ellipsis mark, drawn larger than a button's icon so three dots read as
/// three dots.
const double _ellipsisGlyph = 20;

/// {@category Layout}
/// {@template foss.pagination.preview}
/// <img src="https://fossui.org/components/pagination/overview/light.png"
///   alt="FossPagination, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/pagination/overview/dark.png"
///   alt="FossPagination, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the
/// [pagination documentation ↗](https://fossui.org/docs/components/pagination)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/pagination/fosspagination/playground).
/// {@endtemplate}
///
/// A row that walks through pages: a previous control, a windowed run of page
/// numbers with an ellipsis wherever the run is cut, and a next control.
///
/// It is controlled. [page] is the current page and [pageCount] the total, both
/// 1-based, and [onPageChanged] reports the page the user asked for. Passing a
/// null [onPageChanged] makes the whole row inert and dimmed.
///
/// [siblingCount] is how many pages sit either side of the current one, and it
/// is an upper bound: when the width it is given cannot hold that many slots,
/// the row uses the largest count that fits, so it does not overflow a phone.
/// That figure ignores [page], so the row does not resize while the user pages.
/// Seven slots is the floor, since a narrower row would have to drop the first
/// or last page.
///
/// Because the row reads the width it is given, it cannot report an intrinsic
/// size. Give it a width instead of placing it in a `Table` cell or an
/// `IntrinsicWidth`.
///
/// {@macro foss.customize}
///
/// Every control is a square [FossButton], so hover, pressed, focus, and
/// disabled all behave the way buttons do elsewhere. The chevrons follow the
/// reading direction and the ellipsis is not focusable.
///
/// See also [FossPaginationStyle] for one-off overrides.
///
/// ```dart
/// FossPagination(
///   page: page,
///   pageCount: 10,
///   onPageChanged: (p) => setState(() => page = p),
/// );
/// ```
@FossSince('0.2.0')
class FossPagination extends StatelessWidget {
  /// {@macro foss.pagination.preview}
  ///
  /// Creates a pagination row. [page] is 1-based and must fall within
  /// [pageCount]; a null [onPageChanged] disables every control.
  const FossPagination({
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.siblingCount = 1,
    this.label = 'Pagination',
    this.pageLabel,
    this.previousLabel = 'Go to previous page',
    this.nextLabel = 'Go to next page',
    this.moreLabel = 'More pages',
    this.style,
    super.key,
  }) : assert(pageCount >= 1, 'pageCount must be at least 1.'),
       assert(
         page >= 1 && page <= pageCount,
         'page must be between 1 and pageCount.',
       ),
       assert(siblingCount >= 0, 'siblingCount cannot be negative.');

  /// The current page, 1-based and within [pageCount].
  final int page;

  /// The total number of pages, at least 1.
  final int pageCount;

  /// Called with the page the user asked for. Null disables the whole row.
  ///
  /// Tapping the current page does not call it.
  final ValueChanged<int>? onPageChanged;

  /// The pages shown either side of [page], as a ceiling. A narrow row uses
  /// fewer. Defaults to 1.
  final int siblingCount;

  /// Names the row for assistive technology. Defaults to `'Pagination'`.
  final String label;

  /// Builds each page button's accessibility label. Defaults to `'Page $n'`.
  final String Function(int page)? pageLabel;

  /// Accessibility label for the previous control.
  final String previousLabel;

  /// Accessibility label for the next control.
  final String nextLabel;

  /// Accessibility label for an ellipsis, which announces the pages it hides.
  final String moreLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossPaginationStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final numberStyle = theme.typography.base.medium;
    final slot = math.max(_minSlot, _numberExtent(context, numberStyle));
    final visuals = _PaginationVisuals.resolve(theme, style, slot: slot);

    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final siblings = _fittedSiblings(
            constraints.maxWidth,
            gap: visuals.gap,
            slot: slot,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: visuals.gap,
            children: [
              _step(visuals, target: page - 1, forward: false),
              for (final entry in pageWindow(
                page: page,
                pageCount: pageCount,
                siblingCount: siblings,
              ))
                if (entry case final n?)
                  _pageButton(n, visuals, numberStyle)
                else
                  _ellipsis(visuals),
              _step(visuals, target: page + 1, forward: true),
            ],
          );
        },
      ),
    );
  }

  /// Measures the widest page number so the slot pitch stays right when a large
  /// text scale grows the digits past the button's tap extent.
  double _numberExtent(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: '$pageCount', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// The largest sibling count whose row fits [maxWidth], never above the
  /// requested [siblingCount]. An unbounded width takes the request as-is.
  int _fittedSiblings(
    double maxWidth, {
    required double gap,
    required double slot,
  }) {
    if (!maxWidth.isFinite) return siblingCount;
    final fits = ((maxWidth + gap) / (slot + gap)).floor();
    // Two slots go to the previous and next controls; the rest hold the
    // 2 * siblingCount + 5 pages.
    return ((fits - 7) ~/ 2).clamp(0, siblingCount);
  }

  void _go(int next) {
    if (next != page) onPageChanged?.call(next);
  }

  /// The previous or next control. Off either end it has no target, so it
  /// takes a null callback and [FossButton] dims it and drops it from focus.
  Widget _step(
    _PaginationVisuals visuals, {
    required int target,
    required bool forward,
  }) {
    final live = onPageChanged != null && target >= 1 && target <= pageCount;
    return FossButton.icon(
      onPressed: live ? () => _go(target) : null,
      variant: visuals.inactiveVariant,
      size: visuals.buttonSize,
      semanticLabel: forward ? nextLabel : previousLabel,
      icon: _Chevron(forward: forward),
    );
  }

  Widget _pageButton(int n, _PaginationVisuals visuals, TextStyle numberStyle) {
    final current = n == page;
    final button = FossButton.icon(
      onPressed: onPageChanged == null ? null : () => _go(n),
      variant: current ? visuals.activeVariant : visuals.inactiveVariant,
      size: visuals.buttonSize,
      semanticLabel: pageLabel?.call(n) ?? 'Page $n',
      icon: _PageNumber(n, style: numberStyle),
    );
    // Selection is the closest thing Flutter has to marking the current item in
    // a set of page links.
    return current ? Semantics(selected: true, child: button) : button;
  }

  /// The cut marker: as wide as a page button so the row's pitch stays even,
  /// and inert, so only its label reaches assistive technology.
  Widget _ellipsis(_PaginationVisuals visuals) => Semantics(
    // Its own node, or the label folds into the row's and the row announces
    // every ellipsis as part of its name.
    container: true,
    label: moreLabel,
    child: SizedBox(
      width: visuals.ellipsisWidth,
      child: Center(
        child: FossGlyphIcon(
          EllipsisGlyph(visuals.ellipsisColor),
          size: _ellipsisGlyph,
        ),
      ),
    ),
  );
}

/// A page number drawn in the enclosing button's resolved foreground, so it
/// stays legible under any [FossButtonVariant] the style picks for the current
/// page. Centred because the button floors its content to a square and a bare
/// [Text] would paint in that square's corner.
class _PageNumber extends StatelessWidget {
  const _PageNumber(this.page, {required this.style});

  final int page;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? context.fossTheme.colors.foreground;
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      // The number is the whole label, and the button already announces it.
      child: ExcludeSemantics(
        child: Text('$page', style: style.copyWith(color: color)),
      ),
    );
  }
}

/// A step chevron pointing along the reading direction, drawn in the enclosing
/// button's resolved icon color and size.
///
/// The two glyphs are swapped rather than mirrored with a transform, so the
/// stroke caps stay where the glyph put them.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.forward});

  final bool forward;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final color = icon.color ?? context.fossTheme.colors.foreground;
    // A bare glyph paints into whatever box it is handed, and the button floors
    // its content to a square, so centre it or it draws at the button's size.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: FossGlyphIcon(
        forward == ltr ? ChevronRightGlyph(color) : ChevronLeftGlyph(color),
        size: icon.size,
      ),
    );
  }
}

/// The resolved row appearance: the gap, the button shape, and the ellipsis.
@immutable
class _PaginationVisuals {
  const _PaginationVisuals({
    required this.gap,
    required this.buttonSize,
    required this.activeVariant,
    required this.inactiveVariant,
    required this.ellipsisColor,
    required this.ellipsisWidth,
  });

  factory _PaginationVisuals.resolve(
    FossThemeData theme,
    FossPaginationStyle? s, {
    required double slot,
  }) => _PaginationVisuals(
    gap: s?.gap ?? theme.spacing(1),
    buttonSize: s?.buttonSize ?? FossButtonSize.md,
    activeVariant: s?.activeVariant ?? FossButtonVariant.outline,
    inactiveVariant: s?.inactiveVariant ?? FossButtonVariant.ghost,
    ellipsisColor: s?.ellipsisColor ?? theme.colors.mutedForeground,
    // Matching the button's occupied width keeps every slot the same size, so
    // the row holds its width as ellipses come and go.
    ellipsisWidth: s?.ellipsisWidth ?? slot,
  );

  final double gap;
  final FossButtonSize buttonSize;
  final FossButtonVariant activeVariant;
  final FossButtonVariant inactiveVariant;
  final Color ellipsisColor;
  final double ellipsisWidth;
}

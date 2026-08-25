import 'dart:math' as math;

/// The page numbers to render for [page] of [pageCount], where a null entry is
/// an ellipsis standing in for a run of hidden pages.
///
/// Below the threshold of `2 * siblingCount + 5` every page is listed. Above it
/// the list is always exactly that long: whichever end has no ellipsis extends
/// its run to make up the difference. That keeps the row a fixed width as the
/// user pages through, at the cost of occasionally spending an ellipsis on a
/// single hidden page.
///
/// Internal to the pagination component and not part of the public surface.
///
/// ```dart
/// pageWindow(page: 5, pageCount: 10, siblingCount: 1);
/// // [1, null, 4, 5, 6, null, 10]
/// ```
List<int?> pageWindow({
  required int page,
  required int pageCount,
  required int siblingCount,
}) {
  final slots = 2 * siblingCount + 5;
  if (pageCount <= slots) return [for (var i = 1; i <= pageCount; i++) i];

  final left = math.max(page - siblingCount, 1);
  final right = math.min(page + siblingCount, pageCount);

  // The inclusive run between the two boundary pages. Near an end it anchors to
  // that end and grows; in the middle it is the sibling run itself.
  final (start, end) = switch (left) {
    <= 2 => (2, 2 * siblingCount + 3),
    _ when right >= pageCount - 1 => (
      pageCount - 2 * siblingCount - 2,
      pageCount - 1,
    ),
    _ => (left, right),
  };

  return [
    1,
    if (start > 2) null,
    for (var i = start; i <= end; i++) i,
    if (end < pageCount - 1) null,
    pageCount,
  ];
}

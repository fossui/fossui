import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/src/components/pagination/pagination_window.dart';

/// One expected window, written the way the row reads. `null` is an ellipsis.
typedef _Case = (int pageCount, int page, List<int?> expected);

void main() {
  group('pageWindow at siblingCount 1', () {
    const cases = <_Case>[
      (1, 1, [1]),
      (2, 1, [1, 2]),
      (2, 2, [1, 2]),
      (5, 3, [1, 2, 3, 4, 5]),
      (7, 4, [1, 2, 3, 4, 5, 6, 7]),
      (8, 1, [1, 2, 3, 4, 5, null, 8]),
      (8, 4, [1, null, 3, 4, 5, null, 8]),
      (8, 8, [1, null, 4, 5, 6, 7, 8]),
      (10, 1, [1, 2, 3, 4, 5, null, 10]),
      (10, 3, [1, 2, 3, 4, 5, null, 10]),
      (10, 4, [1, null, 3, 4, 5, null, 10]),
      (10, 5, [1, null, 4, 5, 6, null, 10]),
      (10, 7, [1, null, 6, 7, 8, null, 10]),
      (10, 8, [1, null, 6, 7, 8, 9, 10]),
      (10, 9, [1, null, 6, 7, 8, 9, 10]),
      (10, 10, [1, null, 6, 7, 8, 9, 10]),
    ];

    for (final (pageCount, page, expected) in cases) {
      test('page $page of $pageCount', () {
        expect(
          pageWindow(page: page, pageCount: pageCount, siblingCount: 1),
          expected,
        );
      });
    }
  });

  group('pageWindow at siblingCount 0', () {
    const cases = <_Case>[
      (5, 3, [1, 2, 3, 4, 5]),
      (10, 1, [1, 2, 3, null, 10]),
      (10, 2, [1, 2, 3, null, 10]),
      (10, 3, [1, null, 3, null, 10]),
      (10, 5, [1, null, 5, null, 10]),
      // The right ellipsis stands in for page 9 alone, the accepted cost of a
      // row that does not resize as the user pages.
      (10, 8, [1, null, 8, null, 10]),
      (10, 9, [1, null, 8, 9, 10]),
      (10, 10, [1, null, 8, 9, 10]),
    ];

    for (final (pageCount, page, expected) in cases) {
      test('page $page of $pageCount', () {
        expect(
          pageWindow(page: page, pageCount: pageCount, siblingCount: 0),
          expected,
        );
      });
    }
  });

  group('pageWindow at siblingCount 2', () {
    const cases = <_Case>[
      (9, 5, [1, 2, 3, 4, 5, 6, 7, 8, 9]),
      (20, 1, [1, 2, 3, 4, 5, 6, 7, null, 20]),
      (20, 10, [1, null, 8, 9, 10, 11, 12, null, 20]),
      (20, 20, [1, null, 14, 15, 16, 17, 18, 19, 20]),
    ];

    for (final (pageCount, page, expected) in cases) {
      test('page $page of $pageCount', () {
        expect(
          pageWindow(page: page, pageCount: pageCount, siblingCount: 2),
          expected,
        );
      });
    }
  });

  group('slot count', () {
    for (final siblingCount in [0, 1, 2, 3]) {
      final slots = 2 * siblingCount + 5;

      test('is $slots at every page above the threshold', () {
        // One past the threshold is where the ellipses first appear, and the
        // width must hold from there on.
        for (final pageCount in [slots + 1, slots + 2, 40, 500]) {
          for (var page = 1; page <= pageCount; page++) {
            expect(
              pageWindow(
                page: page,
                pageCount: pageCount,
                siblingCount: siblingCount,
              ),
              hasLength(slots),
              reason: 'page $page of $pageCount at siblingCount $siblingCount',
            );
          }
        }
      });

      test('lists every page up to the threshold of $slots', () {
        for (var pageCount = 1; pageCount <= slots; pageCount++) {
          for (var page = 1; page <= pageCount; page++) {
            expect(
              pageWindow(
                page: page,
                pageCount: pageCount,
                siblingCount: siblingCount,
              ),
              [for (var i = 1; i <= pageCount; i++) i],
            );
          }
        }
      });
    }
  });

  group('invariants above the threshold', () {
    test('always keeps the first and last page', () {
      for (var pageCount = 8; pageCount <= 40; pageCount++) {
        for (var page = 1; page <= pageCount; page++) {
          final window = pageWindow(
            page: page,
            pageCount: pageCount,
            siblingCount: 1,
          );
          expect(window.first, 1);
          expect(window.last, pageCount);
        }
      }
    });

    test('always includes the current page', () {
      for (var pageCount = 8; pageCount <= 40; pageCount++) {
        for (var page = 1; page <= pageCount; page++) {
          expect(
            pageWindow(page: page, pageCount: pageCount, siblingCount: 1),
            contains(page),
          );
        }
      }
    });

    test('runs strictly upward and never repeats a page', () {
      for (var pageCount = 8; pageCount <= 40; pageCount++) {
        for (var page = 1; page <= pageCount; page++) {
          final pages = pageWindow(
            page: page,
            pageCount: pageCount,
            siblingCount: 1,
          ).nonNulls.toList();
          expect(pages, orderedEquals(pages.toSet().toList()..sort()));
        }
      }
    });

    test('never places two ellipses side by side', () {
      for (var pageCount = 8; pageCount <= 40; pageCount++) {
        for (var page = 1; page <= pageCount; page++) {
          final window = pageWindow(
            page: page,
            pageCount: pageCount,
            siblingCount: 1,
          );
          for (var i = 1; i < window.length; i++) {
            expect(window[i] == null && window[i - 1] == null, isFalse);
          }
        }
      }
    });
  });
}

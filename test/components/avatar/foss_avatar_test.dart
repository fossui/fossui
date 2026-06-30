import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );

  // The closest DefaultTextStyle to the fallback child carries the resolved
  // type step.
  TextStyle fallbackStyle(WidgetTester tester) {
    final styles = find.descendant(
      of: find.byType(FossAvatar),
      matching: find.byType(DefaultTextStyle),
    );
    return tester.widget<DefaultTextStyle>(styles.last).style;
  }

  Color circleColor(WidgetTester tester, {required bool fallback}) {
    final boxes = find.descendant(
      of: find.byType(FossAvatar),
      matching: find.byType(DecoratedBox),
    );
    // The outer DecoratedBox is the background circle; the inner one is the
    // fallback layer.
    final box = tester.widget<DecoratedBox>(
      fallback ? boxes.last : boxes.first,
    );
    return (box.decoration as BoxDecoration).color ?? const Color(0x00000000);
  }

  group('FossAvatarStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossAvatarStyle(
        backgroundColor: Color(0xFF111111),
        fallbackColor: Color(0xFF222222),
        fallbackTextStyle: TextStyle(fontSize: 9),
      );
      const over = FossAvatarStyle(fallbackColor: Color(0xFF333333));

      final merged = base.merge(over);

      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.fallbackColor, const Color(0xFF333333));
      expect(merged.fallbackTextStyle, const TextStyle(fontSize: 9));
    });

    test('null other returns the same instance', () {
      const base = FossAvatarStyle(fallbackColor: Color(0xFF222222));
      expect(base.merge(null), same(base));
    });
  });

  group('size', () {
    const boxes = {
      FossAvatarSize.xs: 24.0,
      FossAvatarSize.sm: 28.0,
      FossAvatarSize.md: 32.0,
      FossAvatarSize.lg: 36.0,
      FossAvatarSize.xl: 40.0,
      FossAvatarSize.xl2: 48.0,
    };

    for (final MapEntry(key: size, value: edge) in boxes.entries) {
      testWidgets('$size renders a $edge box', (tester) async {
        await tester.pumpWidget(host(FossAvatar(size: size)));
        expect(tester.getSize(find.byType(FossAvatar)), Size(edge, edge));
      });
    }

    testWidgets('fallback type step climbs with the box', (tester) async {
      final t = FossThemeData.light.typography;
      final steps = {
        FossAvatarSize.xs: t.xs.fontSize,
        FossAvatarSize.md: t.xs.fontSize,
        FossAvatarSize.lg: t.sm.fontSize,
        FossAvatarSize.xl: t.base.fontSize,
        FossAvatarSize.xl2: t.lg.fontSize,
      };
      for (final entry in steps.entries) {
        await tester.pumpWidget(
          host(FossAvatar(size: entry.key, fallback: const Text('VL'))),
        );
        expect(fallbackStyle(tester).fontSize, entry.value);
      }
    });
  });

  group('fallback', () {
    testWidgets('shows when there is no image', (tester) async {
      await tester.pumpWidget(host(const FossAvatar(fallback: Text('VL'))));
      expect(find.text('VL'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('layer fills muted, text is medium mutedForeground', (
      tester,
    ) async {
      const theme = FossThemeData.light;
      await tester.pumpWidget(
        host(const FossAvatar(fallback: Text('VL')), theme: theme),
      );
      expect(circleColor(tester, fallback: true), theme.colors.muted);
      final style = fallbackStyle(tester);
      expect(style.color, theme.colors.mutedForeground);
      expect(style.fontWeight, FontWeight.w500);
    });

    testWidgets('absent with no image leaves a bare background circle', (
      tester,
    ) async {
      const theme = FossThemeData.light;
      await tester.pumpWidget(host(const FossAvatar(), theme: theme));
      expect(find.byType(Image), findsNothing);
      expect(find.byType(Text), findsNothing);
      expect(circleColor(tester, fallback: false), theme.colors.background);
    });

    testWidgets('dark roles resolve', (tester) async {
      const theme = FossThemeData.dark;
      await tester.pumpWidget(
        host(const FossAvatar(fallback: Text('VL')), theme: theme),
      );
      expect(circleColor(tester, fallback: true), theme.colors.muted);
      expect(fallbackStyle(tester).color, theme.colors.mutedForeground);
    });
  });

  group('image', () {
    testWidgets('renders an Image over the provider, cover fit', (
      tester,
    ) async {
      final provider = MemoryImage(_kPixel);
      await tester.pumpWidget(
        host(FossAvatar(image: provider, fallback: const Text('VL'))),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, provider);
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('fallback stays visible until the first frame', (tester) async {
      // A never-resolving provider keeps frame null, so the fallback shows.
      await tester.pumpWidget(
        host(
          FossAvatar(image: _PendingImage(), fallback: const Text('VL')),
        ),
      );
      expect(find.text('VL'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('exposes one labelled image', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const FossAvatar(fallback: Text('VL'), semanticsLabel: 'Vitalik'),
        ),
      );
      expect(
        tester.getSemantics(find.byType(FossAvatar)),
        matchesSemantics(label: 'Vitalik', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('is decorative when unlabelled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossAvatar(fallback: Text('VL'))));
      expect(
        tester.getSemantics(find.byType(FossAvatar)),
        matchesSemantics(isImage: true),
      );
      handle.dispose();
    });

    testWidgets('box is fixed under 2x text scale', (tester) async {
      await tester.pumpWidget(
        host(
          const FossAvatar(fallback: Text('VL')),
          textScale: 2,
        ),
      );
      expect(tester.getSize(find.byType(FossAvatar)), const Size(32, 32));
    });

    testWidgets('box is symmetric under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const FossAvatar(fallback: Text('VL')),
          direction: TextDirection.rtl,
        ),
      );
      expect(tester.getSize(find.byType(FossAvatar)), const Size(32, 32));
    });
  });
}

// A 1x1 transparent PNG, enough to instantiate a MemoryImage provider.
final _kPixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

// An image provider whose load never completes, holding the frame at null.
class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: Completer<Codec>().future,
    scale: 1,
  );
}

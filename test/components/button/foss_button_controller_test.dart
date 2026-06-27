import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

void main() {
  group('FossButtonController state', () {
    test('exposes status and derived reads', () {
      final controller = FossButtonController();
      addTearDown(controller.dispose);

      expect(controller.status, FossButtonStatus.idle);
      expect(controller.isEnabled, isTrue);
      expect(controller.isLoading, isFalse);

      controller.loading();
      expect(controller.isLoading, isTrue);
      expect(controller.isEnabled, isFalse);

      controller.disable();
      expect(controller.status, FossButtonStatus.disabled);
      expect(controller.isEnabled, isFalse);
    });

    test('notifies only on a real change', () {
      final controller = FossButtonController();
      addTearDown(controller.dispose);
      var notifications = 0;

      controller
        ..addListener(() => notifications++)
        ..idle() // already idle, no change
        ..loading()
        ..loading(); // same, no change

      expect(notifications, 1);
    });

    test('run() drives loading then idle, even on error', () async {
      final controller = FossButtonController();
      addTearDown(controller.dispose);

      final completer = Completer<void>();
      final future = controller.run(() => completer.future);
      expect(controller.isLoading, isTrue);

      completer.completeError(Exception('boom'));
      await expectLater(future, throwsException);
      expect(controller.status, FossButtonStatus.idle);
    });

    test('run() is a no-op unless idle', () async {
      final controller = FossButtonController(FossButtonStatus.disabled);
      addTearDown(controller.dispose);
      var ran = false;

      await controller.run(() async => ran = true);

      expect(ran, isFalse);
      expect(controller.status, FossButtonStatus.disabled);
    });
  });

  group('FossButtonController drives the button', () {
    testWidgets('loading() shows the spinner and blocks taps', (tester) async {
      final controller = FossButtonController();
      addTearDown(controller.dispose);
      var taps = 0;

      await tester.pumpWidget(
        host(
          FossButton(
            controller: controller,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );

      controller.loading();
      await tester.pump();
      await tester.tap(find.byType(FossButton), warnIfMissed: false);

      expect(taps, 0);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('disable() blocks taps while onPressed is set', (tester) async {
      final controller = FossButtonController();
      addTearDown(controller.dispose);
      var taps = 0;

      await tester.pumpWidget(
        host(
          FossButton(
            controller: controller,
            onPressed: () => taps++,
            child: const Text('Go'),
          ),
        ),
      );

      controller.disable();
      await tester.pump();
      await tester.tap(find.byType(FossButton), warnIfMissed: false);
      expect(taps, 0);

      controller.idle();
      await tester.pump();
      await tester.tap(find.byType(FossButton));
      expect(taps, 1);
    });
  });
}

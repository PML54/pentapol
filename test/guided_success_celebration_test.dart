// Modified: 2026-09-11 10:32 — vérifier les gestes pendant la célébration et la réduction des animations.
// test/guided_success_celebration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/pentoscope/home/guided_success_celebration.dart';

void main() {
  for (final complete in [false, true]) {
    testWidgets(
      'la célébration laisse passer les gestes et se termine ($complete)',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox.expand(),
                ),
                GuidedSuccessCelebration(
                  origin: const Offset(.5, .5),
                  complete: complete,
                ),
              ],
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          find.byKey(const ValueKey('guided-celebration-paint')),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(200, 200));
        expect(taps, 1);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('guided-celebration-paint')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('réduction des animations : aucun effet animé', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GuidedSuccessCelebration(
            origin: Offset(.5, .5),
            complete: true,
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('guided-celebration-paint')),
      findsNothing,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}

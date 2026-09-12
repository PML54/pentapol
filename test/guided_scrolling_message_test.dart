// Modified: 2026-09-12 03:51 — vitesse doublée, boucle continue, changement de consigne et arrêt accessible.
// Historique: 2026-09-12 03:42 — défilement fini, nouvelle consigne et réduction des animations.
// test/guided_scrolling_message_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/pentoscope/home/guided_scrolling_message.dart';

Widget banner(String text, {bool reduced = false, bool accessible = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduced,
          accessibleNavigation: accessible,
        ),
        child: Center(
          child: SizedBox(
            width: 260,
            height: 150,
            child: GuidedScrollingMessage(
              message: text,
              width: 260,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
void main() {
  for (final text in [
    'Bravo !',
    'Fais défiler le rack, puis choisis une pièce par son numéro.',
  ]) {
    testWidgets('défilement continu accéléré, nouvelle consigne : $text', (
      tester,
    ) async {
      await tester.pumpWidget(banner(text));
      final frame = tester.getRect(find.byType(GuidedScrollingMessage));
      final motion = find.byKey(const ValueKey('guided-message-motion'));
      final initialX = tester.widget<Transform>(motion).transform.storage[12];
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        tester.widget<Transform>(motion).transform.storage[12],
        lessThan(initialX),
      );
      expect(tester.getRect(find.byType(GuidedScrollingMessage)), frame);
      expect(
        tester.widget<Transform>(motion).transform.storage[12],
        closeTo(initialX - 72 * .6, .1),
      );
      final row = tester.widget<Transform>(motion).child! as Row;
      final cycleWidth = (row.children.first as SizedBox).width!;
      final periodMs = (cycleWidth / 72 * 1000).ceil();
      // Deux tours complets : même phase, toujours animé et même taille de bandeau.
      final before = tester.widget<Transform>(motion).transform.storage[12];
      await tester.pump(Duration(milliseconds: periodMs * 2));
      expect(
        tester.widget<Transform>(motion).transform.storage[12],
        closeTo(before, .1),
      );
      expect(tester.getRect(find.byType(GuidedScrollingMessage)), frame);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(banner('Continue !'));
      expect(motion, findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('guided-message'))).data,
        'Continue !',
      );
      expect(tester.widget<Transform>(motion).transform.storage[12], 0);
      await tester.pumpWidget(banner('Continue !', reduced: true));
      expect(motion, findsNothing);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets('consigne fixe en accessibilité : reduced=$reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        banner('Fais défiler le rack', reduced: reduced, accessible: !reduced),
      );
      expect(find.byKey(const ValueKey('guided-message-motion')), findsNothing);
      expect(find.text('Fais défiler le rack'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }
}

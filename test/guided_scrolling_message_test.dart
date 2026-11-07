// Modified: 2026-10-26 15:02 — vérifier les consignes fixes sans animation.
// Historique: 2026-09-12 03:51 — vitesse doublée, boucle continue, changement de consigne et arrêt accessible.
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
    testWidgets('consigne fixe et changement de texte : $text', (tester) async {
      await tester.pumpWidget(banner(text));
      final before = tester.getRect(
        find.byKey(const ValueKey('guided-message')),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const ValueKey('guided-message-motion')), findsNothing);
      expect(
        tester.getRect(find.byKey(const ValueKey('guided-message'))),
        before,
      );
      expect(find.text(text), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(banner('Continue !'));
      expect(find.text('Continue !'), findsOneWidget);
      expect(find.text(text), findsNothing);
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

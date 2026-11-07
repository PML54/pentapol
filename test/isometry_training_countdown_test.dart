// Modified: 2026-10-31 06:51 — conserver cinq étoiles avant 35 secondes en Isométries.
// Historique: 2026-10-31 06:45 — vérifier étoiles, acuité et expiration à trois minutes.
// Historique: 2026-10-09 09:41 — vérifier l'attente avant le démarrage du compte à rebours.
// Historique: 2026-10-09 09:27 — vérifier les 60 s, alerte finale, gel, relance et mouvement réduit.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/widgets/isometry_training_countdown.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('chrono Training, mouvement réduit=$reduced', (tester) async {
      var expirations = 0;
      Future<void> mount({
        bool complete = false,
        bool ready = true,
        int game = 1,
      }) => tester.pumpWidget(
        MaterialApp(
          locale: Locale(reduced ? 'en' : 'fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reduced,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: Center(
                child: IsometryTrainingCountdown(
                  key: ValueKey(game),
                  complete: complete,
                  ready: ready,
                  onExpired: () => expirations++,
                ),
              ),
            ),
          ),
        ),
      );
      await mount(ready: false);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('180 s'), findsOneWidget);
      await mount();
      int filledStars() => tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(const ValueKey('training-stars')),
              matching: find.byType(Icon),
            ),
          )
          .where((icon) => icon.icon == Icons.star)
          .length;
      expect(filledStars(), 5);
      for (final boundary in [
        (34, 5),
        (35, 4),
        (59, 4),
        (60, 3),
        (89, 3),
        (90, 2),
        (149, 2),
        (150, 1),
        (179, 1),
        (180, 0),
      ]) {
        final elapsed =
            180 -
            int.parse(
              tester
                  .widgetList<Text>(find.byType(Text))
                  .firstWhere((text) => text.data?.endsWith(' s') ?? false)
                  .data!
                  .split(' ')
                  .first,
            );
        await tester.pump(Duration(seconds: boundary.$1 - elapsed));
        expect(filledStars(), boundary.$2);
        expect(find.text('${180 - boundary.$1} s'), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0 s'), findsOneWidget);
      expect(expirations, 1);
      await mount(game: 2);
      expect(find.text('180 s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 40));
      expect(filledStars(), 4);
      await mount(game: 2, complete: true);
      await tester.pump(const Duration(seconds: 150));
      expect(find.text('140 s'), findsOneWidget);
      expect(filledStars(), 4);
      expect(expirations, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

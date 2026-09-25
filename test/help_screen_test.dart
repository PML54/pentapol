// Modified: 2026-09-25 15:10 — vérifier les 10 lignes utiles après le second nettoyage.
// Historique: 2026-09-25 15:06 — vérifier les 13 lignes utiles et l'absence des commandes retirées.
// Historique: 2026-09-25 03:14 — 17 lignes : lampe rouge et lampe jaune comptées séparément.
// Historique: 2026-09-25 02:56 — l'écran d'Aide s'ouvre et liste les 16 icônes du jeu (FR/EN).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/screens/help_screen.dart';

void main() {
  for (final lang in ['fr', 'en']) {
    testWidgets('HelpScreen liste les 10 lignes d\'icônes ($lang)', (
      tester,
    ) async {
      // Viewport assez haut pour que toutes les lignes du ListView soient construites.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 2600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const HelpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // lampe rouge + lampe jaune + 7 icônes utiles de GameIcons + home.
      expect(find.byType(ListTile), findsNWidgets(10));
      if (lang == 'fr') {
        expect(find.text('Mode Isométries'), findsNothing);
        expect(find.text('Voir les solutions'), findsNothing);
        expect(find.text('Annuler'), findsNothing);
        expect(find.text('Rotation'), findsNothing);
        expect(find.text('Nombre de solutions'), findsNothing);
        expect(find.text('Nouvelle partie'), findsNothing);
        expect(find.text('Retirer'), findsOneWidget);
      }
    });
  }
}

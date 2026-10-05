// Modified: 2026-10-02 09:20 — vérifier le guide de manipulation en français et en anglais.
// Historique: 2026-10-02 07:24 — vérifier que l'Aide ne contient plus la présentation du développeur.
// Historique: 2026-09-29 05:50 — vérifier la présentation du développeur avant les icônes.
// Historique: 2026-09-25 15:10 — vérifier les 10 lignes utiles après le second nettoyage.
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
      tester.view.physicalSize = const Size(600, 4200);
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

      expect(find.text('Paul Marie Larivière'), findsNothing);
      expect(
        find.text(lang == 'fr' ? 'Jouer à Pentapol' : 'Playing Pentapol'),
        findsOneWidget,
      );
      expect(
        find.textContaining(lang == 'fr' ? '5. Ajuste' : '5. Adjust'),
        findsOneWidget,
      );
      expect(
        find.text(lang == 'fr' ? 'Icônes du jeu' : 'Game icons'),
        findsOneWidget,
      );
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

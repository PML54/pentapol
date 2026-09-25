// Modified: 2026-09-25 03:14 — 17 lignes : lampe rouge et lampe jaune comptées séparément.
// Historique: 2026-09-25 02:56 — l'écran d'Aide s'ouvre et liste les 16 icônes du jeu (FR/EN).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/screens/help_screen.dart';

void main() {
  for (final lang in ['fr', 'en']) {
    testWidgets('HelpScreen liste les 17 lignes d\'icônes ($lang)', (tester) async {
      // Viewport assez haut pour que les 16 lignes du ListView soient toutes construites.
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

      // lampe rouge + lampe jaune (en tête) + 13 icônes de GameIcons (settings dédupliqué)
      // + home + nouvelle partie.
      expect(find.byType(ListTile), findsNWidgets(17));
    });
  }
}

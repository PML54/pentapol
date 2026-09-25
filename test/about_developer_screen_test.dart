// Modified: 2026-09-25 14:43 — vérifier la présentation du développeur en français et en anglais.
// test/about_developer_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/screens/about_developer_screen.dart';

void main() {
  Widget app(Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AboutDeveloperScreen(),
  );

  testWidgets('présentation du développeur en français', (tester) async {
    await tester.pumpWidget(app(const Locale('fr')));

    expect(find.text('À propos du développeur'), findsOneWidget);
    expect(find.text('Paul Marie Larivière'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("D'une génération informatique à l'autre"),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('antichaîne de Sperner'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Remerciements'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('Francine'), findsNWidgets(2));
  });

  testWidgets('présentation du développeur en anglais', (tester) async {
    await tester.pumpWidget(app(const Locale('en')));

    expect(find.text('About the developer'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('From one computing generation to another'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('Sperner antichain'), findsOneWidget);
  });
}

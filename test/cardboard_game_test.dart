// Modified: 2026-11-13 07:02 — vérifier l’ordre et le défilement de la variante bois FR/EN à texte agrandi.
// Historique: 2026-11-13 06:37 — vérifier le titre unique de la carte carton dans les deux langues.
// Historique: 2026-11-13 06:16 — tester l’accès accueil, retour et reprise FR/EN à 320 px et texte ×2.
// Historique: 2026-11-12 07:25 — vérifier le parcours carton FR/EN et la reprise d’ouverture.
// test/cardboard_game_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/config/pentapol_website.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/screens/cardboard_game_screen.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/models/app_settings.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings(hasCompletedDiscovery: true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  for (final lang in ['fr', 'en']) {
    testWidgets('Ordre pédagogique et contenus conservés ($lang)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 4200);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CardboardGameScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(CardboardGameScreen)),
      );
      final texts = [
        l10n.helpShapesTitle,
        l10n.helpShapesRule,
        l10n.helpShapesCount,
        l10n.cardboardSearchTitle,
        l10n.helpShapesChallenge,
        l10n.cardboardMakeTitle,
        l10n.cardboardMaterials,
        l10n.cardboardStepPrint,
        l10n.cardboardStepGlue,
        l10n.cardboardStepCut,
        l10n.cardboardStepPlay,
        l10n.cardboardStepInvent,
        l10n.cardboardAdultHelp,
        l10n.cardboardWoodTitle,
        l10n.cardboardWoodMaterials,
        l10n.cardboardWoodShapes,
        l10n.cardboardWoodGlue,
        l10n.cardboardWoodPaint,
        l10n.cardboardDownload,
      ];
      var previousY = -1.0;
      for (final text in texts) {
        expect(find.text(text), findsOneWidget);
        final y = tester.getTopLeft(find.text(text)).dy;
        expect(y, greaterThan(previousY));
        previousY = y;
      }
      if (lang == 'fr') {
        expect(
          find.text('Et si on faisait de la géométrie en jouant ?'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Atelier depuis l’accueil, petit écran et grand texte ($lang)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var attempts = 0;
        final launched = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'launch') {
              attempts++;
              launched.add((call.arguments as Map)['url'] as String);
              if (attempts == 1) throw PlatformException(code: 'unavailable');
              if (attempts == 2) return false;
              return true;
            }
            return true;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [settingsProvider.overrideWith(_Settings.new)],
            child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = find.byKey(const ValueKey('home-cardboard'));
        await tester.scrollUntilVisible(entry, 200);
        expect(find.byIcon(Icons.content_cut), findsOneWidget);
        final cardTexts = tester.widgetList<Text>(
          find.descendant(of: entry, matching: find.byType(Text)),
        );
        expect(cardTexts.map((text) => text.data), [
          lang == 'fr'
              ? 'Fabrique ton Pentapol en carton'
              : 'Make your own cardboard Pentapol',
        ]);
        expect(tester.takeException(), isNull);
        // Même le bord de la carte ouvre l’activité.
        await tester.tapAt(tester.getTopLeft(entry) + const Offset(24, 4));
        await tester.pumpAndSettle();
        expect(find.byType(CardboardGameScreen), findsOneWidget);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CardboardGameScreen)),
        );
        expect(find.text(l10n.cardboardSlogan), findsOneWidget);
        for (final text in [
          l10n.helpShapesTitle,
          l10n.helpShapesRule,
          l10n.helpShapesCount,
          l10n.cardboardSearchTitle,
          l10n.helpShapesChallenge,
          l10n.cardboardMakeTitle,
          l10n.cardboardMaterialsTitle,
          l10n.cardboardAdultHelp,
          l10n.cardboardWoodTitle,
          l10n.cardboardWoodMaterials,
          l10n.cardboardWoodShapes,
          l10n.cardboardWoodGlue,
          l10n.cardboardWoodPaint,
        ]) {
          await tester.scrollUntilVisible(find.text(text), 100);
          expect(find.text(text), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        final download = find.byKey(const ValueKey('cardboard-download'));
        await tester.scrollUntilVisible(download, 200);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        if (pentapolWebsiteUrl.isEmpty) {
          expect(find.text(l10n.cardboardUnavailable), findsOneWidget);
          expect(tester.widget<FilledButton>(download).onPressed, isNull);
        } else {
          await tester.tap(download);
          await tester.pumpAndSettle();
          expect(find.text(l10n.cardboardOpenError), findsOneWidget);
          await tester.scrollUntilVisible(download, 150);
          expect(find.text(l10n.retry), findsOneWidget);
          await tester.tap(download);
          await tester.pumpAndSettle();
          expect(find.text(l10n.cardboardOpenError), findsOneWidget);
          await tester.scrollUntilVisible(download, 150);
          await tester.tap(download);
          await tester.pumpAndSettle();
          expect(find.text(l10n.cardboardOpenError), findsNothing);
          expect(attempts, 3);
          expect(launched, [
            cardboardActivityUri(lang).toString(),
            cardboardActivityUri(lang).toString(),
            cardboardActivityUri(lang).toString(),
          ]);
          expect(
            Uri.parse(launched.first).path,
            lang == 'fr' ? '/fr/fabriquer/' : '/en/make/',
          );
        }
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(CardboardGameScreen), findsNothing);
        expect(entry, findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

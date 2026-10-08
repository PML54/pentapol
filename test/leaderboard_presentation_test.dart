// Modified: 2026-10-07 07:38 — vérifier l'absence du ratio sous les noms en Stratégie FR/EN.
// Historique: 2026-10-07 02:13 — vérifier secondes seules et passage à une minute en FR/EN.
// Historique: 2026-10-07 02:10 — vérifier points entiers, durées explicites et absence de coups dans Temps.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Settings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  for (final language in ['fr', 'en']) {
    for (final width in [375.0, 800.0]) {
      testWidgets('classements $language, largeur $width', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var timeMs = 100999;
        final container = ProviderContainer(
          overrides: [
            settingsProvider.overrideWith(_Settings.new),
            challengeApiProvider.overrideWithValue(
              ChallengeApi(
                client: MockClient(
                  (request) async => http.Response(
                    jsonEncode({
                      'entries': [
                        {
                          'player_id': 'a' * 32,
                          'pseudo': 'Paul',
                          'time_ms': timeMs,
                          'strategy_actions': 14,
                          'theoretical_moves': 7,
                          'points': 123.6,
                        },
                      ],
                    }),
                    200,
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const LeaderboardScreen(
                day: '2026-10-07',
                size: PentoscopeSize.size3x5,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 min 40 s').hitTestable(), findsOneWidget);
        for (final example in {
          0: '0 s',
          5000: '5 s',
          59999: '59 s',
          60000: '1 min 00 s',
          100999: '1 min 40 s',
        }.entries) {
          timeMs = example.key;
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pumpAndSettle();
          expect(find.text(example.value).hitTestable(), findsOneWidget);
          expect(find.textContaining('0 min').hitTestable(), findsNothing);
        }
        expect(
          tester
              .widget<ListTile>(find.byType(ListTile).hitTestable().first)
              .subtitle,
          isNull,
        );
        await tester.tap(
          find.text(language == 'fr' ? 'Stratégie' : 'Strategy'),
        );
        await tester.pumpAndSettle();
        expect(find.text('14/7').hitTestable(), findsNothing);
        expect(
          tester
              .widget<ListTile>(find.byType(ListTile).hitTestable().first)
              .subtitle,
          isNull,
        );
        expect(
          find.text(language == 'fr' ? '14 coups' : '14 moves').hitTestable(),
          findsOneWidget,
        );
        for (final period in [
          language == 'fr' ? 'Semaine' : 'Week',
          language == 'fr' ? 'Mois' : 'Month',
        ]) {
          await tester.tap(find.text(period));
          await tester.pumpAndSettle();
          expect(find.text('124 pts').hitTestable(), findsOneWidget);
          expect(find.text('14/7').hitTestable(), findsNothing);
          expect(
            tester
                .widget<ListTile>(find.byType(ListTile).hitTestable().first)
                .subtitle,
            isNull,
          );
          await tester.tap(find.text(language == 'fr' ? 'Temps' : 'Time'));
          await tester.pumpAndSettle();
          expect(find.text('124 pts').hitTestable(), findsOneWidget);
          expect(
            tester
                .widget<ListTile>(find.byType(ListTile).hitTestable().first)
                .subtitle,
            isNull,
          );
          await tester.tap(
            find.text(language == 'fr' ? 'Stratégie' : 'Strategy'),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}

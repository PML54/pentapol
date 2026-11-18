// Modified: 2026-11-11 06:37 — Vérifier persistance, réseau et affichage du qualificatif public.
// test/player_qualifier_test.dart
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/models/player_name.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('champ facultatif : limites, normalisation, anciens réglages', () {
    for (final value in [
      '',
      '  ',
      'Lyon',
      'Île-de-France',
      "L’Haÿ",
      'Hibou',
      'Québec',
    ]) {
      expect(validatePlayerQualifier(value), isNull);
    }
    for (final value in ['Rue@', 'a' * 21, '🏠']) {
      expect(validatePlayerQualifier(value), isNotNull);
    }
    expect(AppSettings.fromJson({}).playerQualifier, isNull);
    const settings = AppSettings(userName: 'Paul', playerQualifier: 'Lyon');
    expect(AppSettings.fromJson(settings.toJson()).playerQualifier, 'Lyon');
    expect(settings.copyWith(currentLevel: 2).playerQualifier, 'Lyon');
    expect(
      settings.copyWith(clearPlayerQualifier: true).playerQualifier,
      isNull,
    );
  });

  test('pseudo identique, qualificatifs différents et ancien score', () {
    LeaderboardEntry player(String id, String? qualifier) =>
        LeaderboardEntry.fromJson({
          'player_id': id,
          'pseudo': 'Paul',
          'qualifier': qualifier,
        });
    final lyon = player('aaaa', 'Lyon');
    final quebec = player('bbbb', 'Québec');
    expect(
      leaderboardDisplayName(lyon, [lyon, quebec], 'Joueur'),
      'Paul · Lyon',
    );
    expect(
      leaderboardDisplayName(quebec, [lyon, quebec], 'Joueur'),
      'Paul · Québec',
    );
    final old = player('cccc', null);
    expect(leaderboardDisplayName(old, [old], 'Joueur'), 'Paul');
  });

  test(
    'qualificatif inclus dans les scores hors ligne et la requête HTTP',
    () async {
      final score = PendingChallengeScore.fromJson({
        'version': 3,
        'day': '2026-11-11',
        'size': 0,
        'playerId': 'a' * 32,
        'pseudo': 'Paul',
        'qualifier': 'Lyon',
      });
      expect(PendingChallengeScore.fromJson(score.toJson()).qualifier, 'Lyon');
      Map<String, dynamic>? payload;
      final api = ChallengeApi(
        client: MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 201);
        }),
      );
      expect(
        await api.submitScore(
          version: score.version,
          day: score.day,
          size: score.size,
          playerId: score.playerId,
          pseudo: score.pseudo,
          qualifier: score.qualifier,
          minIso: 0,
          isoCount: 0,
          faults: 0,
          timeMs: 0,
          moves: 0,
          grid: '123',
        ),
        isTrue,
      );
      expect(payload!['pseudo'], 'Paul');
      expect(payload!['qualifier'], 'Lyon');
    },
  );

  for (final lang in ['fr', 'en']) {
    testWidgets(
      'paramètres : enregistrer, retrouver et effacer le qualificatif $lang',
      (tester) async {
        final db = SettingsDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final container = ProviderContainer(
          overrides: [settingsDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(settingsProvider.notifier);
        await notifier.ensureLoaded();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final title = lang == 'fr'
            ? 'Ville ou qualificatif (facultatif)'
            : 'City or qualifier (optional)';
        final save = lang == 'fr' ? 'Sauvegarder' : 'Save';
        await tester.scrollUntilVisible(find.text(title), 300);
        await Scrollable.ensureVisible(
          tester.element(find.text(title)),
          alignment: 0.3,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '  Lyon  ');
        await tester.tap(find.text(save));
        await tester.pumpAndSettle();
        expect(container.read(settingsProvider).playerQualifier, 'Lyon');
        expect(find.text('Lyon'), findsOneWidget);
        // Recréation avec la même base : donnée effectivement persistée.
        final restored = ProviderContainer(
          overrides: [settingsDatabaseProvider.overrideWithValue(db)],
        );
        await restored.read(settingsProvider.notifier).ensureLoaded();
        expect(restored.read(settingsProvider).playerQualifier, 'Lyon');
        restored.dispose();
        await Scrollable.ensureVisible(
          tester.element(find.text(title)),
          alignment: 0.3,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '');
        await tester.tap(find.text(save));
        await tester.pumpAndSettle();
        expect(container.read(settingsProvider).playerQualifier, isNull);
      },
    );
  }
}

// Modified: 2026-10-05 07:43 — vérifier que la purge locale efface les scores de défi en attente.
// Historique: 2026-10-02 06:39 — vérifier purge locale, conservation du profil et confirmation à l'accueil.
// test/reset_local_results_test.dart
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/home/animated_home_board.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';

Future<AppSettings> seed(SettingsDatabase db) async {
  final settings = AppSettings(
    userName: 'Paul',
    playerId: '0123456789abcdef0123456789abcdef',
    currentLevel: 7,
    localeCode: 'fr',
    shareScoresOptIn: true,
    challengeConsentAsked: true,
    game: const GameSettings().copyWith(enableHaptics: false),
    duel: DuelSettings.defaults.copyWith(
      playerName: 'Paul Duo',
      totalWins: 2,
      totalGamesPlayed: 2,
    ),
    pieceAcuityTotals: const {
      1: PieceAcuityTotals(placements: 2, theoretical: 2, actual: 3),
    },
    attemptHistory: [
      PlayerAttemptSummary.fromJson({'sizeName': 'size3x5', 'completed': true}),
    ],
    dailyChallengeDay: '2026-10-02',
    completedDailyChallengeSizes: const [0, 1],
    pendingChallengeScores: const [
      PendingChallengeScore(
        version: 2,
        day: '2026-10-02',
        size: 0,
        playerId: '0123456789abcdef0123456789abcdef',
        pseudo: 'Paul',
        minIso: 1,
        isoCount: 2,
        faults: 0,
        timeMs: 10000,
        moves: 4,
        grid: '1,1,1,1,1',
      ),
    ],
  );
  await db.setSetting('app_settings', jsonEncode(settings.toJson()));
  await db.setSetting('other', 'preserved');
  await db.recordPuzzleCompleted(
    sizeName: 'size3x5',
    minIso: 1,
    isoCount: 2,
    faults: 0,
    timeSeconds: 10,
    clean: true,
  );
  await db.recordSolvedSolution(
    board: '6x10',
    solutionNumber: 1,
    minIso: 1,
    isoCount: 2,
    faults: 0,
    timeSeconds: 10,
    clean: true,
  );
  await db.saveCurrentGame(
    sizeName: 'size3x5',
    pieceIds: '1,2,3',
    solutionCount: 1,
    placedPieces: '[]',
    positionIndices: '{}',
    elapsedSeconds: 10,
    isometryCount: 0,
    translationCount: 0,
    deleteCount: 0,
    hintCount: 0,
    faultCount: 0,
    isProgression: true,
    initialOrientations: '{}',
  );
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'la purge efface les résultats et conserve identité, réglages et niveaux',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final original = await seed(db);
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await container.read(settingsProvider.notifier).resetLocalResults();
      final persisted = AppSettings.fromJson(
        jsonDecode((await db.getSetting('app_settings'))!)
            as Map<String, dynamic>,
      );
      expect(
        persisted.toJson(),
        original
            .copyWith(
              pieceAcuityTotals: const {},
              attemptHistory: const [],
              duel: original.duel.resetStats(),
              clearDailyChallengeDay: true,
              completedDailyChallengeSizes: const [],
              pendingChallengeScores: const [],
            )
            .toJson(),
      );
      expect(container.read(settingsProvider).toJson(), persisted.toJson());
      expect(await db.select(db.currentGame).get(), isEmpty);
      expect(await db.select(db.solvedSolutions).get(), isEmpty);
      expect(await db.select(db.puzzleStats).get(), isEmpty);
      expect(await db.getSetting('other'), 'preserved');
    },
  );

  test('un échec de sauvegarde annule toute la purge', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    final original = await seed(db);
    final container = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await container.read(settingsProvider.notifier).ensureLoaded();
    await db.customStatement(
      "CREATE TRIGGER reject_reset BEFORE UPDATE ON settings BEGIN SELECT RAISE(ABORT, 'test failure'); END;",
    );
    await expectLater(
      container.read(settingsProvider.notifier).resetLocalResults(),
      throwsA(isA<Exception>()),
    );
    expect(await db.loadCurrentGame(), isNotNull);
    expect(await db.select(db.solvedSolutions).get(), hasLength(1));
    expect(await db.select(db.puzzleStats).get(), hasLength(1));
    expect(container.read(settingsProvider).toJson(), original.toJson());
    expect(
      jsonDecode((await db.getSetting('app_settings'))!),
      original.toJson(),
    );
  });

  testWidgets(
    'à 320 px, annuler conserve les données et confirmer les efface',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      await seed(db);
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          homeDemoSolutionsProvider.overrideWith(
            (ref) async => throw StateError('Demo unavailable'),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      await container.read(settingsProvider.notifier).ensureLoaded();
      await container
          .read(pentoscopeProvider.notifier)
          .restoreGame((await db.loadCurrentGame())!);
      expect(container.read(pentoscopeProvider).puzzle, isNotNull);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-reset-results')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await db.loadCurrentGame(), isNotNull);
      expect(await db.select(db.puzzleStats).get(), isNotEmpty);
      await tester.tap(find.byKey(const ValueKey('home-reset-results')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Réinitialiser'));
      await tester.pumpAndSettle();
      expect(await db.loadCurrentGame(), isNull);
      expect(await db.select(db.puzzleStats).get(), isEmpty);
      expect(container.read(pentoscopeProvider).puzzle, isNull);
      await container
          .read(pentoscopeProvider.notifier)
          .saveCurrentGameSnapshot();
      expect(await db.loadCurrentGame(), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}

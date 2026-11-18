// Modified: 2026-11-18 02:34 — départ quotidien au niveau 1 pour toutes les ceintures.
// Historique: 2026-11-17 09:44 — icône seule au profil et passages successifs dans le temps imparti.
// Historique: 2026-11-17 09:07 — vérifier seuils, persistance et tentatives quotidiennes des ceintures.
// test/challenge_belts_test.dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/config/challenge_belts.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/solution_source.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('accès strictement successif, y compris après la ceinture noire', () {
    bool enter(
      int belt,
      int size, {
      bool today = false,
      int last = -1,
      bool passed = false,
    }) => canEnterBeltChallenge(
      belt: belt,
      sizeIndex: size,
      attemptedToday: today,
      lastSize: last,
      lastPassed: passed,
    );
    expect(enter(0, 1), isFalse);
    expect(enter(0, 0), isTrue);
    expect(enter(0, 0, today: true, last: 0), isFalse);
    expect(enter(1, 1, today: true, last: 0, passed: true), isTrue);
    expect(enter(6, 0), isTrue);
    expect(enter(6, 1), isFalse);
    expect(enter(6, 1, today: true, last: 0), isFalse);
    expect(enter(6, 1, today: true, last: 0, passed: true), isTrue);
    expect(enter(6, 2, today: true, last: 0, passed: true), isFalse);
  });
  test('chaque ceinture recommence au premier défi chaque jour', () {
    for (var belt = 0; belt <= 6; belt++) {
      for (var size = 0; size < 6; size++) {
        expect(
          canEnterBeltChallenge(
            belt: belt,
            sizeIndex: size,
            attemptedToday: false,
            lastSize: 4,
            lastPassed: true,
          ),
          size == 0,
        );
        expect(
          canEnterBeltChallenge(
            belt: belt,
            sizeIndex: size,
            attemptedToday: true,
            lastSize: 0,
            lastPassed: true,
          ),
          size == 1,
        );
        expect(
          canEnterBeltChallenge(
            belt: belt,
            sizeIndex: size,
            attemptedToday: true,
            lastSize: 0,
            lastPassed: false,
          ),
          isFalse,
        );
      }
    }
  });
  test('six seuils inclusifs, aucun saut et aucune régression', () {
    expect(beltTimeLimits, [30, 60, 90, 120, 150, 180]);
    for (var belt = 0; belt < 6; belt++) {
      final max = beltTimeLimits[belt];
      expect(earnedChallengeBelt(belt, belt, max - 1), belt + 1);
      expect(earnedChallengeBelt(belt, belt, max), belt + 1);
      expect(earnedChallengeBelt(belt, belt, max + 1), belt);
      expect(earnedChallengeBelt(belt, belt, -1), belt);
      expect(earnedChallengeBelt(belt, belt + 1, 0), belt);
      expect(earnedChallengeBelt(belt, belt - 1, 0), belt);
    }
    expect(earnedChallengeBelt(6, 5, 1), 6);
  });
  test('anciens profils blancs même si Solo est au niveau neuf', () {
    expect(AppSettings.fromJson({'currentLevel': 9}).challengeBelt, 0);
    final settings = const AppSettings(
      challengeBelt: 4,
      beltAttemptDay: '2026-11-17',
      beltAttemptSize: 3,
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.challengeBelt, 4);
    expect(restored.beltAttemptDay, '2026-11-17');
    expect(restored.beltAttemptSize, 3);
  });
  test(
    'persistance SQLite, dépassement, doublon, reset et lendemain',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      ProviderContainer create() => ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      var c = create();
      var settings = c.read(settingsProvider.notifier);
      await settings.ensureLoaded();
      await settings.completeDailyChallengeSize(
        '2026-11-17',
        0,
        elapsedSeconds: 30,
      );
      await settings.completeDailyChallengeSize(
        '2026-11-17',
        1,
        elapsedSeconds: 61,
      );
      expect(c.read(settingsProvider).challengeBelt, 1);
      await settings.completeDailyChallengeSize(
        '2026-11-17',
        1,
        elapsedSeconds: 1,
      );
      expect(c.read(settingsProvider).challengeBelt, 1);
      await settings.resetLocalResults();
      await settings.completeDailyChallengeSize(
        '2026-11-17',
        1,
        elapsedSeconds: 1,
      );
      expect(c.read(settingsProvider).challengeBelt, 1);
      c.dispose();
      c = create();
      addTearDown(c.dispose);
      settings = c.read(settingsProvider.notifier);
      await settings.ensureLoaded();
      expect(c.read(settingsProvider).challengeBelt, 1);
      expect(c.read(settingsProvider).beltAttemptSize, 1);
      expect(c.read(settingsProvider).beltAttemptPassed, isFalse);
      await settings.dailyChallengeCompletions(DateTime.utc(2026, 11, 18));
      expect(c.read(settingsProvider).challengeBelt, 1);
      await settings.completeDailyChallengeSize(
        '2026-11-18',
        0,
        elapsedSeconds: 30,
      );
      expect(c.read(settingsProvider).challengeBelt, 1);
      for (var i = 1; i < 6; i++) {
        await settings.completeDailyChallengeSize(
          '2026-11-18',
          i,
          elapsedSeconds: (i + 1) * 30,
        );
        expect(c.read(settingsProvider).challengeBelt, i + 1);
      }
      await settings.dailyChallengeCompletions(DateTime.utc(2026, 11, 19));
      expect(c.read(settingsProvider).challengeBelt, 6);
      await settings.advanceLevel();
      expect(c.read(settingsProvider).challengeBelt, 6);
      expect(c.read(settingsProvider).shareScoresOptIn, isFalse);
    },
  );
  test('Solo et complétion sans temps ne donnent pas de ceinture', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(c.dispose);
    final s = c.read(settingsProvider.notifier);
    await s.ensureLoaded();
    await s.advanceLevel();
    await s.completeDailyChallengeSize('2026-11-17', 0);
    expect(c.read(settingsProvider).challengeBelt, 0);
  });
  for (final seconds in [30, 31]) {
    test(
      'vraie grille terminée en $seconds secondes attribue ou refuse la jaune',
      () async {
        final db = SettingsDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final c = ProviderContainer(
          overrides: [settingsDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(c.dispose);
        await c.read(settingsProvider.notifier).ensureLoaded();
        final game = c.read(pentoscopeProvider.notifier);
        final definition = await game.dailyChallengeDefinition(
          kChallengeSizes.first,
          date: DateTime.utc(2026, 11, 17),
        );
        await game.startChallenge(definition);
        final before = c.read(pentoscopeProvider);
        final corpus = await c.read(tirageCorpusProvider.future);
        final solution = CorpusSolutionSource(
          corpus.solutionsFor(definition.mask),
          width: definition.size.width,
          height: definition.size.height,
        ).hintFrom(before.plateau, before.availablePieces)!;
        for (final piece in solution) {
          if (before.fixedPieceIds.contains(piece.piece.id)) continue;
          game.selectPiece(piece.piece);
          for (var reflection = 0; reflection < 2; reflection++) {
            for (var rotation = 0; rotation < 4; rotation++) {
              if (c.read(pentoscopeProvider).selectedPositionIndex ==
                  piece.positionIndex) {
                break;
              }
              game.applyIsometryRotationCW();
            }
            if (c.read(pentoscopeProvider).selectedPositionIndex ==
                piece.positionIndex) {
              break;
            }
            game.applyIsometrySymmetryH();
          }
          game.restoreTimerOrigin(seconds);
          game.startTimer();
          expect(game.tryPlaceAtAnchor(piece.gridX, piece.gridY), isTrue);
        }
        expect(c.read(pentoscopeProvider).isComplete, isTrue);
        await game.waitForChallengeCompletion();
        expect(c.read(settingsProvider).challengeBelt, seconds == 30 ? 1 : 0);
        expect(c.read(settingsProvider).completedDailyChallengeSizes, [0]);
        await game.saveCurrentGameSnapshot();
      },
    );
  }
}

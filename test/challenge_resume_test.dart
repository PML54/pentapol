// Modified: 2026-11-17 09:07 — adapter les vérifications aux ceintures et au passage suivant.
// Historique: 2026-11-11 05:57 — vérifier la reprise persistée des défis et l’exclusion du temps interrompu.
// test/challenge_resume_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/pentoscope/screens/challenge_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reprise après recréation du provider : plateau, orientations, compteurs et temps',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      ProviderContainer create() => ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      var container = create();
      await container.read(settingsProvider.notifier).ensureLoaded();
      var game = container.read(pentoscopeProvider.notifier);
      final definition = await game.dailyChallengeDefinition(
        kChallengeSizes.first,
        date: DateTime.utc(2026, 11, 11),
      );
      await game.startOrResumeChallenge(definition);
      game.selectPiece(
        container.read(pentoscopeProvider).availablePieces.first,
      );
      for (
        var i = 0;
        i < 8 && container.read(pentoscopeProvider).validPlacements.isEmpty;
        i++
      ) {
        if (i == 4) game.applyIsometrySymmetryH();
        game.applyIsometryRotationCW();
      }
      final placement = container
          .read(pentoscopeProvider)
          .validPlacements
          .first;
      expect(game.tryPlaceAtAnchor(placement.x, placement.y), isTrue);
      game.restoreTimerOrigin(17);
      game.startTimer();
      await game.suspendChallenge();
      final before = container.read(pentoscopeProvider);
      expect(before.elapsedSeconds, 17);
      expect(game.isTimerRunning, isFalse);
      expect(await db.loadCurrentGame(), isNull);
      container.dispose();

      container = create();
      addTearDown(container.dispose);
      await container.read(settingsProvider.notifier).ensureLoaded();
      game = container.read(pentoscopeProvider.notifier);
      await game.startOrResumeChallenge(definition);
      final after = container.read(pentoscopeProvider);
      expect(after.isRanked, isTrue);
      expect(after.elapsedSeconds, 17);
      expect(game.isTimerRunning, isFalse);
      expect(after.plateau.grid, before.plateau.grid);
      expect(
        [
          for (final p in after.placedPieces)
            [p.piece.id, p.positionIndex, p.gridX, p.gridY],
        ],
        [
          for (final p in before.placedPieces)
            [p.piece.id, p.positionIndex, p.gridX, p.gridY],
        ],
      );
      expect(after.piecePositionIndices, before.piecePositionIndices);
      expect(after.fixedPieceIds, before.fixedPieceIds);
      expect(after.strategyActions.toJson(), before.strategyActions.toJson());
      expect(after.isometryCount, before.isometryCount);
      game.selectPiece(after.availablePieces.first);
      expect(game.isTimerRunning, isFalse);
      game.applyIsometryRotationCW();
      expect(game.isTimerRunning, isTrue);
      expect(game.getElapsedSeconds(), 17);
      await game.suspendChallenge();
    },
  );

  testWidgets(
    'le menu Défi ouvre directement la première taille non terminée',
    (tester) async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(
        () => tester.runAsync(() async {
          await container.read(pentoscopeProvider.notifier).suspendChallenge();
          container.dispose();
        }),
      );
      await tester.runAsync(() async {
        final settings = container.read(settingsProvider.notifier);
        await settings.ensureLoaded();
        await settings.completeDailyChallengeSize(
          challengeDay(),
          kChallengeSizes.first.index,
          elapsedSeconds: 30,
        );
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('home-challenge')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 12; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
      }
      await tester.pumpAndSettle();
      expect(find.byType(ChallengeScreen), findsNothing);
      expect(find.byType(PentoscopeGameScreen), findsOneWidget);
      expect(
        container.read(pentoscopeProvider.notifier).activeChallenge!.size,
        kChallengeSizes[1],
      );
      expect(
        container.read(pentoscopeProvider.notifier).isTimerRunning,
        isFalse,
      );
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.home_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      for (var i = 0; i < 5; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        container.read(pentoscopeProvider.notifier).isTimerRunning,
        isFalse,
      );
    },
  );

  test(
    'la sauvegarde du défi préserve le Solo et fige aussi le passage en arrière-plan',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await container.read(settingsProvider.notifier).ensureLoaded();
      final game = container.read(pentoscopeProvider.notifier);
      await game.startPuzzle(kChallengeSizes.first, isProgression: true);
      await game.saveCurrentGameSnapshot();
      final solo = await db.loadCurrentGame();
      expect(solo, isNotNull);
      final definition = await game.dailyChallengeDefinition(
        kChallengeSizes.first,
        date: DateTime.utc(2026, 11, 11),
      );
      await game.startOrResumeChallenge(definition);
      game.restoreTimerOrigin(30);
      game.startTimer();
      game.pauseTimerForBackground();
      await game.saveCurrentGameSnapshot();
      expect(container.read(pentoscopeProvider).elapsedSeconds, 30);
      game.resumeTimerFromBackground();
      expect(game.isTimerRunning, isFalse);
      game.selectPiece(
        container.read(pentoscopeProvider).availablePieces.first,
      );
      game.applyIsometryRotationCW();
      expect(game.getElapsedSeconds(), 30);
      await game.suspendChallenge();
      final preserved = await db.loadCurrentGame();
      expect(preserved!.pieceIds, solo!.pieceIds);
      expect(preserved.placedPieces, solo.placedPieces);
      expect(preserved.positionIndices, solo.positionIndices);
      expect(preserved.isProgression, isTrue);
    },
  );

  test('un nouveau jour ignore le défi interrompu de la veille', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).ensureLoaded();
    final game = container.read(pentoscopeProvider.notifier);
    final yesterday = await game.dailyChallengeDefinition(
      kChallengeSizes.first,
      date: DateTime.utc(2026, 11, 10),
    );
    await game.startOrResumeChallenge(yesterday);
    game.restoreTimerOrigin(35);
    game.startTimer();
    await game.suspendChallenge();
    final today = await game.dailyChallengeDefinition(
      kChallengeSizes.first,
      date: DateTime.utc(2026, 11, 11),
    );
    await game.startOrResumeChallenge(today);
    expect(container.read(pentoscopeProvider).elapsedSeconds, 0);
    expect(game.activeChallenge!.day, today.day);
    expect(game.isTimerRunning, isFalse);
    await game.suspendChallenge();
  });
}

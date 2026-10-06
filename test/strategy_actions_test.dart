// Modified: 2026-10-06 04:52 — vérifier la remise à zéro des seuls Défis locaux sans reprendre les anciens scores.
// Historique: 2026-10-06 04:48 — vérifier la persistance de la règle du minimum de la solution finale.
// Historique: 2026-10-06 04:22 — vérifier le renvoi des coups théoriques avec les compteurs hors ligne.
// Historique: 2026-10-05 20:02 — vérifier les gestes refusés, previews, effacements et reprise des compteurs.
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/strategy_actions.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'une action par tentative, aucune pour les previews, reprise fidèle',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [settingsDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final game = container.read(pentoscopeProvider.notifier);
      await game.drawMask(PentoscopeSize.size3x5);
      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);
      final piece = container.read(pentoscopeProvider).availablePieces.first;
      game.selectPiece(piece);
      game.applyIsometryRotationCW(preview: true);
      game.applyIsometrySymmetryH(preview: true);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
      game.applyIsometryRotationCW();
      game.applyIsometrySymmetryH();
      expect(game.tryPlaceAtAnchor(-50, -50), isFalse);
      game.recordRejectedDrop();
      var actions = container.read(pentoscopeProvider).strategyActions;
      expect(actions.count(StrategyAction.rotation), 1);
      expect(actions.count(StrategyAction.symmetry), 1);
      expect(actions.count(StrategyAction.placement), 2);
      final target = container.read(pentoscopeProvider).validPlacements.first;
      expect(game.tryPlaceAtAnchor(target.x, target.y), isTrue);
      final placed = container.read(pentoscopeProvider).placedPieces.single;
      final cell = placed.absoluteCells.first;
      game.selectPlacedPiece(placed, cell.x, cell.y);
      expect(game.tryPlaceAtAnchor(-50, -50), isFalse);
      game.recordRejectedDrop();
      game.removePlacedPiece(placed);
      actions = container.read(pentoscopeProvider).strategyActions;
      expect(actions.count(StrategyAction.placement), 3);
      expect(actions.count(StrategyAction.translation), 2);
      expect(actions.count(StrategyAction.removal), 1);
      expect(actions.total, 8);
      await game.saveCurrentGameSnapshot();
      final saved = (await db.loadCurrentGame())!;
      await game.restoreGame(saved);
      expect(
        container.read(pentoscopeProvider).strategyActions.toJson(),
        actions.toJson(),
      );
      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);
      expect(container.read(pentoscopeProvider).strategyActions.total, 0);
    },
  );

  test('un ancien snapshot ne reçoit pas de score Stratégie inventé', () {
    expect(StrategyActions.fromJson(null).eligible, isFalse);
  });

  test(
    'la nouvelle règle remet à zéro les seuls Défis locaux une seule fois',
    () {
      final current = const AppSettings(
        userName: 'Paul',
        currentLevel: 5,
        playerId: 'player',
        shareScoresOptIn: true,
        localeCode: 'fr',
        dailyChallengeDay: '2026-10-06',
        completedDailyChallengeSizes: [0, 1],
      ).toJson();
      expect(AppSettings.fromJson(current).completedDailyChallengeSizes, [
        0,
        1,
      ]);
      final old = {...current}..remove('dailyChallengeScoringRevision');
      old['pendingChallengeScores'] = [
        {'version': 2, 'day': '2026-10-06'},
      ];
      final reset = AppSettings.fromJson(old);
      expect(reset.dailyChallengeDay, isNull);
      expect(reset.completedDailyChallengeSizes, isEmpty);
      expect(reset.pendingChallengeScores, isEmpty);
      expect(reset.userName, 'Paul');
      expect(reset.currentLevel, 5);
      expect(reset.playerId, 'player');
      expect(reset.shareScoresOptIn, isTrue);
      expect(reset.localeCode, 'fr');
      final next = reset.copyWith(
        dailyChallengeDay: '2026-10-06',
        completedDailyChallengeSizes: [0],
      );
      expect(AppSettings.fromJson(next.toJson()).completedDailyChallengeSizes, [
        0,
      ]);
    },
  );

  test('la file hors ligne conserve le détail et le renvoie à API', () async {
    final original = PendingChallengeScore(
      version: 2,
      day: '2026-10-05',
      size: 0,
      playerId: 'a' * 32,
      pseudo: 'Player',
      minIso: 0,
      isoCount: 2,
      faults: 0,
      timeMs: 1000,
      moves: 3,
      grid: '123',
      strategyActions: 5,
      theoreticalMoves: 3,
      finalSolutionMinimum: true,
      actionCounts: const {
        'placement': 3,
        'rotation': 1,
        'symmetry': 1,
        'translation': 0,
        'removal': 0,
      },
    );
    final restored = PendingChallengeScore.fromJson(
      jsonDecode(jsonEncode(original.toJson())),
    );
    final api = ChallengeApi(
      client: MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(body['strategyActions'], 5);
        expect(body['theoreticalMoves'], 3);
        expect(body['finalSolutionMinimum'], isTrue);
        expect(body['actionCounts'], original.actionCounts);
        return http.Response('{}', 201);
      }),
    );
    expect(
      await api.submitScore(
        version: restored.version,
        day: restored.day,
        size: restored.size,
        playerId: restored.playerId,
        pseudo: restored.pseudo,
        minIso: restored.minIso,
        isoCount: restored.isoCount,
        faults: restored.faults,
        timeMs: restored.timeMs,
        moves: restored.moves,
        grid: restored.grid,
        strategyActions: restored.strategyActions,
        theoreticalMoves: restored.theoreticalMoves,
        finalSolutionMinimum: restored.finalSolutionMinimum,
        actionCounts: restored.actionCounts,
      ),
      isTrue,
    );
  });
}

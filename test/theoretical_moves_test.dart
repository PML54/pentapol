// Modified: 2026-10-07 07:40 — vérifier l'identité du minimum annoncé et du minimum final du défi.
// Historique: 2026-10-07 06:53 — vérifier que le minimum et les coups excluent les pièces fixes du défi unique.
// Historique: 2026-10-06 04:52 — vérifier les minima finaux et attendre la persistance avant fermeture du test.
// Historique: 2026-10-06 04:48 — vérifier le minimum propre à chaque solution finale jouée.
// Historique: 2026-10-06 04:22 — vérifier le minimum de coups pour les neuf tailles contre une énumération exhaustive.
import 'package:drift/native.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pentapol/common/byte_matching.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/completion_metrics.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_solutions_provider.dart';
import 'package:pentapol/pentoscope/strategy_actions.dart';
import 'package:pentapol/pentoscope/solution_source.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'minimum propre à chaque solution des neuf tailles et à la partie jouée',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final posted = <Map<String, dynamic>>[];
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          challengeApiProvider.overrideWithValue(
            ChallengeApi(
              client: MockClient((request) async {
                if (request.method == 'POST') {
                  posted.add(jsonDecode(request.body) as Map<String, dynamic>);
                  return http.Response('{}', 201);
                }
                return http.Response('{}', 404);
              }),
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final corpus = await container.read(tirageCorpusProvider.future);
      final generator = PentoscopeGenerator();
      for (final size in kChallengeSizes) {
        final challenge = deriveChallenge(
          date: DateTime.utc(2026, 10, 6),
          size: size,
          solubleMasks: await generator.solubleMasksFor(size),
          solutionCountForMask: generator.countOfMask,
        );
        final Iterable<List<PlacedPiece>> solutions;
        if (size.table case final table?) {
          final matcher = await container.read(
            pentoscopeSolutionsProvider(table).future,
          );
          expect(matcher.totalSolutions, 9356);
          solutions = Iterable.generate(
            matcher.totalSolutions,
            (index) => matcher.getPlacedPiecesByIndex(index)!,
          );
        } else {
          final bytes = corpus.solutionsFor(challenge.mask);
          solutions = Iterable.generate(
            challenge.solutionCount,
            (index) => flatBoardToPlacedPieces(
              bytes,
              index * size.area,
              size.width,
              size.height,
            ),
          );
        }
        var enumerated = 0;
        for (final solution in solutions) {
          final metrics = computeMetrics(
            placedPieces: solution,
            initialOrientations: challenge.orientations,
            isometryCount: 0,
            timeSeconds: 0,
          );
          expect(
            minimumSolutionMoves(solution, challenge.orientations),
            solution.length + metrics.minIso,
          );
          enumerated++;
        }
        expect(enumerated, challenge.solutionCount);
        // The rack of an existing solution always admits exactly one placement per piece.
        final perfectRack = {
          for (final placed in solutions.first)
            placed.piece.id: placed.positionIndex,
        };
        expect(
          minimumSolutionMoves(solutions.first, perfectRack),
          size.numPieces,
        );
      }
      final game = container.read(pentoscopeProvider.notifier);
      final definition = await game.dailyChallengeDefinition(
        PentoscopeSize.size3x5,
        date: DateTime.utc(2026, 10, 6),
      );
      await game.startDailyChallenge(
        PentoscopeSize.size3x5,
        date: DateTime.utc(2026, 10, 6),
      );
      expect(game.activeChallenge!.mask, definition.mask);
      await container.read(settingsProvider.notifier).ensureLoaded();
      expect(game.computeCompletionMetrics()!.theoreticalMoves, isNull);
      final bytes = corpus.solutionsFor(definition.mask);
      expect(definition.solutionCount, 1);
      expect(definition.fixedPieces, hasLength(1));
      for (var index = 0; index < definition.solutionCount; index++) {
        await game.startChallenge(definition);
        final before = container.read(pentoscopeProvider);
        final solution = CorpusSolutionSource(
          bytes,
          width: definition.size.width,
          height: definition.size.height,
        ).hintFrom(before.plateau, before.availablePieces)!;
        final initial = before.initialOrientations;
        for (final fixed in definition.fixedPieces) {
          final cell = fixed.absoluteCells.first;
          game.selectPlacedPiece(fixed, cell.x, cell.y);
          game.selectPiece(fixed.piece);
          game.removePlacedPiece(fixed);
          expect(container.read(pentoscopeProvider).selectedPiece, isNull);
          expect(container.read(pentoscopeProvider).strategyActions.total, 0);
          expect(
            container.read(pentoscopeProvider).placedPieces.length,
            definition.fixedPieces.length,
          );
        }
        for (final placed in solution) {
          if (before.fixedPieceIds.contains(placed.piece.id)) {
            continue;
          }
          game.selectPiece(placed.piece);
          // Visit both rotation orbits using only the real game controls.
          for (var reflection = 0; reflection < 2; reflection++) {
            for (var rotation = 0; rotation < 4; rotation++) {
              if (container.read(pentoscopeProvider).selectedPositionIndex ==
                  placed.positionIndex) {
                break;
              }
              game.applyIsometryRotationCW();
            }
            if (container.read(pentoscopeProvider).selectedPositionIndex ==
                placed.positionIndex) {
              break;
            }
            game.applyIsometrySymmetryH();
          }
          expect(
            container.read(pentoscopeProvider).selectedPositionIndex,
            placed.positionIndex,
          );
          expect(game.tryPlaceAtAnchor(placed.gridX, placed.gridY), isTrue);
        }
        final playable = solution
            .where((piece) => !before.fixedPieceIds.contains(piece.piece.id))
            .toList();
        final expected =
            playable.length +
            computeMetrics(
              placedPieces: playable,
              initialOrientations: initial,
              isometryCount: 0,
              timeSeconds: 0,
            ).minIso;
        expect(container.read(pentoscopeProvider).isComplete, isTrue);
        expect(game.computeCompletionMetrics()!.theoreticalMoves, expected);
        expect(definition.theoreticalMoves, expected);
        expect(
          container
              .read(pentoscopeProvider)
              .strategyActions
              .count(StrategyAction.placement),
          playable.length,
        );
        await container
            .read(settingsProvider.notifier)
            .completeDailyChallengeSize(definition.day, definition.size.index);
        await container
            .read(settingsProvider.notifier)
            .setShareScoresOptIn(true);
        await game.submitChallengeScore();
        expect(posted, hasLength(1));
        expect(posted.single['version'], kChallengeVersion);
        expect(posted.single['moves'], playable.length);
        expect(posted.single['theoreticalMoves'], expected);
        expect(posted.single['actionCounts']['placement'], playable.length);
        expect(
          posted.single['strategyActions'],
          container.read(pentoscopeProvider).strategyActions.total,
        );
      }
      await db.customSelect('SELECT 1').get();
    },
  );
}

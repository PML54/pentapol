// Modified: 2026-09-22 05:35 — vérifier le Training 2 réel : deux pièces voisines retirées,
//           rack réorienté et plateau à solution unique.
// Historique: 2026-09-21 08:49 — vérifier le puzzle training 5x7 construit par le vrai moteur Game.
// Historique: 2026-09-12 10:58 — parcours réel du corpus, barème figé, reprise SQLite, Triche et exclusion des records.
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';

class _Game extends PentoscopeNotifier {
  void load(PentoscopeState next) => state = next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'vraies impasses, réglages figés, SQLite, reprise et partie suivante',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      container.read(pentoscopeProvider);
      final settings = container.read(settingsProvider.notifier);
      await settings.ensureLoaded();
      const first = GeometryRules(fillPenalty: 12, exponent: 3, areaPenalty: 7);
      const next = GeometryRules(fillPenalty: 30, areaPenalty: 10);
      await settings.setGeometryRules(first);
      await game.drawMask(PentoscopeSize.size3x5);
      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);
      final baseline = container.read(pentoscopeProvider);
      expect(baseline.geometry!.rules.toJson(), first.toJson());
      await settings.setGeometryRules(next);
      expect(
        container.read(pentoscopeProvider).geometry!.rules.toJson(),
        first.toJson(),
      );
      // Chercher un placement légal qui crée réellement une impasse dans le corpus.
      var found = false;
      search:
      for (final piece in baseline.availablePieces) {
        for (
          var orientation = 0;
          orientation < piece.numOrientations;
          orientation++
        ) {
          for (var y = 0; y < baseline.plateau.height; y++) {
            for (var x = 0; x < baseline.plateau.width; x++) {
              if (!baseline.canPlacePiece(piece, orientation, x, y)) continue;
              game.load(
                baseline.copyWith(
                  piecePositionIndices: {piece.id: orientation},
                ),
              );
              game.selectPiece(piece);
              expect(game.tryPlaceAtAnchor(x, y), isTrue);
              if (container.read(pentoscopeProvider).faultCount == 1) {
                found = true;
                break search;
              }
            }
          }
        }
      }
      expect(found, isTrue);
      final bad = container.read(pentoscopeProvider);
      expect(bad.geometry!.penalties, greaterThan(0));
      // Un appui rouge ne compte pas comme triche et une correction ne rend aucun point.
      game.applyHint();
      expect(container.read(pentoscopeProvider).hintCount, 0);
      game.removePlacedPiece(bad.placedPieces.single);
      expect(
        container.read(pentoscopeProvider).geometry!.penalties,
        bad.geometry!.penalties,
      );
      game.applyHint();
      expect(container.read(pentoscopeProvider).hintCount, 1);
      await game.saveCurrentGameSnapshot();
      final saved = (await db.loadCurrentGame())!;
      expect((await db.select(db.currentGame).get()).map((r) => r.id), [0]);
      expect(jsonDecode(saved.geometryState)['rules'], first.toJson());
      final before = container.read(pentoscopeProvider);
      final resumed = _Game();
      final other = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          pentoscopeProvider.overrideWith(() => resumed),
        ],
      );
      other.read(pentoscopeProvider);
      await resumed.restoreGame(saved);
      final restored = other.read(pentoscopeProvider);
      expect(restored.geometry!.toJson(), before.geometry!.toJson());
      expect(restored.hintCount, 1);
      expect(restored.faultCount, 1);
      expect(restored.placedPieces.length, before.placedPieces.length);
      other.dispose();
      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);
      expect(
        container.read(pentoscopeProvider).geometry!.rules.toJson(),
        next.toJson(),
      );
      expect(container.read(pentoscopeProvider).geometry!.value, 100);
      // Fin expérimentale : aucun record n'est écrit, même après toutes les aides.
      while (!container.read(pentoscopeProvider).isComplete) {
        game.applyHint();
      }
      await db.customSelect('SELECT 1').get();
      expect(await db.select(db.puzzleStats).get(), isEmpty);
      expect(await db.select(db.solvedSolutions).get(), isEmpty);
      expect(game.computeCompletionMetrics()!.geometry!.value, 100);
      expect(container.read(pentoscopeProvider).hintCount, 3);
    },
  );

  test(
    'puzzle récréatif prépare un vrai Game 5x7 avec une pièce manquante',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      container.read(pentoscopeProvider);
      await container.read(settingsProvider.notifier).ensureLoaded();
      await game.startRecreationalPuzzle();

      final state = container.read(pentoscopeProvider);
      expect(state.puzzle!.size, PentoscopeSize.size7x5);
      expect(state.plateau.width, 5);
      expect(state.plateau.height, 7);
      expect(state.isComplete, isFalse);
      expect(state.placedPieces.length, 6);
      expect(state.availablePieces.length, 1);
      final missing = state.availablePieces.single;
      expect(missing.numOrientations, greaterThan(1));
      expect(
        state.initialOrientations[missing.id],
        state.getPiecePositionIndex(missing.id),
      );
      expect(state.hasPossibleSolution, isTrue);
      expect(state.solutionsCount, 1);
      expect(state.hintCount, 0);
      expect(state.deleteCount, 0);
      expect(state.isProgression, isFalse);
      expect(await db.loadCurrentGame(), isNull);
    },
  );

  test(
    'training 2 prépare deux pièces voisines sur un plateau à solution unique',
    () async {
      final db = SettingsDatabase.forTesting(NativeDatabase.memory());
      final game = _Game();
      final container = ProviderContainer(
        overrides: [
          settingsDatabaseProvider.overrideWithValue(db),
          pentoscopeProvider.overrideWith(() => game),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      container.read(pentoscopeProvider);
      await container.read(settingsProvider.notifier).ensureLoaded();
      for (var generation = 0; generation < 10; generation++) {
        await game.startRecreationalPuzzle(missingPieceCount: 2);

        final state = container.read(pentoscopeProvider);
        expect(state.placedPieces.length, 5);
        expect(state.availablePieces.length, 2);
        expect(state.solutionsCount, 1);
        expect(state.hasPossibleSolution, isTrue);
        expect(state.deleteCount, 0);
        for (final piece in state.availablePieces) {
          expect(piece.numOrientations, greaterThan(1));
          expect(
            state.initialOrientations[piece.id],
            state.getPiecePositionIndex(piece.id),
          );
        }

        final empty = <(int, int)>{};
        for (var y = 0; y < state.plateau.height; y++) {
          for (var x = 0; x < state.plateau.width; x++) {
            if (state.plateau.getCell(x, y) == 0) empty.add((x, y));
          }
        }
        expect(empty, hasLength(10));
        final reached = <(int, int)>{empty.first};
        final pending = <(int, int)>[empty.first];
        while (pending.isNotEmpty) {
          final (x, y) = pending.removeLast();
          for (final neighbor in [
            (x - 1, y),
            (x + 1, y),
            (x, y - 1),
            (x, y + 1),
          ]) {
            if (empty.contains(neighbor) && reached.add(neighbor)) {
              pending.add(neighbor);
            }
          }
        }
        expect(reached, hasLength(10));
        expect(await db.loadCurrentGame(), isNull);
      }
    },
  );
}

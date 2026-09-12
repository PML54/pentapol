// Modified: 2026-09-12 10:58 — parcours réel du corpus, barème figé, reprise SQLite, Triche et exclusion des records.
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
}

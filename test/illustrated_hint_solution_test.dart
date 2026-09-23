// Modified: 2026-09-23 07:03 — verrouiller la rotation de l'image en paysage.
// test/illustrated_hint_solution_test.dart

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/widgets/illustrated_piece_cells.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le paysage tourne les fragments dans le même sens que le plateau', () {
    expect(kIllustratedLandscapeQuarterTurns, 3);
  });

  test('la lampe suit la solution-image sur toutes les tailles', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await container
        .read(settingsProvider.notifier)
        .setShowIllustratedPieces(true);
    final game = container.read(pentoscopeProvider.notifier);
    for (final size in PentoscopeSize.values) {
      await game.startPuzzle(size);

      final started = container.read(pentoscopeProvider);
      final target = started.illustratedSolution;
      expect(started.isIllustratedMode, isTrue, reason: size.name);
      expect(target, isNotNull, reason: size.name);
      expect(target, hasLength(size.numPieces), reason: size.name);

      for (var i = 0; i < size.numPieces; i++) {
        game.applyHint();
      }

      final completed = container.read(pentoscopeProvider);
      expect(completed.isComplete, isTrue, reason: size.name);
      expect(completed.placedPieces, hasLength(size.numPieces));

      final targetById = {for (final piece in target!) piece.piece.id: piece};
      for (final placed in completed.placedPieces) {
        expect(
          placed.absoluteCells.toSet(),
          targetById[placed.piece.id]!.absoluteCells.toSet(),
          reason: size.name,
        );
      }
    }

    // L'enregistrement de fin de partie est lancé en arrière-plan par le provider.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  test('la lampe refuse un placement géométrique hors image', () async {
    final db = SettingsDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [settingsDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await container
        .read(settingsProvider.notifier)
        .setShowIllustratedPieces(true);
    final game = container.read(pentoscopeProvider.notifier);
    await game.startPuzzle(PentoscopeSize.size3x5);
    await container
        .read(settingsProvider.notifier)
        .setShowIllustratedPieces(false);

    final started = container.read(pentoscopeProvider);
    expect(started.isIllustratedMode, isTrue);
    final target = started.illustratedSolution!;
    var placedWrongly = false;
    for (final piece in started.availablePieces) {
      if (placedWrongly) break;
      game.selectPiece(piece);
      final position = container.read(pentoscopeProvider).selectedPositionIndex;
      final targetCells = target
          .firstWhere((placed) => placed.piece.id == piece.id)
          .absoluteCells
          .toSet();
      for (var y = 0; y < started.plateau.height && !placedWrongly; y++) {
        for (var x = 0; x < started.plateau.width && !placedWrongly; x++) {
          if (!container
              .read(pentoscopeProvider)
              .canPlacePiece(piece, position, x, y)) {
            continue;
          }
          final candidate = PlacedPiece(
            piece: piece,
            positionIndex: position,
            gridX: x,
            gridY: y,
          ).absoluteCells.toSet();
          if (candidate.length == targetCells.length &&
              candidate.containsAll(targetCells)) {
            continue;
          }
          placedWrongly = game.tryPlaceAtAnchor(x, y);
        }
      }
    }

    expect(placedWrongly, isTrue);
    final wrongState = container.read(pentoscopeProvider);
    expect(wrongState.hasPossibleSolution, isFalse);
    expect(wrongState.isComplete, isFalse);
    final hintsBefore = wrongState.hintCount;
    game.applyHint();
    expect(container.read(pentoscopeProvider).hintCount, hintsBefore);
  });
}

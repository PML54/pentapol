// Modified: 2026-09-30 07:10 — vérifier qu'un premier placement abandonné alimente le bilan.
// test/player_attempt_history_test.dart

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'remplacer une partie commencée conserve une tentative abandonnée',
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
      await container.read(settingsProvider.notifier).ensureLoaded();
      await game.drawMask(PentoscopeSize.size3x5);
      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);
      final initial = container.read(pentoscopeProvider);
      final piece = initial.availablePieces.first;
      final orientation = initial.getPiecePositionIndex(piece.id);

      var placed = false;
      for (var y = 0; y < initial.plateau.height && !placed; y++) {
        for (var x = 0; x < initial.plateau.width && !placed; x++) {
          if (!initial.canPlacePiece(piece, orientation, x, y)) continue;
          game.selectPiece(piece);
          placed = game.tryPlaceAtAnchor(x, y);
        }
      }
      expect(placed, isTrue);
      final afterPlacement = container.read(pentoscopeProvider);
      expect(afterPlacement.firstPlacedPieceId, piece.id);
      expect(afterPlacement.firstPlacementSolvable, isNotNull);

      await game.startPuzzle(PentoscopeSize.size3x5, mask: 74);

      final history = container.read(settingsProvider).attemptHistory;
      expect(history, hasLength(1));
      expect(history.single.completed, isFalse);
      expect(history.single.firstPieceId, piece.id);
      expect(
        history.single.firstPlacementSolvable,
        afterPlacement.firstPlacementSolvable,
      );
    },
  );
}

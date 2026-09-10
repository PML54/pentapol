// Modified: 2026-09-10 07:19 — vérifier les aperçus sans mutation et leur équivalence avec les actions aux bords.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';

class _Fixture extends PentoscopeNotifier {
  void load(PentoscopeState value) => state = value;
}

void main() {
  test('aperçu identique à l’action : bords, obstacles, axes et recentrage', () {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = originalDebugPrint);
    final fixture = _Fixture();
    final container = ProviderContainer(overrides: [
      pentoscopeProvider.overrideWith(() => fixture),
    ]);
    addTearDown(container.dispose);
    container.read(pentoscopeProvider);
    final actions = [fixture.applyIsometryRotationTW, fixture.applyIsometryRotationCW,
      fixture.applyIsometrySymmetryH, fixture.applyIsometrySymmetryV];
    final results = <TransformationResult>{};
    for (final view in ViewOrientation.values) {
      for (final piece in pentominos) {
        for (var index = 0; index < piece.numOrientations; index++) {
          for (final anchor in [const Point(0, 0), const Point(1, 1), const Point(2, 2)]) {
            final placed = PlacedPiece(piece: piece, positionIndex: index,
                gridX: anchor.x, gridY: anchor.y);
            if (placed.absoluteCells.any((c) => c.x >= 5 || c.y >= 5)) continue;
            for (final blocked in [false, true]) {
              final board = Plateau.allVisible(5, 5);
              for (final c in placed.absoluteCells) { board.setCell(c.x, c.y, piece.id); }
              if (blocked) {
                for (var y = 0; y < 5; y++) {
                  for (var x = 0; x < 5; x++) {
                    if (board.getCell(x, y) == 0) board.setCell(x, y, 99);
                  }
                }
              }
              final master = placed.absoluteCells.first;
              final initial = PentoscopeState.initial().copyWith(
                plateau: board, placedPieces: [placed], selectedPiece: piece,
                selectedPositionIndex: index, selectedPlacedPiece: placed,
                selectedCellInPiece: Point(master.x - anchor.x, master.y - anchor.y),
                viewOrientation: view);
              for (final action in actions) {
                fixture.load(initial);
                final gridBefore = jsonEncode(board.grid);
                final preview = action(preview: true);
                expect(identical(container.read(pentoscopeProvider), initial), isTrue);
                expect(jsonEncode(board.grid), gridBefore);
                final actual = action();
                expect(preview, actual, reason: 'piece ${piece.id}, $index, $view, $anchor, $blocked');
                results.add(actual);
                if (actual == TransformationResult.impossible) {
                  expect(identical(container.read(pentoscopeProvider), initial), isTrue);
                }
              }
            }
          }
          final rack = PentoscopeState.initial().copyWith(selectedPiece: piece,
              selectedPositionIndex: index, viewOrientation: view);
          for (final action in actions) {
            fixture.load(rack);
            expect(action(preview: true), TransformationResult.success);
            expect(identical(container.read(pentoscopeProvider), rack), isTrue);
          }
        }
      }
    }
    expect(results, containsAll(TransformationResult.values));
    fixture.load(PentoscopeState.initial());
    for (final action in actions) {
      expect(action(preview: true), TransformationResult.impossible);
    }
  });
}

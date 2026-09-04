// Modified: 2026-09-04 05:20 — création : test du calcul des trois maillots (CDC §4). Vérifie
//           l'appariement rack↔placement (minIso), la formule des coups, et les cas 0.
// test/completion_metrics_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/pentoscope/completion_metrics.dart';

PlacedPiece _placed(Pento piece, int positionIndex) =>
    PlacedPiece(piece: piece, positionIndex: positionIndex, gridX: 0, gridY: 0);

void main() {
  // Une pièce totalement asymétrique (8 orientations) : une rotation change vraiment l'orientation.
  final asym = pentominos.firstWhere((p) => p.numOrientations == 8);

  group('computeMetrics — coups (maillot à pois, §4.7)', () {
    test('sans retrait : coups = nombre de pièces', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 5,
        timeSeconds: 100,
      );
      expect(m.moves, 5);
      expect(m.minMoves, 5);
      expect(m.efficiency, 1.0);
    });

    test('deleteCount retraits : coups = pièces + 2·retraits', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        deleteCount: 2,
        pieceCount: 5,
        timeSeconds: 0,
      );
      expect(m.moves, 5 + 2 * 2); // 9
      expect(m.efficiency, 5 / 9);
    });
  });

  group('computeMetrics — minIso (maillot jaune, §4.2)', () {
    test('rack == placement → 0 par pièce', () {
      final m = computeMetrics(
        placedPieces: [_placed(asym, 0)],
        initialOrientations: {asym.id: 0},
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.minIso, 0);
    });

    test('une rotation d\'écart → 1 (appariement rack↔placement correct)', () {
      final placedPos = asym.rotationCW(0);
      // sanité : la primitive donne bien 1 pour une rotation sur une pièce asymétrique
      expect(asym.minIsometriesToReach(0, placedPos), 1);

      final m = computeMetrics(
        placedPieces: [_placed(asym, placedPos)],
        initialOrientations: {asym.id: 0}, // rack = orientation 0
        isometryCount: 3,
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.minIso, 1);
      // acuité = (minIso + 1) / (isometryCount + 1) = 2/4
      expect(m.acuity, 2 / 4);
    });

    test('somme sur deux pièces distinctes', () {
      final asym2 =
          pentominos.firstWhere((p) => p.numOrientations == 8 && p.id != asym.id);
      final m = computeMetrics(
        placedPieces: [
          _placed(asym, asym.rotationCW(0)), // distance 1
          _placed(asym2, 0), // rack == placement → distance 0
        ],
        initialOrientations: {asym.id: 0, asym2.id: 0},
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 2,
        timeSeconds: 0,
      );
      expect(m.minIso, 1); // 1 + 0
    });

    test('pièce dont le rack est absent de la map → n\'ajoute rien', () {
      final other = pentominos.firstWhere((p) => p.id != asym.id);
      final m = computeMetrics(
        placedPieces: [_placed(other, 0)],
        initialOrientations: const {}, // aucun rack
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.minIso, 0);
    });
  });

  group('computeMetrics — vision parfaite (médaille §4.6)', () {
    test('acuité 100 % (aucun geste de trop) → perfectVision', () {
      // rack == placement pour toutes les pièces → minIso 0, et 0 isométrie → parfait
      final m = computeMetrics(
        placedPieces: [_placed(asym, 0)],
        initialOrientations: {asym.id: 0},
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.minIso, 0);
      expect(m.perfectVision, isTrue);
    });

    test('un geste de trop → pas de vision parfaite', () {
      final m = computeMetrics(
        placedPieces: [_placed(asym, 0)], // minIso 0
        initialOrientations: {asym.id: 0},
        isometryCount: 1, // mais une isométrie faite
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.perfectVision, isFalse);
    });

    test('minIso élevé mais atteint exactement → vision parfaite', () {
      final placedPos = asym.rotationCW(0); // distance 1
      final m = computeMetrics(
        placedPieces: [_placed(asym, placedPos)],
        initialOrientations: {asym.id: 0},
        isometryCount: 1, // exactement le minimum
        deleteCount: 0,
        pieceCount: 1,
        timeSeconds: 0,
      );
      expect(m.minIso, 1);
      expect(m.perfectVision, isTrue);
    });
  });

  group('computeMetrics — temps (maillot vert)', () {
    test('temps reporté tel quel', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        deleteCount: 0,
        pieceCount: 5,
        timeSeconds: 222,
      );
      expect(m.timeSeconds, 222);
    });
  });
}

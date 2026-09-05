// Modified: 2026-09-05 10:35 — refonte « A » : trois maillots (acuité plafonnée / FAUTES / temps).
//           Coups (moves/deleteCount/pieceCount) et Help supprimés ; ajout du plafond d'acuité et
//           du report des fautes.
// test/completion_metrics_test.dart
// Historique: 2026-09-04 05:20 — création : test du calcul des maillots (minIso, coups, cas 0).

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/pentoscope/completion_metrics.dart';

PlacedPiece _placed(Pento piece, int positionIndex) =>
    PlacedPiece(piece: piece, positionIndex: positionIndex, gridX: 0, gridY: 0);

void main() {
  // Une pièce totalement asymétrique (8 orientations) : une rotation change vraiment l'orientation.
  final asym = pentominos.firstWhere((p) => p.numOrientations == 8);

  group('computeMetrics — minIso (maillot jaune, §4.2)', () {
    test('rack == placement → 0 par pièce', () {
      final m = computeMetrics(
        placedPieces: [_placed(asym, 0)],
        initialOrientations: {asym.id: 0},
        isometryCount: 0,
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
        timeSeconds: 0,
      );
      expect(m.minIso, 0);
    });
  });

  group('computeMetrics — acuité plafonnée à 100 % (§4.2 A)', () {
    test('moins d\'isométries que le minimum théorique → acuité plafonnée à 1.0', () {
      // minIso = 1 (une rotation d'écart) mais 0 isométrie comptée (aide) → ratio 2/1 = 2.0
      final placedPos = asym.rotationCW(0);
      final m = computeMetrics(
        placedPieces: [_placed(asym, placedPos)],
        initialOrientations: {asym.id: 0},
        isometryCount: 0,
        timeSeconds: 0,
      );
      expect(m.minIso, 1);
      expect(m.acuity, 1.0); // plafonné, jamais 2.0
    });
  });

  group('computeMetrics — vision parfaite (médaille §4.6)', () {
    test('acuité 100 % (aucun geste de trop) → perfectVision', () {
      final m = computeMetrics(
        placedPieces: [_placed(asym, 0)],
        initialOrientations: {asym.id: 0},
        isometryCount: 0,
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
        timeSeconds: 0,
      );
      expect(m.minIso, 1);
      expect(m.perfectVision, isTrue);
    });
  });

  group('computeMetrics — fautes (maillot à pois §4.7 A)', () {
    test('fautes reportées telles quelles', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        timeSeconds: 0,
        faults: 3,
      );
      expect(m.faults, 3);
    });

    test('fautes par défaut = 0', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        timeSeconds: 0,
      );
      expect(m.faults, 0);
    });
  });

  group('computeMetrics — temps (maillot vert)', () {
    test('temps reporté tel quel', () {
      final m = computeMetrics(
        placedPieces: const [],
        initialOrientations: const {},
        isometryCount: 0,
        timeSeconds: 222,
      );
      expect(m.timeSeconds, 222);
    });
  });
}

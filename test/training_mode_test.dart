// Modified: 2026-09-08 22:37 — Tests du mode entraînement niveau 1 (PLAN_MODE_ENTRAINEMENT §9) :
//           terminaison du tirage sur les douze pièces (X compris), validation par ensembles de
//           cases sur une pièce symétrique, et cohérence de minIsometriesToReach avec la table §5
//           (342 couples distincts, 210 à un appui, 132 à deux, diamètre 2).
// test/training_mode_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/pentoscope/training/training_mode.dart';

void main() {
  group('Tirage niveau 1 — terminaison et invariants', () {
    test('se termine sur les douze pièces, X compris (aucune boucle infinie)', () {
      // Sans la règle du X (pose seule), la boucle « départ ≠ cible » ne se terminerait jamais.
      for (final piece in pentominos) {
        for (int seed = 0; seed < 200; seed++) {
          final ex = drawLevel1ForPiece(PentapolRng(seed), piece);
          expect(ex.piece.id, piece.id);

          // La cible tient dans le plateau 5×5.
          for (final c in ex.targetCells()) {
            expect(c.x, inInclusiveRange(0, kTrainBoardWidth - 1));
            expect(c.y, inInclusiveRange(0, kTrainBoardHeight - 1));
          }

          if (piece.numOrientations == 1) {
            // X : pose seule.
            expect(ex.poseOnly, isTrue);
            expect(ex.startPositionIndex, ex.targetPositionIndex);
            expect(ex.minPresses, 0);
          } else {
            // Le rack n'est jamais déjà la cible (forme différente), donc au moins un appui.
            expect(ex.poseOnly, isFalse);
            final startShape = cellsFor(piece, ex.startPositionIndex, const Point(0, 0));
            final targetShape = cellsFor(piece, ex.targetPositionIndex, const Point(0, 0));
            expect(sameCells(startShape, targetShape), isFalse,
                reason: 'pièce ${piece.id} : départ = cible (rack déjà résolu)');
            expect(ex.minPresses, greaterThanOrEqualTo(1));
            expect(ex.minPresses, lessThanOrEqualTo(2)); // diamètre 2 (PLAN §5)
          }
        }
      }
    });
  });

  group('Validation par égalité des ensembles de cases (jamais par index)', () {
    test('une pièce symétrique (I) : la cible se valide, une translation ne se valide pas', () {
      final iPiece = pentominos.firstWhere((p) => p.numOrientations == 2); // le I
      final ex = drawLevel1ForPiece(PentapolRng(7), iPiece);

      // Posé exactement sur la cible → résolu.
      expect(ex.isSolvedBy(ex.targetPositionIndex, ex.targetAnchor), isTrue);

      // Même orientation, ancre décalée d'une case si elle tient encore → PAS résolu.
      final box = orientationBox(iPiece, ex.targetPositionIndex);
      if (ex.targetAnchor.x + box.x < kTrainBoardWidth) {
        final shifted = Point(ex.targetAnchor.x + 1, ex.targetAnchor.y);
        expect(ex.isSolvedBy(ex.targetPositionIndex, shifted), isFalse);
      } else if (ex.targetAnchor.y + box.y < kTrainBoardHeight) {
        final shifted = Point(ex.targetAnchor.x, ex.targetAnchor.y + 1);
        expect(ex.isSolvedBy(ex.targetPositionIndex, shifted), isFalse);
      }
    });

    test('la bonne orientation à la bonne ancre est la seule à valider, sur toutes les pièces', () {
      for (final piece in pentominos) {
        final ex = drawLevel1ForPiece(PentapolRng(123), piece);
        expect(ex.isSolvedBy(ex.targetPositionIndex, ex.targetAnchor), isTrue);
      }
    });
  });

  group('Catalogue §5 — cohérence de minIsometriesToReach', () {
    test('342 couples distincts, 210 à un appui, 132 à deux, aucun au-delà de 2', () {
      int total = 0;
      final buckets = <int, int>{};
      // Détail par catégorie d'orientations, pour recouper les sous-totaux du §5.
      final byOrientCount = <int, Map<int, int>>{}; // numOrient -> {presses: count}

      for (final piece in pentominos) {
        final n = piece.numOrientations;
        for (int start = 0; start < n; start++) {
          for (int target = 0; target < n; target++) {
            if (start == target) continue;
            final d = piece.minIsometriesToReach(start, target);
            total++;
            buckets[d] = (buckets[d] ?? 0) + 1;
            byOrientCount.putIfAbsent(n, () => {});
            byOrientCount[n]![d] = (byOrientCount[n]![d] ?? 0) + 1;
          }
        }
      }

      expect(total, 342, reason: 'nombre de couples orientation départ ≠ cible');
      expect(buckets[1], 210, reason: 'couples à un appui');
      expect(buckets[2], 132, reason: 'couples à deux appuis');
      expect(buckets[0] ?? 0, 0, reason: 'aucun couple à zéro appui (formes distinctes)');
      // Diamètre 2 : rien au-delà de deux appuis (aucun repli minIsometriesToReach non trouvé).
      for (final entry in buckets.entries) {
        expect(entry.key, lessThanOrEqualTo(2),
            reason: '${entry.value} couple(s) à ${entry.key} appuis');
      }

      // Sous-totaux : les cinq pièces à 8 orientations font 280 couples (160@1, 120@2).
      expect(byOrientCount[8]![1], 160);
      expect(byOrientCount[8]![2], 120);
    });
  });
}

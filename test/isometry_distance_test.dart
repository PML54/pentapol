// Modified: 2026-09-11 15:10 — conserver le contrôle combinatoire des distances utilisées par les scores.
// test/isometry_distance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';

void main() {
  group('Distances entre orientations — cohérence de minIsometriesToReach', () {
    test('342 couples distincts, 210 à un appui, 132 à deux, aucun au-delà de 2', () {
      int total = 0;
      final buckets = <int, int>{};
      // Détail par catégorie d'orientations, pour recouper les sous-totaux du §5.
      final byOrientCount =
          <int, Map<int, int>>{}; // numOrient -> {presses: count}

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

      expect(
        total,
        342,
        reason: 'nombre de couples orientation départ ≠ cible',
      );
      expect(buckets[1], 210, reason: 'couples à un appui');
      expect(buckets[2], 132, reason: 'couples à deux appuis');
      expect(
        buckets[0] ?? 0,
        0,
        reason: 'aucun couple à zéro appui (formes distinctes)',
      );
      // Diamètre 2 : rien au-delà de deux appuis (aucun repli minIsometriesToReach non trouvé).
      for (final entry in buckets.entries) {
        expect(
          entry.key,
          lessThanOrEqualTo(2),
          reason: '${entry.value} couple(s) à ${entry.key} appuis',
        );
      }

      // Sous-totaux : les cinq pièces à 8 orientations font 280 couples (160@1, 120@2).
      expect(byOrientCount[8]![1], 160);
      expect(byOrientCount[8]![2], 120);
    });
  });
}

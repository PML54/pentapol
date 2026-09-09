// Modified: 2026-09-09 05:29 — Tests des règles de score centralisées (score_rules.dart) : plafond de
//           l'acuité, équivalence du pourcentage avec l'ancienne formule sur parties propres, produit
//           croisé « meilleure acuité » (mêmes résultats que l'ancien _isBetterAcuity), vision parfaite.
// test/score_rules_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:pentapol/pentoscope/score_rules.dart';

// Anciennes formules, recopiées ici pour PROUVER l'équivalence (mêmes résultats qu'avant).
int _oldRecordsPercentUncapped(int mi, int iso) => ((mi + 1) / (iso + 1) * 100).round();
int _oldApiPercentCapped(int mi, int iso) {
  final r = (mi + 1) / (iso + 1);
  return ((r > 1.0 ? 1.0 : r) * 100).round();
}
bool _oldIsBetterAcuity(int? bestMinIso, int? bestIso, int newMinIso, int newIso) {
  if (bestMinIso == null || bestIso == null) return true;
  return (newMinIso + 1) * (bestIso + 1) > (bestMinIso + 1) * (newIso + 1);
}

void main() {
  group('acuityRatio — plafond à 1.0', () {
    test('ratio nominal (iso ≥ minIso)', () {
      expect(acuityRatio(0, 0), 1.0);
      expect(acuityRatio(3, 3), 1.0);
      expect(acuityRatio(1, 3), (2) / (4)); // 0.5
    });
    test('plafonné quand minIso > isoCount (cas indice)', () {
      expect(acuityRatio(5, 0), 1.0); // (6)/(1)=6 → plafonné à 1
      expect(acuityRatio(2, 1), 1.0); // (3)/(2)=1.5 → 1
    });
  });

  group('acuityPercent — plafonné, et équivalent à l\'existant', () {
    test('égal à l\'ancien % de challenge_api (déjà plafonné) partout', () {
      for (int mi = 0; mi <= 12; mi++) {
        for (int iso = 0; iso <= 12; iso++) {
          expect(acuityPercent(mi, iso), _oldApiPercentCapped(mi, iso),
              reason: 'mi=$mi iso=$iso');
        }
      }
    });
    test('égal à l\'ancien % de records_screen (non plafonné) sur parties PROPRES (iso ≥ minIso)', () {
      // Les records ne stockent que des parties propres : iso ≥ minIso → ratio ≤ 1 → identique.
      for (int mi = 0; mi <= 12; mi++) {
        for (int iso = mi; iso <= 12; iso++) {
          expect(acuityPercent(mi, iso), _oldRecordsPercentUncapped(mi, iso),
              reason: 'mi=$mi iso=$iso');
        }
      }
    });
    test('borné à 100', () {
      expect(acuityPercent(5, 0), 100);
      expect(acuityPercent(0, 0), 100);
    });
  });

  group('isBetterAcuity — mêmes résultats que l\'ancien _isBetterAcuity', () {
    test('null best → toujours vrai', () {
      expect(isBetterAcuity(null, null, 3, 4), isTrue);
      expect(isBetterAcuity(null, 2, 3, 4), isTrue);
      expect(isBetterAcuity(2, null, 3, 4), isTrue);
    });
    test('équivalence exhaustive sur une grille de valeurs', () {
      for (int bm = 0; bm <= 8; bm++) {
        for (int bi = 0; bi <= 8; bi++) {
          for (int nm = 0; nm <= 8; nm++) {
            for (int ni = 0; ni <= 8; ni++) {
              expect(isBetterAcuity(bm, bi, nm, ni),
                  _oldIsBetterAcuity(bm, bi, nm, ni),
                  reason: 'best=($bm,$bi) new=($nm,$ni)');
            }
          }
        }
      }
    });
  });

  group('isPerfectVision', () {
    test('vrai ssi aucun geste de trop', () {
      expect(isPerfectVision(3, 3), isTrue);
      expect(isPerfectVision(0, 0), isTrue);
      expect(isPerfectVision(3, 4), isFalse);
      expect(isPerfectVision(2, 5), isFalse);
    });
  });
}

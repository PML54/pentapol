// Modified: 2026-10-02 07:03 — vérifier l'arrondi supérieur et les bornes du taux de Triche.
// Historique: 2026-09-30 07:27 — vérifier la troncature des pourcentages d'acuité.
// Historique: 2026-09-09 05:29 — Tests des règles de score centralisées (score_rules.dart) : plafond de
//           l'acuité, équivalence du pourcentage avec l'ancienne formule sur parties propres, produit
//           croisé « meilleure acuité » (mêmes résultats que l'ancien _isBetterAcuity), vision parfaite.
// test/score_rules_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:pentapol/pentoscope/score_rules.dart';

bool _oldIsBetterAcuity(
  int? bestMinIso,
  int? bestIso,
  int newMinIso,
  int newIso,
) {
  if (bestMinIso == null || bestIso == null) return true;
  return (newMinIso + 1) * (bestIso + 1) > (bestMinIso + 1) * (newIso + 1);
}

void main() {
  test('Triche : pourcentage entier arrondi au supérieur, de 0 à 100', () {
    expect(cheatingPercent(0, 3), 0);
    expect(cheatingPercent(1, 3), 34);
    expect(cheatingPercent(2, 3), 67);
    expect(cheatingPercent(1, 4), 25);
    expect(cheatingPercent(3, 3), 100);
    expect(cheatingPercent(4, 3), 100);
    expect(cheatingPercent(0, 0), 0);
  });
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

  group('acuityPercent — plafonné et tronqué', () {
    test('99,5 % reste affiché à 99 %', () {
      expect(acuityPercent(198, 199), 99);
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
              expect(
                isBetterAcuity(bm, bi, nm, ni),
                _oldIsBetterAcuity(bm, bi, nm, ni),
                reason: 'best=($bm,$bi) new=($nm,$ni)',
              );
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

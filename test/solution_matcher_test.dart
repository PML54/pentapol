// Modified: 2026-08-29 13:43 — création : test unitaire du SolutionMatcher paramétré,
//           remplaçant du « canari » du §4.3 (le compteur du mode classique), qui disparaît
//           avec le module. Voir PLAN_SUPPRESSION_CLASSICAL.md §5 étape 2, décision 24.
// test/solution_matcher_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/services/solution_matcher.dart';

void main() {
  // Charge les 2339 solutions canoniques directement depuis le .bin (dart:io :
  // pas de rootBundle en test), même décodage que pentapol_solutions_loader.dart.
  late final List<BigInt> canonical =
      _loadCanonical('assets/data/solutions_6x10_normalisees.bin');

  late final SolutionMatcher matcher = SolutionMatcher() // 6×10 par défaut
    ..initWithBigIntSolutions(canonical);

  test('2339 canoniques → 9356 solutions après expansion ×4', () {
    expect(canonical.length, 2339);
    expect(matcher.totalSolutions, 9356);
  });

  test('plateau vide (masque 0) → toutes les 9356 sont compatibles', () {
    expect(matcher.countCompatibleFromBigInts(BigInt.zero, BigInt.zero), 9356);
  });

  test('plateau complet = une solution connue → exactement 1, et son index', () {
    final sol = matcher.getSolutionByIndex(0)!;
    final fullMask = (BigInt.one << 360) - BigInt.one;
    expect(matcher.countCompatibleFromBigInts(sol, fullMask), 1);
    expect(matcher.findSolutionIndex(sol), 0);
  });

  test('plateau partiel → compte stable entre deux appels, dans [1, 9356[', () {
    final sol = matcher.getSolutionByIndex(0)!;
    // Fixer les 12 dernières cases (2 lignes) aux valeurs de la solution 0.
    final mask = (BigInt.one << (6 * 12)) - BigInt.one;
    final pieces = sol & mask;
    final a = matcher.countCompatibleFromBigInts(pieces, mask);
    final b = matcher.countCompatibleFromBigInts(pieces, mask);
    expect(a, b, reason: 'le comptage doit être déterministe');
    expect(a, greaterThanOrEqualTo(1)); // la solution 0 elle-même
    expect(a, lessThan(9356)); // 12 cases fixées éliminent des solutions
  });

  test('paramétrisation additive : SolutionMatcher(width:6, height:10) == défaut', () {
    final explicit = SolutionMatcher(width: 6, height: 10)
      ..initWithBigIntSolutions(canonical);
    expect(explicit.totalSolutions, matcher.totalSolutions);
    expect(
      explicit.countCompatibleFromBigInts(BigInt.zero, BigInt.zero),
      matcher.countCompatibleFromBigInts(BigInt.zero, BigInt.zero),
    );
  });
}

/// Décode le fichier de solutions normalisées (60 cases × 6 bits = 45 octets par
/// solution, bits de poids fort en premier) en BigInt — identique au chargeur.
List<BigInt> _loadCanonical(String path) {
  final bytes = File(path).readAsBytesSync();
  const bytesPerSolution = 45;
  const cells = 60;
  final out = <BigInt>[];

  for (int off = 0; off < bytes.length; off += bytesPerSolution) {
    int byteIndex = off;
    int currentByte = 0;
    int bitsLeft = 0;
    BigInt acc = BigInt.zero;

    for (int cell = 0; cell < cells; cell++) {
      int code = 0;
      for (int i = 0; i < 6; i++) {
        if (bitsLeft == 0) {
          currentByte = bytes[byteIndex++];
          bitsLeft = 8;
        }
        final bit = (currentByte >> (bitsLeft - 1)) & 1;
        bitsLeft--;
        code = (code << 1) | bit;
      }
      acc = (acc << 6) | BigInt.from(code);
    }
    out.add(acc);
  }
  return out;
}

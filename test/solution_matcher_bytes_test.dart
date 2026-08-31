// Modified: 2026-08-31 16:39 — REFERENCE_TIRAGES §9 : garde d'équivalence du nouvel appariement
//           Uint8List. countCompatibleBytes doit rendre EXACTEMENT le même compte que
//           countCompatibleFromBigInts sur des plateaux tirés au hasard.
// test/solution_matcher_bytes_test.dart

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/services/solution_matcher.dart';

const int _cells = 60; // 6×10
const int _bit6Mask = 0x3F;

/// Encode 60 codes (0..63), board[0] en poids fort, comme le fait le matcher.
BigInt _encode(List<int> board) {
  var acc = BigInt.zero;
  for (final code in board) {
    acc = (acc << 6) | BigInt.from(code);
  }
  return acc;
}

void main() {
  test('countCompatibleBytes == countCompatibleFromBigInts (10 000 plateaux)', () {
    final rnd = Random(12345); // graine fixe : test reproductible

    // 200 « solutions » canoniques synthétiques : 60 cases, codes 1..63 (jamais 0,
    // comme un plateau plein). Le matcher les étend ×4 (identité/rot180/miroirs).
    final canon = <BigInt>[
      for (int s = 0; s < 200; s++)
        _encode(List<int>.generate(_cells, (_) => 1 + rnd.nextInt(63))),
    ];

    final matcher = SolutionMatcher(); // 6×10 par défaut
    matcher.initWithBigIntSolutions(canon);

    for (int t = 0; t < 10000; t++) {
      // Un plateau partiel : chaque case a une proba d'être occupée ; si occupée,
      // on lui donne le plus souvent le code d'une vraie solution (pour produire des
      // compatibilités non triviales), parfois un code au hasard.
      final ref = matcher.getSolutionByIndex(rnd.nextInt(matcher.totalSolutions))!;
      final refBoard = List<int>.filled(_cells, 0);
      var v = ref;
      for (int i = _cells - 1; i >= 0; i--) {
        refBoard[i] = (v & BigInt.from(_bit6Mask)).toInt();
        v = v >> 6;
      }

      final bytes = List<int>.filled(_cells, 0);
      for (int c = 0; c < _cells; c++) {
        if (rnd.nextDouble() < 0.35) {
          bytes[c] = rnd.nextDouble() < 0.85 ? refBoard[c] : 1 + rnd.nextInt(63);
        }
      }

      // Masques BigInt correspondants (occupée ⟺ octet ≠ 0).
      var pieces = BigInt.zero;
      var mask = BigInt.zero;
      for (int c = 0; c < _cells; c++) {
        pieces <<= 6;
        mask <<= 6;
        if (bytes[c] != 0) {
          pieces |= BigInt.from(bytes[c]);
          mask |= BigInt.from(_bit6Mask);
        }
      }

      final byBytes = matcher.countCompatibleBytes(Uint8List.fromList(bytes));
      final byBigInt = matcher.countCompatibleFromBigInts(pieces, mask);
      expect(byBytes, byBigInt, reason: 'divergence au plateau #$t');
    }
  });
}

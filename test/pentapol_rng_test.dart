// Modified: 2026-09-04 04:34 — création : test de gel du PRNG du dépôt. Seul garde-fou contre
//           une modification involontaire de la dérivation des puzzles seedés (CDC §7.3, piège 5).
// test/pentapol_rng_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentapol_rng.dart';

void main() {
  group('PentapolRng — séquences figées (ne jamais modifier sans intention)', () {
    // Si l'un de ces goldens change, TOUS les puzzles seedés changent (duel, défi hebdo).
    // Un échec ici est un signal, pas un test à « réparer » en recopiant la nouvelle valeur.
    test('seed 42', () {
      final r = PentapolRng(42);
      final seq = [for (var i = 0; i < 8; i++) r.nextInt(1 << 30)];
      expect(seq, [
        11355432, 688534700, 476557059, 426820544,
        538758084, 367696310, 492241368, 284160686,
      ]);
    });

    test('seed 12345', () {
      final r = PentapolRng(12345);
      final seq = [for (var i = 0; i < 8; i++) r.nextInt(1 << 30)];
      expect(seq, [
        115700858, 623511983, 669028256, 881738218,
        718842323, 62394978, 1064460696, 459685688,
      ]);
    });

    test('nextInt(8) — bornes usuelles (orientations)', () {
      final r = PentapolRng(12345);
      final seq = [for (var i = 0; i < 12; i++) r.nextInt(8)];
      expect(seq, [2, 7, 0, 2, 3, 2, 0, 0, 0, 4, 6, 7]);
      expect(seq.every((v) => v >= 0 && v < 8), isTrue);
    });
  });

  group('PentapolRng — propriétés', () {
    test('même seed ⟹ même séquence', () {
      final a = PentapolRng(777);
      final b = PentapolRng(777);
      final sa = [for (var i = 0; i < 50; i++) a.nextInt(1000)];
      final sb = [for (var i = 0; i < 50; i++) b.nextInt(1000)];
      expect(sa, sb);
    });

    test('seed 0 n\'est pas un point fixe (remappé)', () {
      final r = PentapolRng(0);
      final seq = [for (var i = 0; i < 5; i++) r.nextInt(1 << 30)];
      expect(seq.toSet().length, greaterThan(1)); // pas [0,0,0,0,0]
      expect(seq.first, isNot(0));
    });

    test('seed 0 et seed 1 divergent', () {
      final r0 = PentapolRng(0);
      final r1 = PentapolRng(1);
      final a = [for (var i = 0; i < 5; i++) r0.nextInt(1 << 30)];
      final b = [for (var i = 0; i < 5; i++) r1.nextInt(1 << 30)];
      expect(a, isNot(b));
    });

    test('nextInt reste dans [0, max)', () {
      final r = PentapolRng(2026);
      for (final max in [1, 2, 3, 7, 8, 245, 1664]) {
        for (var i = 0; i < 200; i++) {
          final v = r.nextInt(max);
          expect(v, inInclusiveRange(0, max - 1));
        }
      }
    });
  });
}

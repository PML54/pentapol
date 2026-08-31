// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES §8 B) : validation structurelle du
//           corpus des solutions. Chaque solution doit employer EXACTEMENT les pièces de son
//           masque et remplir tout le plateau ; les comptes doivent suivre subset_counts.bin.
// test/solutions_corpus_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// bit6 par id (1..12), ordre pentominos.dart (X..I) — même source que le générateur.
const List<int> _bit6 = [7, 11, 19, 35, 13, 21, 37, 25, 41, 49, 14, 22];

/// bit6 → id (1..12).
final Map<int, int> _idByBit6 = {for (int i = 0; i < 12; i++) _bit6[i]: i + 1};

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

/// Les ids (1..12) d'un masque.
Set<int> _idsOfMask(int m) => {
      for (int id = 1; id <= 12; id++)
        if (m & (1 << (id - 1)) != 0) id,
    };

void main() {
  final counts = ByteData.sublistView(
      File('assets/data/subset_counts.bin').readAsBytesSync());
  final corpus = File('assets/data/solutions_corpus.bin').readAsBytesSync();

  test('taille du corpus = Σ compte(m) × 5·popcount(m) sur popcounts 3..10', () {
    var expected = 0;
    for (int m = 0; m < 4096; m++) {
      final pc = _popcount(m);
      if (pc < 3 || pc > 10) continue;
      expected += counts.getUint16(m * 2, Endian.little) * 5 * pc;
    }
    expect(corpus.length, expected);
  });

  test('chaque solution : plateau plein, pièces = exactement le masque', () {
    var offset = 0;
    var checked = 0;
    for (int m = 0; m < 4096; m++) {
      final pc = _popcount(m);
      if (pc < 3 || pc > 10) continue;
      final count = counts.getUint16(m * 2, Endian.little);
      if (count == 0) continue;

      final cells = 5 * pc;
      final wantedIds = _idsOfMask(m);
      for (int s = 0; s < count; s++) {
        final seenIds = <int>{};
        for (int c = 0; c < cells; c++) {
          final code = corpus[offset + c];
          expect(code, isNot(0), reason: 'case vide dans une solution (masque $m)');
          final id = _idByBit6[code];
          expect(id, isNotNull, reason: 'bit6 inconnu $code (masque $m)');
          seenIds.add(id!);
        }
        // Chaque pièce couvre 5 cases → les 5·pc cases portent exactement pc ids distincts,
        // et ce sont ceux du masque.
        expect(seenIds, wantedIds, reason: 'pièces ≠ masque $m, solution $s');
        offset += cells;
      }
      checked += count;
    }
    expect(offset, corpus.length);
    expect(checked, 73876); // total §2 des popcounts 3..10
  });

  test('spot-check 5×10 (§2) : 65 solubles, min 4, max 4664', () {
    var soluble = 0, min = 1 << 30, max = 0;
    for (int m = 0; m < 4096; m++) {
      if (_popcount(m) != 10) continue;
      final c = counts.getUint16(m * 2, Endian.little);
      if (c == 0) continue;
      soluble++;
      if (c < min) min = c;
      if (c > max) max = c;
    }
    expect(soluble, 65);
    expect(min, 4);
    expect(max, 4664);
  });
}

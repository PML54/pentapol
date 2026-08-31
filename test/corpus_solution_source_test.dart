// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES §8 B) : validation runtime de
//           CorpusSolutionSource. Sur plateau vide, countFrom doit rendre countOf(masque) pour
//           TOUS les masques solubles (garantit les offsets de découpe) ; sur un plateau plein
//           d'une solution, countFrom doit rendre 1.
// test/corpus_solution_source_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';
import 'package:pentapol/pentoscope/solution_source.dart';

/// bit6 par id (1..12), ordre pentominos.dart. bit6 → id pour remplir le plateau.
const List<int> _bit6 = [7, 11, 19, 35, 13, 21, 37, 25, 41, 49, 14, 22];
final Map<int, int> _idByBit6 = {for (int i = 0; i < 12; i++) _bit6[i]: i + 1};

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

/// Dimensions runtime de la taille à n pièces (n<5 → n×5, sinon 5×n).
(int, int) _dims(int n) => n < 5 ? (n, 5) : (5, n);

void main() {
  final blob = File('assets/data/solutions_corpus.bin').readAsBytesSync();
  final counts = ByteData.sublistView(
      File('assets/data/subset_counts.bin').readAsBytesSync());
  final corpus = TirageCorpus(Uint8List.fromList(blob), counts);

  test('plateau vide → countFrom == countOf(masque), tous les masques solubles', () {
    for (int m = 0; m < 4096; m++) {
      final pc = _popcount(m);
      if (pc < 3 || pc > 10) continue;
      final expected = corpus.countOf(m);
      if (expected == 0) continue;
      final (w, h) = _dims(pc);
      final src = CorpusSolutionSource(corpus.solutionsFor(m), width: w, height: h);
      final empty = Plateau.allVisible(w, h);
      expect(src.countFrom(empty), expected, reason: 'masque $m');
    }
  });

  test('plateau plein d\'une solution → countFrom == 1, hasSolutionFrom vrai', () {
    // Un masque 5×10 soluble : le premier de popcount 10.
    int mask = -1;
    for (int m = 0; m < 4096; m++) {
      if (_popcount(m) == 10 && corpus.countOf(m) > 0) {
        mask = m;
        break;
      }
    }
    expect(mask, isNot(-1));

    const w = 5, h = 10, cells = 50;
    final sols = corpus.solutionsFor(mask);
    final src = CorpusSolutionSource(sols, width: w, height: h);

    // Reconstruit le plateau de la première solution du tirage.
    final full = Plateau.allVisible(w, h);
    for (int c = 0; c < cells; c++) {
      full.setCell(c % w, c ~/ w, _idByBit6[sols[c]]!);
    }
    expect(src.countFrom(full), 1);
    expect(src.hasSolutionFrom(full, const []), isTrue);

    // hintFrom sur plateau vide rend une solution complète (12 - 2 = 10 pièces).
    final hint = src.hintFrom(Plateau.allVisible(w, h), const []);
    expect(hint, isNotNull);
    expect(hint!.length, 10);
  });
}

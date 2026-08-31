// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES §8 B) : chargement du corpus complet
//           des solutions (solutions_corpus.bin) et découpe par masque de tirage. Adosse toutes
//           les tailles 5×n à une table, comme le 6×10 — plus de solveur live sur le chemin chaud.
// lib/pentoscope/corpus_provider.dart

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _corpusAsset = 'assets/data/solutions_corpus.bin';
const String _countsAsset = 'assets/data/subset_counts.bin';

/// Corpus des solutions de tous les tirages solubles (tailles 5×n, popcount 3..10), découpable
/// par masque. Les solutions d'un masque sont `count(masque)` plateaux pleins de `5·popcount`
/// octets (un code bit6 par case, orientation runtime) concaténés dans l'ordre croissant des
/// masques. Les offsets sont dérivés de subset_counts.bin (mêmes comptes) au chargement.
class TirageCorpus {
  final Uint8List _blob;
  final List<int> _counts; // subset_counts.bin, 4096 entrées
  final List<int> _offset; // offset octet du début des solutions du masque m

  TirageCorpus._(this._blob, this._counts, this._offset);

  factory TirageCorpus(Uint8List blob, ByteData counts) {
    final c = List<int>.generate(4096, (i) => counts.getUint16(i * 2, Endian.little));
    final offset = List<int>.filled(4096, 0);
    var acc = 0;
    for (int m = 0; m < 4096; m++) {
      offset[m] = acc;
      final pc = _popcount(m);
      if (pc >= 3 && pc <= 10) acc += c[m] * 5 * pc;
    }
    if (acc != blob.length) {
      throw StateError(
          'Corpus incohérent : offsets cumulés $acc ≠ taille ${blob.length}.');
    }
    return TirageCorpus._(blob, c, offset);
  }

  int countOf(int mask) => _counts[mask];

  /// Vue plate (sans copie) des solutions du masque : `count × 5·popcount` octets.
  /// N'a de sens que pour un masque de popcount 3..10 (le 6×10 a sa propre table).
  Uint8List solutionsFor(int mask) {
    final pc = _popcount(mask);
    assert(pc >= 3 && pc <= 10, 'solutionsFor hors petites tailles: popcount $pc');
    final cells = 5 * pc;
    final len = _counts[mask] * cells;
    return Uint8List.sublistView(_blob, _offset[mask], _offset[mask] + len);
  }

  static int _popcount(int x) {
    var c = 0;
    while (x != 0) {
      c += x & 1;
      x >>= 1;
    }
    return c;
  }
}

/// Charge le corpus une seule fois (les deux assets), puis le met en cache Riverpod.
final tirageCorpusProvider = FutureProvider<TirageCorpus>((ref) async {
  final blob = (await rootBundle.load(_corpusAsset)).buffer.asUint8List();
  final counts = await rootBundle.load(_countsAsset);
  return TirageCorpus(blob, counts);
});

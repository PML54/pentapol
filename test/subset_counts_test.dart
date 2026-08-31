// Modified: 2026-08-31 18:00 — création (REFERENCE_TIRAGES.md §8 A) : recharge l'asset
//           subset_counts.bin et vérifie que ses neuf totaux par popcount reproduisent le §2.
// test/subset_counts_test.dart
//
// Remplace le canari : ce test lit l'asset livré (pas la table en mémoire du générateur) et
// contrôle qu'elle porte bien les comptes de référence — le seul test qui a un sens sur une
// donnée pré-calculée embarquée.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Totaux attendus par popcount (REFERENCE_TIRAGES.md §2, plus popcount 12 = 4040 du §3).
const Map<int, int> expectedTotals = {
  3: 28,
  4: 200,
  5: 856,
  6: 2164,
  7: 5584,
  8: 13632,
  9: 23608,
  10: 27804,
  12: 4040,
};

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

void main() {
  test('subset_counts.bin : 8192 octets et neuf totaux du §2 (REFERENCE_TIRAGES)', () {
    final file = File('assets/data/subset_counts.bin');
    expect(file.existsSync(), isTrue,
        reason: 'asset absent — lancer `dart run tools/generate_subset_counts.dart`');

    final bytes = file.readAsBytesSync();
    expect(bytes.length, 8192, reason: '4096 × uint16');

    final bd = ByteData.view(Uint8List.fromList(bytes).buffer);
    final table = List<int>.generate(4096, (i) => bd.getUint16(i * 2, Endian.little));

    for (final entry in expectedTotals.entries) {
      final n = entry.key;
      var total = 0;
      for (int m = 0; m < 4096; m++) {
        if (_popcount(m) == n) total += table[m];
      }
      expect(total, entry.value, reason: 'total des tirages à $n pièces');
    }
  });
}

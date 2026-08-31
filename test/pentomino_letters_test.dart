// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES §10) : garde de la nomenclature des
//           pièces. Reconstruit la lettre de chaque pièce depuis sa géométrie (cartesianCoords),
//           indépendamment de pentominoLetters, et échoue si elles divergent. C'est CE test — et
//           pas un contrôle du nombre d'orientations — qui aurait attrapé l'interversion Z/W
//           (id 10/11) : Z et W ont 4 orientations chacun.
// test/pentomino_letters_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/pentominos.dart';

/// Les 12 pentominos standard, une orientation quelconque chacun (la clé canonique est invariante
/// par rotation et réflexion). Source indépendante de `pentominoLetters` : c'est l'oracle.
const Map<String, List<List<int>>> _canonicalShapes = {
  'X': [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]],
  'I': [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
  'L': [[0, 0], [0, 1], [0, 2], [0, 3], [1, 3]],
  'N': [[1, 0], [1, 1], [0, 2], [1, 2], [0, 3]],
  'P': [[0, 0], [1, 0], [0, 1], [1, 1], [0, 2]],
  'T': [[0, 0], [1, 0], [2, 0], [1, 1], [1, 2]],
  'U': [[0, 0], [2, 0], [0, 1], [1, 1], [2, 1]],
  'V': [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]],
  'W': [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2]],
  'Y': [[1, 0], [0, 1], [1, 1], [1, 2], [1, 3]],
  'Z': [[0, 0], [1, 0], [1, 1], [1, 2], [2, 2]],
  'F': [[1, 0], [2, 0], [0, 1], [1, 1], [1, 2]],
};

/// Clé canonique d'une forme : la plus petite (lexicographiquement) de ses 8 orientations
/// (4 rotations × 2 réflexions), chacune normalisée coin haut-gauche en (0,0) et triée.
String _canonicalKey(List<List<int>> cells) {
  String best = '';
  for (int refl = 0; refl < 2; refl++) {
    var cur = refl == 0
        ? cells.map((c) => [c[0], c[1]]).toList()
        : cells.map((c) => [-c[0], c[1]]).toList();
    for (int rot = 0; rot < 4; rot++) {
      final key = _normalizeKey(cur);
      if (best == '' || key.compareTo(best) < 0) best = key;
      cur = cur.map((c) => [-c[1], c[0]]).toList(); // rotation 90°
    }
  }
  return best;
}

String _normalizeKey(List<List<int>> cells) {
  var minX = 1 << 30, minY = 1 << 30;
  for (final c in cells) {
    if (c[0] < minX) minX = c[0];
    if (c[1] < minY) minY = c[1];
  }
  final norm = cells.map((c) => [c[0] - minX, c[1] - minY]).toList()
    ..sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
  return norm.map((c) => '${c[0]},${c[1]}').join(';');
}

void main() {
  // Oracle : clé canonique → lettre. Doit couvrir 12 formes distinctes.
  final letterByKey = <String, String>{};
  _canonicalShapes.forEach((letter, cells) {
    letterByKey[_canonicalKey(cells)] = letter;
  });

  test('les 12 formes de référence sont distinctes', () {
    expect(letterByKey.length, 12);
    expect(letterByKey.values.toSet(), _canonicalShapes.keys.toSet());
  });

  test('pentominoLetters == lettre reconstruite depuis cartesianCoords', () {
    expect(pentominoLetters.length, 12);
    for (final p in pentominos) {
      final key = _canonicalKey(p.cartesianCoords[0]);
      final reconstructed = letterByKey[key];
      expect(reconstructed, isNotNull,
          reason: 'pièce ${p.id} : forme ne correspond à aucun pentomino standard');
      expect(pentominoLetters[p.id - 1], reconstructed,
          reason: 'pièce ${p.id} : table dit ${pentominoLetters[p.id - 1]}, '
              'géométrie dit $reconstructed');
    }
  });

  test('la table §10 est respectée (Z=10, W=11)', () {
    expect(pentominoLetters, ['X', 'P', 'T', 'F', 'Y', 'V', 'U', 'L', 'N', 'Z', 'W', 'I']);
  });
}

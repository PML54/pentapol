// Modified: 2026-08-31 18:00 — création (REFERENCE_TIRAGES.md §8 A) : table des comptes de
//           solutions par sous-ensemble de pièces, pour toutes les tailles 5×n.
// tools/generate_subset_counts.dart
//
// Un parcours PAR PLATEAU (n ∈ 3..10 plus 12 = 9 parcours), jamais un par tirage. Chaque parcours
// énumère tous les pavages d'un plateau 5×n avec des pièces distinctes prises parmi les 12, et
// incrémente table[masque des pièces utilisées] à chaque plateau plein.
//
// Sortie : assets/data/subset_counts.bin — 4096 × uint16 petit-boutiste = 8192 octets.
//   index = masque 12 bits, bit (id − 1) dans l'ordre de pentominos.dart (X=1 … I=12).
//   table[masque] = nombre de solutions ; 0 ⟺ tirage insoluble ; plateau = 5 × popcount(masque).
//
// Le programme échoue (exit 1) si un total par popcount ne reproduit pas REFERENCE_TIRAGES.md §2
// (dont popcount 12 = 4040, contrôle 5×12). Il chronomètre chaque plateau séparément — mesure n°1.
//
// Volontairement **sans dépendance Flutter** (pas d'import de pentominos.dart, qui tire
// `package:flutter/foundation.dart` → `dart:ui` et empêcherait `dart run`). La géométrie est
// reconstruite ici depuis les `baseShape` de pentominos.dart (mêmes 12 pièces, même ordre), et
// toutes les orientations sont générées par le groupe diédral D4 (réflexions autorisées). Deux
// filets : les orientations doivent totaliser 63 (§3.1), et les totaux doivent reproduire le §2 —
// une forme mal recopiée les ferait échouer.
//
// Énumération : on choisit la première case libre, puis on branche sur TOUS les placements qui la
// couvrent — toute pièce non utilisée, toute orientation, toute cellule de la pièce. Prendre le
// premier placement (comme _findPlacementCoveringCell du runtime) sous-compterait. Élagage : toute
// zone vide connexe doit avoir une taille multiple de 5.

import 'dart:io';
import 'dart:typed_data';

/// `baseShape` des 12 pièces, recopiées de `lib/common/pentominos.dart` dans l'ordre id 1..12
/// (X, P, T, F, Y, V, U, L, N, W, Z, I). Numéros de case sur une grille 5×5 (n → x=(n−1)%5,
/// y=(n−1)~/5).
const List<List<int>> _baseShapes = [
  [2, 6, 7, 8, 12], //  1 X
  [1, 2, 6, 7, 12], //  2 P
  [3, 6, 7, 8, 13], //  3 T
  [2, 3, 6, 7, 12], //  4 F
  [2, 7, 11, 12, 17], // 5 Y
  [3, 8, 11, 12, 13], // 6 V
  [1, 3, 6, 7, 8], //  7 U
  [4, 6, 7, 8, 9], //  8 L
  [3, 4, 6, 7, 8], //  9 N
  [3, 6, 7, 8, 11], // 10 W
  [3, 7, 8, 11, 12], // 11 Z
  [1, 6, 11, 16, 21], // 12 I
];

const List<int> _plateaus = [3, 4, 5, 6, 7, 8, 9, 10, 12];

/// Totaux attendus par popcount (REFERENCE_TIRAGES.md §2, plus popcount 12 = 4040 du §3).
const Map<int, int> _expectedTotals = {
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

/// [pièce 0..11][orientation][cellule][x, y]. Rempli par main() via le groupe diédral.
late final List<List<List<List<int>>>> _pieceOrientations;

void main() {
  _pieceOrientations = List.generate(12, (i) => _orientationsOf(_baseShapes[i]));

  final totalOrientations =
      _pieceOrientations.fold<int>(0, (s, o) => s + o.length);
  if (totalOrientations != 63) {
    stderr.writeln('❌ Orientations = $totalOrientations, attendu 63 (§3.1).');
    exit(1);
  }

  final table = List<int>.filled(4096, 0);

  stdout.writeln('═════════════════════════════════════════════════');
  stdout.writeln('GÉNÉRATION subset_counts.bin — comptes par sous-ensemble');
  stdout.writeln('═════════════════════════════════════════════════');
  stdout.writeln('Orientations totales : $totalOrientations ✓ (§3.1)\n');

  var ok = true;
  final totalSw = Stopwatch()..start();

  for (final n in _plateaus) {
    const width = 5;
    final height = n; // 5×n (la transposition ne change pas le compte)
    final plateau = List<List<int>>.generate(
      height,
      (_) => List<int>.filled(width, 0),
    );

    final sw = Stopwatch()..start();
    _count(plateau, width, height, 0, table);
    sw.stop();

    var total = 0;
    var min = 1 << 30;
    var max = 0;
    var soluble = 0;
    for (int m = 0; m < 4096; m++) {
      if (_popcount(m) != n) continue;
      final c = table[m];
      if (c == 0) continue;
      total += c;
      soluble++;
      if (c < min) min = c;
      if (c > max) max = c;
    }
    if (soluble == 0) min = 0;

    final expected = _expectedTotals[n];
    final mark = total == expected ? '✓' : '✗ ATTENDU $expected';
    stdout.writeln('n=$n  5×$n  total=$total  solubles=$soluble  '
        'min=$min max=$max  (${sw.elapsedMilliseconds} ms)  $mark');
    if (total != expected) ok = false;
  }

  totalSw.stop();
  stdout.writeln('\nTemps total des 9 parcours : ${totalSw.elapsedMilliseconds} ms');

  if (!ok) {
    stderr.writeln('\n❌ Un total ne reproduit pas REFERENCE_TIRAGES.md §2 — asset NON écrit.');
    exit(1);
  }

  final bytes = Uint8List(4096 * 2);
  final bd = ByteData.view(bytes.buffer);
  for (int i = 0; i < 4096; i++) {
    final c = table[i];
    if (c > 0xFFFF) {
      stderr.writeln('❌ Compte $c > 65535 à l\'index $i : uint16 insuffisant.');
      exit(1);
    }
    bd.setUint16(i * 2, c, Endian.little);
  }
  final file = File('assets/data/subset_counts.bin');
  file.writeAsBytesSync(bytes);
  stdout.writeln('\n✓ Écrit ${file.path} : ${bytes.length} octets (4096 × uint16).');
}

/// Énumère tous les pavages du plateau à partir de son état courant et incrémente table.
void _count(List<List<int>> p, int w, int h, int usedMask, List<int> table) {
  int? target;
  outer:
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (p[y][x] == 0) {
        target = y * w + x;
        break outer;
      }
    }
  }
  if (target == null) {
    table[usedMask]++;
    return;
  }
  final tx = target % w;
  final ty = target ~/ w;

  for (int id = 1; id <= 12; id++) {
    final bit = 1 << (id - 1);
    if (usedMask & bit != 0) continue;

    for (final coords in _pieceOrientations[id - 1]) {
      // Toute cellule de la pièce peut couvrir la case cible : chaque choix donne un placement
      // distinct. Les considérer tous — ne pas s'arrêter au premier.
      for (final c in coords) {
        final gx = tx - c[0];
        final gy = ty - c[1];
        if (_canPlace(coords, gx, gy, w, h, p)) {
          _fill(coords, gx, gy, id, p);
          if (_regionsValid(p, w, h)) {
            _count(p, w, h, usedMask | bit, table);
          }
          _fill(coords, gx, gy, 0, p); // retrait
        }
      }
    }
  }
}

bool _canPlace(List<List<int>> coords, int gx, int gy, int w, int h, List<List<int>> p) {
  for (final c in coords) {
    final ax = gx + c[0];
    final ay = gy + c[1];
    if (ax < 0 || ax >= w || ay < 0 || ay >= h) return false;
    if (p[ay][ax] != 0) return false;
  }
  return true;
}

void _fill(List<List<int>> coords, int gx, int gy, int value, List<List<int>> p) {
  for (final c in coords) {
    p[gy + c[1]][gx + c[0]] = value;
  }
}

/// Toute zone vide connexe doit être de taille multiple de 5, sinon la branche est impossible.
bool _regionsValid(List<List<int>> p, int w, int h) {
  final visited = List<List<bool>>.generate(h, (_) => List<bool>.filled(w, false));
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (p[y][x] == 0 && !visited[y][x]) {
        if (_floodFill(x, y, p, visited, w, h) % 5 != 0) return false;
      }
    }
  }
  return true;
}

int _floodFill(int x, int y, List<List<int>> p, List<List<bool>> visited, int w, int h) {
  if (x < 0 || x >= w || y < 0 || y >= h) return 0;
  if (visited[y][x] || p[y][x] != 0) return 0;
  visited[y][x] = true;
  return 1 +
      _floodFill(x - 1, y, p, visited, w, h) +
      _floodFill(x + 1, y, p, visited, w, h) +
      _floodFill(x, y - 1, p, visited, w, h) +
      _floodFill(x, y + 1, p, visited, w, h);
}

/// Toutes les orientations distinctes d'une pièce (groupe diédral D4, réflexions autorisées),
/// depuis ses numéros de case 5×5. Chaque orientation est normalisée (coin haut-gauche en 0,0).
List<List<List<int>>> _orientationsOf(List<int> baseCells) {
  final pts = baseCells.map((n) => [(n - 1) % 5, (n - 1) ~/ 5]).toList();
  final seen = <String, List<List<int>>>{};
  for (int refl = 0; refl < 2; refl++) {
    var cur = refl == 0
        ? pts
        : pts.map((c) => [-c[0], c[1]]).toList(); // réflexion selon l'axe y
    for (int rot = 0; rot < 4; rot++) {
      final norm = _normalize(cur);
      seen[_key(norm)] = norm;
      cur = cur.map((c) => [-c[1], c[0]]).toList(); // rotation 90°
    }
  }
  return seen.values.toList();
}

List<List<int>> _normalize(List<List<int>> cells) {
  var minX = 1 << 30, minY = 1 << 30;
  for (final c in cells) {
    if (c[0] < minX) minX = c[0];
    if (c[1] < minY) minY = c[1];
  }
  final norm = cells.map((c) => [c[0] - minX, c[1] - minY]).toList();
  norm.sort((a, b) => a[1] != b[1] ? a[1] - b[1] : a[0] - b[0]);
  return norm;
}

String _key(List<List<int>> cells) => cells.map((c) => '${c[0]},${c[1]}').join(';');

int _popcount(int x) {
  var c = 0;
  while (x != 0) {
    c += x & 1;
    x >>= 1;
  }
  return c;
}

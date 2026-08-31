// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES.md §8 B) : corpus complet des solutions
//           de tous les tirages solubles, toutes tailles 5×n, pour donner à chaque taille une
//           source adossée à une table (comme le 6×10) et supprimer le solveur live du runtime.
// tools/generate_solutions_corpus.dart
//
// MÊME parcours que generate_subset_counts.dart (§9.1 : « A et B font le même parcours, B écrit
// des octets en plus »). Différences :
//   - chaque plateau est parcouru dans son ORIENTATION RUNTIME (n<5 → n×5, sinon 5×n), pour que
//     l'appariement en octets se fasse sans transposition ;
//   - à plateau plein, on n'incrémente pas un compteur : on ÉCRIT le plateau (un octet bit6 par
//     case, cellIndex = y·width + x) dans le blob du masque utilisé.
//
// Sortie : assets/data/solutions_corpus.bin — les solutions groupées par masque, masques dans
//   l'ordre croissant 0..4095. Chaque solution = 5·popcount(masque) octets (code bit6, 0 impossible
//   puisque tout bit6 est non nul). Pas d'en-tête : le chargeur retrouve l'offset d'un masque en
//   cumulant subset_counts.bin (mêmes comptes, même indexation par bit id−1). Poids ≈ 3,1 Mo.
//
// Filets (exit 1 sinon) :
//   - orientations totalisant 63 (§3.1) ;
//   - totaux par popcount reproduisant REFERENCE_TIRAGES.md §2 ;
//   - compte par masque IDENTIQUE à subset_counts.bin (garantit le découpage au runtime).
//
// Flutter-free comme son jumeau : baseShape recopiées de pentominos.dart, orientations par le
// groupe diédral D4. Les bit6 par id sont recopiés de pentominos.dart (id 1..12, ordre X..I).

import 'dart:io';
import 'dart:typed_data';

/// `baseShape` des 12 pièces, ordre id 1..12 (X, P, T, F, Y, V, U, L, N, W, Z, I). Case n → x=(n−1)%5,
/// y=(n−1)~/5. Identique à generate_subset_counts.dart.
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

/// bit6 par id (1..12), recopié de lib/common/pentominos.dart. Tous distincts, tous < 64.
const List<int> _bit6 = [7, 11, 19, 35, 13, 21, 37, 25, 41, 49, 14, 22];

/// n ∈ 3..10 : le corpus ne couvre que les tailles à pièces tirées. Le 6×10 (n=12) a son propre
/// asset solutions_6x10_normalisees.bin ; on ne le duplique pas ici.
const List<int> _sizes = [3, 4, 5, 6, 7, 8, 9, 10];

/// Totaux attendus par popcount (REFERENCE_TIRAGES.md §2).
const Map<int, int> _expectedTotals = {
  3: 28, 4: 200, 5: 856, 6: 2164, 7: 5584, 8: 13632, 9: 23608, 10: 27804,
};

/// [pièce 0..11][orientation][cellule][x, y].
late final List<List<List<List<int>>>> _pieceOrientations;

/// Blob par masque, rempli à plateau plein. `null` tant qu'aucune solution.
final List<BytesBuilder?> _solutionsByMask = List<BytesBuilder?>.filled(4096, null);

void main() {
  _pieceOrientations = List.generate(12, (i) => _orientationsOf(_baseShapes[i]));
  final totalOrientations =
      _pieceOrientations.fold<int>(0, (s, o) => s + o.length);
  if (totalOrientations != 63) {
    stderr.writeln('❌ Orientations = $totalOrientations, attendu 63 (§3.1).');
    exit(1);
  }

  stdout.writeln('═════════════════════════════════════════════════');
  stdout.writeln('GÉNÉRATION solutions_corpus.bin — corpus complet (§8 B)');
  stdout.writeln('═════════════════════════════════════════════════');
  stdout.writeln('Orientations totales : $totalOrientations ✓ (§3.1)\n');

  var ok = true;
  final totalSw = Stopwatch()..start();

  for (final n in _sizes) {
    final width = n < 5 ? n : 5; // orientation runtime (portrait) : n<5 → n×5, sinon 5×n
    final height = n < 5 ? 5 : n;
    final plateau = List<List<int>>.generate(
      height,
      (_) => List<int>.filled(width, 0),
    );

    final sw = Stopwatch()..start();
    _enumerate(plateau, width, height, 0);
    sw.stop();

    var total = 0, soluble = 0, min = 1 << 30, max = 0;
    final cellBytes = 5 * n;
    for (int m = 0; m < 4096; m++) {
      if (_popcount(m) != n) continue;
      final bb = _solutionsByMask[m];
      if (bb == null) continue;
      final c = bb.length ~/ cellBytes;
      total += c;
      soluble++;
      if (c < min) min = c;
      if (c > max) max = c;
    }
    if (soluble == 0) min = 0;

    final expected = _expectedTotals[n];
    final mark = total == expected ? '✓' : '✗ ATTENDU $expected';
    stdout.writeln('n=$n  $width×$height  total=$total  solubles=$soluble  '
        'min=$min max=$max  (${sw.elapsedMilliseconds} ms)  $mark');
    if (total != expected) ok = false;
  }

  totalSw.stop();
  stdout.writeln('\nTemps total des 8 parcours : ${totalSw.elapsedMilliseconds} ms');

  if (!ok) {
    stderr.writeln('\n❌ Un total ne reproduit pas REFERENCE_TIRAGES.md §2 — asset NON écrit.');
    exit(1);
  }

  // Filet fort : le compte par masque doit être IDENTIQUE à subset_counts.bin (mêmes comptes,
  // même indexation) — sans quoi le découpage au runtime, qui s'appuie sur cette table, serait faux.
  _checkAgainstSubsetCounts();

  // Écriture : masques dans l'ordre croissant, solutions concaténées.
  final out = BytesBuilder();
  for (int m = 0; m < 4096; m++) {
    final bb = _solutionsByMask[m];
    if (bb != null) out.add(bb.toBytes());
  }
  final bytes = out.toBytes();
  final file = File('assets/data/solutions_corpus.bin');
  file.writeAsBytesSync(bytes);
  stdout.writeln('\n✓ Écrit ${file.path} : ${bytes.length} octets '
      '(${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} Mo).');
}

/// Énumère tous les pavages depuis l'état courant ; à plateau plein, écrit le plateau.
void _enumerate(List<List<int>> p, int w, int h, int usedMask) {
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
    _record(p, w, h, usedMask);
    return;
  }
  final tx = target % w;
  final ty = target ~/ w;

  for (int id = 1; id <= 12; id++) {
    final bit = 1 << (id - 1);
    if (usedMask & bit != 0) continue;
    for (final coords in _pieceOrientations[id - 1]) {
      for (final c in coords) {
        final gx = tx - c[0];
        final gy = ty - c[1];
        if (_canPlace(coords, gx, gy, w, h, p)) {
          _fill(coords, gx, gy, id, p);
          if (_regionsValid(p, w, h)) {
            _enumerate(p, w, h, usedMask | bit);
          }
          _fill(coords, gx, gy, 0, p);
        }
      }
    }
  }
}

/// Écrit le plateau plein dans le blob de son masque : un octet bit6 par case, cellIndex = y·w+x.
void _record(List<List<int>> p, int w, int h, int usedMask) {
  final bb = _solutionsByMask[usedMask] ??= BytesBuilder();
  final row = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      row[y * w + x] = _bit6[p[y][x] - 1];
    }
  }
  bb.add(row);
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

/// Vérifie le compte par masque contre subset_counts.bin (4096 × uint16 petit-boutiste).
void _checkAgainstSubsetCounts() {
  final f = File('assets/data/subset_counts.bin');
  if (!f.existsSync()) {
    stderr.writeln('❌ subset_counts.bin absent — générer A d\'abord.');
    exit(1);
  }
  final bd = ByteData.sublistView(f.readAsBytesSync());
  for (int m = 0; m < 4096; m++) {
    // subset_counts.bin couvre aussi le 5×12 (popcount 12, contrôle §3) que le corpus n'inclut
    // pas ; ne comparer que les tailles du corpus (popcount ∈ 3..10).
    if (!_sizes.contains(_popcount(m))) continue;
    final expected = bd.getUint16(m * 2, Endian.little);
    final bb = _solutionsByMask[m];
    final got = bb == null ? 0 : bb.length ~/ (5 * _popcount(m));
    if (got != expected) {
      stderr.writeln('❌ masque $m : corpus $got ≠ subset_counts $expected.');
      exit(1);
    }
  }
  stdout.writeln('✓ Compte par masque identique à subset_counts.bin (popcounts 3..10).');
}

List<List<List<int>>> _orientationsOf(List<int> baseCells) {
  final pts = baseCells.map((n) => [(n - 1) % 5, (n - 1) ~/ 5]).toList();
  final seen = <String, List<List<int>>>{};
  for (int refl = 0; refl < 2; refl++) {
    var cur = refl == 0 ? pts : pts.map((c) => [-c[0], c[1]]).toList();
    for (int rot = 0; rot < 4; rot++) {
      final norm = _normalize(cur);
      seen[_key(norm)] = norm;
      cur = cur.map((c) => [-c[1], c[0]]).toList();
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

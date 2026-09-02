// Modified: 2026-09-02 15:27 — création : génère la constante des 7 tirages du 3×5 (plateau
//           d'accueil 5 large × 3 haut) pour l'animation-démo de l'écran d'accueil (PLAN_ECRAN_ACCUEIL §3).
// tools/generate_home_tirages.dart
//
// Flutter-free et autonome (comme generate_solutions_corpus.dart) : baseShapes recopiées de
// lib/common/pentominos.dart (ordre id 1..12 = X P T F Y V U L N W Z I), orientations par le
// groupe diédral D4, énumération par backtracking.
//
// Énumère le plateau 5×3 (5 large × 3 haut : l'orientation d'affichage de l'accueil ; le 3×5 du
// corpus est 3 large × 5 haut — même contenu à transposition près, REFERENCE_TIRAGES §1). Pour
// chacun des 7 tirages solubles, capture UNE solution réelle et compte le total (contrôle §3 :
// 7 masques, exactement 4 solutions chacun, noms = PFU/PUN/PVL/PVU/PYU/TYL/VLN).
//
// Sortie : lib/pentoscope/home/home_tirages_data.dart — constante kHomeTirages consommée par
// l'écran d'accueil (PieceRenderer + getPieceColor).
//
// Usage : dart run tools/generate_home_tirages.dart

import 'dart:io';

/// baseShape des 12 pièces, ordre id 1..12 (X, P, T, F, Y, V, U, L, N, W, Z, I).
/// Case n → x=(n−1)%5, y=(n−1)~/5. Identique à generate_solutions_corpus.dart.
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

/// Lettre par id (1..12), même ordre que _baseShapes (REFERENCE_TIRAGES §7/§10).
const List<String> _letters = [
  'X', 'P', 'T', 'F', 'Y', 'V', 'U', 'L', 'N', 'W', 'Z', 'I'
];

/// Attendu (PLAN_ECRAN_ACCUEIL §3, REFERENCE_TIRAGES §7) : les 7 tirages solubles du 3×5.
const Set<String> _expectedNames = {
  'PFU', 'PUN', 'PVL', 'PVU', 'PYU', 'TYL', 'VLN'
};

const int _w = 5; // plateau d'accueil : 5 large
const int _h = 3; //                     3 haut

late final List<List<List<List<int>>>> _pieceOrientations;

/// mask → première solution capturée (plateau 3×5 d'ids), et mask → nombre total de solutions.
final Map<int, List<List<int>>> _firstSolution = {};
final Map<int, int> _countByMask = {};

void main() {
  _pieceOrientations = List.generate(12, (i) => _orientationsOf(_baseShapes[i]));
  final totalOrientations =
      _pieceOrientations.fold<int>(0, (s, o) => s + o.length);
  if (totalOrientations != 63) {
    stderr.writeln('❌ Orientations = $totalOrientations, attendu 63.');
    exit(1);
  }

  final plateau = List<List<int>>.generate(_h, (_) => List<int>.filled(_w, 0));
  _enumerate(plateau, _w, _h, 0, (p, usedMask) {
    _countByMask[usedMask] = (_countByMask[usedMask] ?? 0) + 1;
    _firstSolution.putIfAbsent(
        usedMask, () => p.map((row) => List<int>.of(row)).toList());
  });

  // ── Contrôles d'acceptation (PLAN_ECRAN_ACCUEIL §3) ────────────────────────
  final masks = _firstSolution.keys.toList();
  if (masks.length != 7) {
    stderr.writeln('❌ ${masks.length} masques solubles, attendu 7.');
    exit(1);
  }
  final names = <int, String>{for (final m in masks) m: _maskName(m)};
  final nameSet = names.values.toSet();
  if (nameSet.length != 7 || !nameSet.containsAll(_expectedNames)) {
    stderr.writeln('❌ Noms $nameSet ≠ attendus $_expectedNames.');
    exit(1);
  }
  for (final m in masks) {
    if (_countByMask[m] != 4) {
      stderr.writeln('❌ ${names[m]} : ${_countByMask[m]} solutions, attendu 4.');
      exit(1);
    }
  }
  stdout.writeln('✓ 7 tirages, 4 solutions chacun, noms $_expectedNames.');

  // ── Émission ───────────────────────────────────────────────────────────────
  final sortedMasks = masks..sort((a, b) => names[a]!.compareTo(names[b]!));
  final out = StringBuffer()
    ..writeln('// GÉNÉRÉ par tools/generate_home_tirages.dart — NE PAS MODIFIER À LA MAIN.')
    ..writeln('// Les 7 tirages du 3×5 (plateau d\'accueil 5 large × 3 haut), une solution réelle')
    ..writeln('// chacun. Chaque pièce : id (1..12, couleur via getPieceColor) + ses 5 cellules (x,y).')
    ..writeln('// lib/pentoscope/home/home_tirages_data.dart')
    ..writeln()
    ..writeln('/// Un tirage de l\'écran d\'accueil : nom (lettres des pièces) + les 3 pièces posées.')
    ..writeln('class HomeTirage {')
    ..writeln('  final String name;')
    ..writeln('  final List<HomePiece> pieces;')
    ..writeln('  const HomeTirage(this.name, this.pieces);')
    ..writeln('}')
    ..writeln()
    ..writeln('/// Une pièce posée : id du pentomino et ses 5 cellules [x, y] sur le plateau 5×3.')
    ..writeln('class HomePiece {')
    ..writeln('  final int id;')
    ..writeln('  final List<List<int>> cells;')
    ..writeln('  const HomePiece(this.id, this.cells);')
    ..writeln('}')
    ..writeln()
    ..writeln('/// Plateau d\'accueil : $_w cases de large × $_h de haut.')
    ..writeln('const int kHomeBoardWidth = $_w;')
    ..writeln('const int kHomeBoardHeight = $_h;')
    ..writeln()
    ..writeln('const List<HomeTirage> kHomeTirages = [');
  for (final m in sortedMasks) {
    final p = _firstSolution[m]!;
    out.writeln("  HomeTirage('${names[m]}', [");
    // ids présents, triés croissant (= ordre des lettres du nom).
    final ids = <int>{for (final row in p) ...row.where((v) => v != 0)}.toList()
      ..sort();
    for (final id in ids) {
      final cells = <List<int>>[];
      for (int y = 0; y < _h; y++) {
        for (int x = 0; x < _w; x++) {
          if (p[y][x] == id) cells.add([x, y]);
        }
      }
      final cellsStr = cells.map((c) => '[${c[0]}, ${c[1]}]').join(', ');
      out.writeln('    HomePiece($id, [$cellsStr]),');
    }
    out.writeln('  ]),');
  }
  out.writeln('];');

  final file = File('lib/pentoscope/home/home_tirages_data.dart');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(out.toString());
  stdout.writeln('✓ Écrit ${file.path} (${sortedMasks.length} tirages).');
}

String _maskName(int mask) {
  final sb = StringBuffer();
  for (int id = 1; id <= 12; id++) {
    if (mask & (1 << (id - 1)) != 0) sb.write(_letters[id - 1]);
  }
  return sb.toString();
}

// ── Énumération (recopiée de generate_solutions_corpus.dart) ──────────────────

void _enumerate(List<List<int>> p, int w, int h, int usedMask,
    void Function(List<List<int>> p, int usedMask) onFull) {
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
    onFull(p, usedMask);
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
            _enumerate(p, w, h, usedMask | bit, onFull);
          }
          _fill(coords, gx, gy, 0, p);
        }
      }
    }
  }
}

bool _canPlace(
    List<List<int>> coords, int gx, int gy, int w, int h, List<List<int>> p) {
  for (final c in coords) {
    final ax = gx + c[0];
    final ay = gy + c[1];
    if (ax < 0 || ax >= w || ay < 0 || ay >= h) return false;
    if (p[ay][ax] != 0) return false;
  }
  return true;
}

void _fill(
    List<List<int>> coords, int gx, int gy, int value, List<List<int>> p) {
  for (final c in coords) {
    p[gy + c[1]][gx + c[0]] = value;
  }
}

bool _regionsValid(List<List<int>> p, int w, int h) {
  final visited =
      List<List<bool>>.generate(h, (_) => List<bool>.filled(w, false));
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (p[y][x] == 0 && !visited[y][x]) {
        if (_floodFill(x, y, p, visited, w, h) % 5 != 0) return false;
      }
    }
  }
  return true;
}

int _floodFill(int x, int y, List<List<int>> p, List<List<bool>> visited, int w,
    int h) {
  if (x < 0 || x >= w || y < 0 || y >= h) return 0;
  if (visited[y][x] || p[y][x] != 0) return 0;
  visited[y][x] = true;
  return 1 +
      _floodFill(x - 1, y, p, visited, w, h) +
      _floodFill(x + 1, y, p, visited, w, h) +
      _floodFill(x, y - 1, p, visited, w, h) +
      _floodFill(x, y + 1, p, visited, w, h);
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

String _key(List<List<int>> cells) =>
    cells.map((c) => '${c[0]},${c[1]}').join(';');

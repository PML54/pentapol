// Modified: 2026-09-07 14:20 — refonte : « aire non multiple de 5 » (englobe les poches < 5) +
//           gravité continue décroissante avec la taille ; suppression du niveau discret « poche ».
// Historique: 2026-09-07 14:08 — création : golden du classifieur de fautes (analyzeFault).
// test/fault_analysis_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/fault_analysis.dart';

/// Construit un plateau depuis une grille ASCII : `.` = case vide (0), `#` = mur (pièce, 1).
Plateau boardFrom(List<String> rows) {
  final h = rows.length;
  final w = rows.first.length;
  final b = Plateau.allVisible(w, h); // tout à 0
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (rows[y][x] == '#') b.setCell(x, y, 1);
    }
  }
  return b;
}

void main() {
  group('analyzeFault — cause + gravité', () {
    test('aire non multiple de 5 : poche de 4 (englobe l\'ancien « poche < 5 »)', () {
      final board = boardFrom([
        '..#',
        '..#',
        '###',
      ]);
      final a = analyzeFault(board);
      expect(a.kind, FaultKind.aireNonMultipleDe5);
      expect(a.zoneCause, 4);
      expect(a.gravite, 5.0); // 20 / 4
      expect(a.zoneSizes, [4]);
    });

    test('aire non multiple de 5 : zone de 7', () {
      final board = boardFrom([
        '..#',
        '..#',
        '...',
      ]);
      final a = analyzeFault(board);
      expect(a.kind, FaultKind.aireNonMultipleDe5);
      expect(a.zoneCause, 7);
      expect(a.gravite, closeTo(20 / 7, 1e-9));
    });

    test('impossibilité subtile : deux zones de 5 (multiples de 5)', () {
      final board = boardFrom([
        '.....',
        '#####',
        '.....',
      ]);
      final a = analyzeFault(board);
      expect(a.kind, FaultKind.impossibiliteSubtile);
      expect(a.zoneCause, isNull);
      expect(a.gravite, kGraviteSubtile);
      expect(a.zoneSizes, [5, 5]);
    });

    test('la plus PETITE zone non multiple de 5 fixe la gravité', () {
      // Zone de 6 (haut) et zone de 4 (bas) : la 4 gagne (plus petite = plus grave).
      final board = boardFrom([
        '...',
        '...',
        '###',
        '..#',
        '..#',
      ]);
      final a = analyzeFault(board);
      expect(a.kind, FaultKind.aireNonMultipleDe5);
      expect(a.zoneSizes, containsAll(<int>[6, 4]));
      expect(a.zoneCause, 4);
      expect(a.gravite, 5.0);
    });

    test('gravité décroissante : une zone de 4 est plus grave qu\'une zone de 9', () {
      final zone4 = analyzeFault(Plateau.allVisible(2, 2)); // 4 cases
      final zone9 = analyzeFault(Plateau.allVisible(3, 3)); // 9 cases
      expect(zone4.kind, FaultKind.aireNonMultipleDe5);
      expect(zone9.kind, FaultKind.aireNonMultipleDe5);
      expect(zone4.gravite, greaterThan(zone9.gravite));
    });

    test('description et étiquette courte', () {
      final board = boardFrom([
        '..#',
        '..#',
        '###',
      ]);
      final a = analyzeFault(board);
      expect(a.description, contains('Zone de 4 cases (non multiple de 5)'));
      expect(a.labelCourt, '⚠️ 4 (g5.0)');
    });
  });
}

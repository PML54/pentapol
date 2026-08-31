// Modified: 2026-08-31 16:39 — création (REFERENCE_TIRAGES §8 B) : appariement de masques en
//           octets, factorisé pour les deux sources adossées à une table (SolutionMatcher pour le
//           6×10, CorpusSolutionSource pour les petites tailles). Sans allocation sur le chemin
//           chaud ; c'est ce que la mesure n°2 (§9) impose. Placé en common/ : couche basse
//           partagée par services/solution_matcher (6×10) et pentoscope/solution_source (corpus).
// lib/common/byte_matching.dart

import 'dart:typed_data';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/point.dart';

/// Solutions stockées **à plat** : `cells` octets par solution, un code bit6 par case
/// (0 = vide, impossible dans une solution). [query] a la même longueur ; une case y vaut
/// le code bit6 de la pièce posée, 0 si vide. Comme aucun bit6 ne vaut 0, « case occupée »
/// ⟺ `query[c] != 0`, sans masque séparé.
///
/// Une solution est compatible si elle porte le même code sur **toutes** les cases occupées.
/// On ne balaie que ces cases (précalculées) et on s'arrête à la première divergence — aucune
/// allocation dans la boucle.

/// Compte les solutions compatibles.
int countCompatibleFlat(Uint8List solutions, Uint8List query, int cells) {
  final occupied = _occupiedCells(query, cells);
  final total = solutions.length ~/ cells;
  if (occupied.isEmpty) return total;
  final m = occupied.length;
  int count = 0;
  for (int base = 0; base < solutions.length; base += cells) {
    if (_matches(solutions, base, occupied, query, m)) count++;
  }
  return count;
}

/// Y a-t-il au moins une solution compatible ? (arrêt au premier succès)
bool anyCompatibleFlat(Uint8List solutions, Uint8List query, int cells) {
  final occupied = _occupiedCells(query, cells);
  if (occupied.isEmpty) return solutions.isNotEmpty;
  final m = occupied.length;
  for (int base = 0; base < solutions.length; base += cells) {
    if (_matches(solutions, base, occupied, query, m)) return true;
  }
  return false;
}

/// Les offsets `base` (multiples de `cells`) des solutions compatibles.
List<int> compatibleBasesFlat(Uint8List solutions, Uint8List query, int cells) {
  final occupied = _occupiedCells(query, cells);
  final m = occupied.length;
  final out = <int>[];
  for (int base = 0; base < solutions.length; base += cells) {
    if (occupied.isEmpty || _matches(solutions, base, occupied, query, m)) {
      out.add(base);
    }
  }
  return out;
}

List<int> _occupiedCells(Uint8List query, int cells) {
  final occupied = <int>[];
  for (int c = 0; c < cells; c++) {
    if (query[c] != 0) occupied.add(c);
  }
  return occupied;
}

bool _matches(
    Uint8List solutions, int base, List<int> occupied, Uint8List query, int m) {
  for (int j = 0; j < m; j++) {
    final c = occupied[j];
    if (solutions[base + c] != query[c]) return false;
  }
  return true;
}

/// bit6 → id (1..12), depuis la liste canonique des pièces.
final Map<int, int> _idByBit6 = {for (final p in pentominos) p.bit6: p.id};

/// Reconstruit les [PlacedPiece] d'un plateau plein stocké à plat (`width×height` octets bit6,
/// cellIndex = y·width + x), pour l'option « afficher la solution ». Même logique que
/// SolutionMatcher.solutionToPlacedPieces, mais depuis des octets et pour des dimensions
/// quelconques.
List<PlacedPiece> flatBoardToPlacedPieces(
    Uint8List blob, int base, int width, int height) {
  final cellsByBit6 = <int, List<Point>>{};
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final code = blob[base + y * width + x];
      if (code == 0) continue;
      cellsByBit6.putIfAbsent(code, () => []).add(Point(x, y));
    }
  }

  final result = <PlacedPiece>[];
  for (final entry in cellsByBit6.entries) {
    final id = _idByBit6[entry.key];
    if (id == null) continue;
    final pento = pentominos[id - 1];
    final cells = entry.value;

    var minX = 1 << 30, minY = 1 << 30;
    for (final c in cells) {
      if (c.x < minX) minX = c.x;
      if (c.y < minY) minY = c.y;
    }
    final normalized = {
      for (final c in cells) '${c.x - minX},${c.y - minY}',
    };

    int positionIndex = 0;
    for (int i = 0; i < pento.cartesianCoords.length; i++) {
      final coords = {
        for (final c in pento.cartesianCoords[i]) '${c[0]},${c[1]}',
      };
      if (coords.length == normalized.length &&
          coords.containsAll(normalized)) {
        positionIndex = i;
        break;
      }
    }

    result.add(PlacedPiece(
      piece: pento,
      positionIndex: positionIndex,
      gridX: minX,
      gridY: minY,
    ));
  }
  return result;
}

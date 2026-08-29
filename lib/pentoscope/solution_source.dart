// Modified: 2026-08-29 09:26 — 6×10 dans Pentoscope (temps 2, étape 2) : interface
//           SolutionSource et ses deux implémentations (table pré-calculée / solveur à la
//           volée). Isolé, non branché à ce stade — le câblage (startPuzzle) vient à l'étape 4.
// lib/pentoscope/solution_source.dart
// D'où viennent les réponses « solution » d'un puzzle Pentoscope :
// - rectangle complet adossé à une table (6×10 aujourd'hui) → TableSolutionSource ;
// - toute autre taille → LiveSolutionSource (PentoscopeSolver, à la volée).
// Voir docs/PLAN_6X10_DANS_PENTOSCOPE.md §4.2 et §4.6.

import 'dart:math';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart' show SolutionTable;
import 'package:pentapol/pentoscope/pentoscope_solver.dart';
import 'package:pentapol/services/solution_matcher.dart';

/// Origine des réponses « solution » d'un puzzle. Un seul site le lit : `startPuzzle`.
abstract interface class SolutionSource {
  /// Une solution reste-t-elle atteignable depuis ce plateau ?
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining);

  /// Combien de solutions complètes restent compatibles.
  /// `null` quand la source ne sait pas compter — c'est le cas du solveur à la volée.
  int? countFrom(Plateau plateau);

  /// Une solution compatible (ses placements), pour l'indice. `null` s'il n'y en a plus.
  ///
  /// [remaining] sert au solveur ; la table l'ignore (elle renvoie la solution complète,
  /// à l'appelant de choisir une pièce non encore posée).
  List<PlacedPiece>? hintFrom(Plateau plateau, List<Pento> remaining);
}

/// Grille `[y][x]` attendue par le solveur, construite depuis un plateau.
List<List<int>> _grid(Plateau plateau) => List<List<int>>.generate(
      plateau.height,
      (y) => List<int>.generate(plateau.width, (x) => plateau.getCell(x, y)),
    );

/// Source à la volée, au-dessus de [PentoscopeSolver]. Ne sait pas compter.
class LiveSolutionSource implements SolutionSource {
  final PentoscopeSolver _solver;

  LiveSolutionSource(this._solver);

  @override
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) {
    if (remaining.isEmpty) return false;
    return _solver.canSolveFrom(
      remaining.map((p) => p.id).toList(),
      plateau.width,
      plateau.height,
      _grid(plateau),
    );
  }

  @override
  int? countFrom(Plateau plateau) => null;

  @override
  List<PlacedPiece>? hintFrom(Plateau plateau, List<Pento> remaining) {
    if (remaining.isEmpty) return null;
    final solution = _solver.findSolutionFrom(
      remaining.map((p) => p.id).toList(),
      plateau.width,
      plateau.height,
      _grid(plateau),
    );
    if (solution == null || solution.isEmpty) return null;
    return solution
        .map((s) => PlacedPiece(
              piece: pentominos[s.pieceId - 1],
              positionIndex: s.positionIndex,
              gridX: s.gridX,
              gridY: s.gridY,
            ))
        .toList();
  }
}

/// Source adossée à une table pré-calculée (rectangle complet), au-dessus d'un
/// [SolutionMatcher] **déjà chargé**. Sait compter ; sa disponibilité = compte > 0.
class TableSolutionSource implements SolutionSource {
  final SolutionMatcher _matcher;
  final SolutionTable table;
  final Random _random;

  TableSolutionSource(this._matcher, this.table, {Random? random})
      : _random = random ?? Random();

  /// `(piecesBits, maskBits)` du plateau, dans le même ordre de cases que le `.bin`
  /// (cellIndex = y·width + x, bits de poids fort en premier).
  (BigInt, BigInt) _mask(Plateau plateau) {
    final bit6ById = {for (final p in pentominos) p.id: p.bit6};
    var pieces = BigInt.zero;
    var mask = BigInt.zero;
    for (int y = 0; y < table.height; y++) {
      for (int x = 0; x < table.width; x++) {
        pieces = pieces << 6;
        mask = mask << 6;
        final v = plateau.getCell(x, y);
        if (v == 0) continue;
        final code = bit6ById[v];
        if (code == null) continue;
        pieces = pieces | BigInt.from(code);
        mask = mask | BigInt.from(0x3F);
      }
    }
    return (pieces, mask);
  }

  @override
  int? countFrom(Plateau plateau) {
    final (pieces, m) = _mask(plateau);
    return _matcher.countCompatibleFromBigInts(pieces, m);
  }

  @override
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) {
    // Sur un rectangle complet, « compte > 0 » ⟺ « les pièces restantes peuvent
    // remplir le plateau » (§2). [remaining] est ignoré : la table le sait déjà.
    final (pieces, m) = _mask(plateau);
    return _matcher.countCompatibleFromBigInts(pieces, m) > 0;
  }

  @override
  List<PlacedPiece>? hintFrom(Plateau plateau, List<Pento> remaining) {
    final (pieces, m) = _mask(plateau);
    final indices = _matcher.getCompatibleSolutionIndices(pieces, m);
    if (indices.isEmpty) return null;
    // Décision de Paul (§4.6) : une solution compatible AU HASARD.
    final idx = indices[_random.nextInt(indices.length)];
    return _matcher.getPlacedPiecesByIndex(idx);
  }
}

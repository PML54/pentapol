// Modified: 2026-08-31 16:39 — étape B (REFERENCE_TIRAGES §8 B) : LiveSolutionSource (solveur live)
//           remplacée par CorpusSolutionSource — les petites tailles s'adossent désormais au corpus
//           précalculé, comme le 6×10, via l'appariement en octets partagé (byte_matching.dart).
//           countFrom devient non-nullable partout ; le solveur backtracking sort du chemin chaud.
// lib/pentoscope/solution_source.dart
// Historique: 2026-08-31 16:39 — appariement Uint8List (§9) : countFrom/hasSolutionFrom du 6×10
//             passent par countCompatibleBytes ; _mask BigInt réservé aux chemins froids.
// Historique: 2026-08-30 11:40 — PLAN_PERSISTANCE §7 étape 3 : 5e méthode solutionIndexOf(plateau).
// Historique: 2026-08-29 09:26 — 6×10 temps 2 étape 2 : interface SolutionSource + 2 impls.
// D'où viennent les réponses « solution » d'un puzzle Pentoscope, désormais toutes adossées à une
// table pré-calculée :
// - rectangle complet 6×10 → TableSolutionSource (SolutionMatcher, BigInt pour le navigateur) ;
// - tailles à pièces tirées 5×n → CorpusSolutionSource (corpus découpé par masque).

import 'dart:math';
import 'dart:typed_data';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/byte_matching.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart' show SolutionTable;
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

  /// Les solutions complètes compatibles avec ce plateau, en BigInt (pour le
  /// navigateur de solutions). Liste vide pour la source à la volée, qui ne les
  /// énumère pas.
  List<BigInt> compatibleSolutions(Plateau plateau);

  /// Le **numéro** (1-based) de la solution atteinte sur un plateau **complet**, ou
  /// `null` si la source ne sait pas la nommer (solveur à la volée) ou si le plateau
  /// ne correspond à aucune solution de la table. C'est la frontière entre les deux
  /// familles de records : `null` → PuzzleStats, un entier → SolvedSolutions
  /// (PLAN_PERSISTANCE §4.3).
  int? solutionIndexOf(Plateau plateau);
}

/// Octets bit6 d'un plateau (un octet par case, `cellIndex = y·width + x`, 0 si vide) —
/// l'entrée des appariements de [byte_matching]. Partagé par les deux sources.
Uint8List _pieceBytes(Plateau plateau) {
  final bit6ById = {for (final p in pentominos) p.id: p.bit6};
  final bytes = Uint8List(plateau.width * plateau.height);
  for (int y = 0; y < plateau.height; y++) {
    for (int x = 0; x < plateau.width; x++) {
      final v = plateau.getCell(x, y);
      if (v == 0) continue;
      final code = bit6ById[v];
      if (code != null) bytes[y * plateau.width + x] = code;
    }
  }
  return bytes;
}

/// Source adossée au **corpus** pré-calculé, pour les tailles à pièces tirées (5×n). Reçoit
/// les solutions du tirage courant à plat (`count × cells` octets, un code bit6 par case) et
/// répond par appariement d'octets, sans allocation ni solveur — voir REFERENCE_TIRAGES §8 B.
///
/// La disponibilité est « compte > 0 », comme pour un rectangle complet : le tirage emploie
/// toutes ses pièces, donc « une solution reste atteignable » ⟺ « compte > 0 » (§2).
class CorpusSolutionSource implements SolutionSource {
  /// Solutions du tirage, à plat. Vue sans copie sur le blob du corpus.
  final Uint8List _solutions;
  final int _cells; // 5 × nombre de pièces du tirage
  final int _width;
  final int _height;
  final Random _random;

  CorpusSolutionSource(
    this._solutions, {
    required int width,
    required int height,
    Random? random,
  })  : _width = width,
        _height = height,
        _cells = width * height,
        _random = random ?? Random();

  /// Source vide (aucune solution) — état initial avant le premier tirage.
  CorpusSolutionSource.empty()
      : _solutions = Uint8List(0),
        _cells = 0,
        _width = 0,
        _height = 0,
        _random = Random();

  @override
  int? countFrom(Plateau plateau) =>
      countCompatibleFlat(_solutions, _pieceBytes(plateau), _cells);

  @override
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) =>
      anyCompatibleFlat(_solutions, _pieceBytes(plateau), _cells);

  @override
  List<PlacedPiece>? hintFrom(Plateau plateau, List<Pento> remaining) {
    final bases = compatibleBasesFlat(_solutions, _pieceBytes(plateau), _cells);
    if (bases.isEmpty) return null;
    final base = bases[_random.nextInt(bases.length)];
    return flatBoardToPlacedPieces(_solutions, base, _width, _height);
  }

  @override
  List<BigInt> compatibleSolutions(Plateau plateau) => const [];

  @override
  int? solutionIndexOf(Plateau plateau) => null;
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
  /// (cellIndex = y·width + x, bits de poids fort en premier). Chemins froids seulement.
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
  int? countFrom(Plateau plateau) =>
      _matcher.countCompatibleBytes(_pieceBytes(plateau));

  @override
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining) {
    // Sur un rectangle complet, « compte > 0 » ⟺ « les pièces restantes peuvent
    // remplir le plateau » (§2). [remaining] est ignoré : la table le sait déjà.
    return _matcher.countCompatibleBytes(_pieceBytes(plateau)) > 0;
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

  @override
  List<BigInt> compatibleSolutions(Plateau plateau) {
    final (pieces, m) = _mask(plateau);
    return _matcher.getCompatibleSolutionsFromBigInts(pieces, m);
  }

  @override
  int? solutionIndexOf(Plateau plateau) {
    // Sur un plateau complet, `pieces` est exactement le BigInt d'une solution du
    // .bin ; findSolutionIndex renvoie son rang 0-based (-1 si absent). On expose un
    // numéro 1-based, aligné sur SolvedSolutions.solutionNumber (1..9356).
    final (pieces, _) = _mask(plateau);
    final idx = _matcher.findSolutionIndex(pieces);
    return idx < 0 ? null : idx + 1;
  }
}

// Modified: 2026-08-31 16:39 — étape B (§8 B) : PentoscopeSolver sort du générateur. puzzleFromMask
//           ne calcule plus de solution (le champ PentoscopePuzzle.solutions est supprimé — la
//           solution « à afficher » vient désormais de la SolutionSource via hintFrom, côté
//           provider). generateFromSeed lit le compte dans subset_counts.bin au lieu du solveur.
// lib/pentoscope/pentoscope_generator.dart
// Historique: 2026-08-31 18:00 — tirage par table (§8 A) : generate() tire un masque parmi les
//             solubles de subset_counts.bin ; solutionCount = table[masque], non-nullable.
// Historique: 2026-08-31 17:00 — suppression de la difficulté (generateEasy/Hard, switch retirés).
// Historique: 2026-08-29 07:46 — 6×10 (temps 1) : court-circuit _buildFullRectanglePuzzle (9356).
// Dimensions transposées: 3×5 = 3 colonnes × 5 lignes (portrait)

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Table des comptes par sous-ensemble : 4096 × uint16 (voir tools/generate_subset_counts.dart
/// et REFERENCE_TIRAGES.md). Index = masque 12 bits, bit (id − 1). 0 ⟺ tirage insoluble.
const String _subsetCountsAsset = 'assets/data/subset_counts.bin';

/// Générateur de puzzles Pentoscope.
class PentoscopeGenerator {
  final Random _random;

  /// Chargés paresseusement à la première génération hors 6×10.
  List<int>? _counts; // table[masque] = nombre de solutions
  Map<int, List<int>>? _solubleByPopcount; // popcount → masques avec compte > 0

  PentoscopeGenerator([Random? random]) : _random = random ?? Random();

  /// Charge `subset_counts.bin` une fois et en déduit, par un balayage des 4096 entrées, la
  /// liste des masques solubles regroupés par popcount (= nombre de pièces = taille du plateau).
  Future<void> _ensureTable() async {
    if (_counts != null) return;
    final data = await rootBundle.load(_subsetCountsAsset);
    final counts =
        List<int>.generate(4096, (i) => data.getUint16(i * 2, Endian.little));
    final byPop = <int, List<int>>{};
    for (int m = 0; m < 4096; m++) {
      if (counts[m] > 0) {
        byPop.putIfAbsent(_popcount(m), () => <int>[]).add(m);
      }
    }
    _counts = counts;
    _solubleByPopcount = byPop;
  }

  int _popcount(int x) {
    var c = 0;
    while (x != 0) {
      c += x & 1;
      x >>= 1;
    }
    return c;
  }

  /// Tire au hasard un masque soluble pour une taille (hors 6×10). Charge la table au besoin.
  Future<int> drawMask(PentoscopeSize size) async {
    await _ensureTable();
    final masks = _solubleByPopcount![size.numPieces]!;
    return masks[_random.nextInt(masks.length)];
  }

  /// Nombre de solutions d'un masque (la table doit être chargée — via drawMask ou generate).
  int countOfMask(int mask) => _counts![mask];

  /// Les ids de pièces (1..12) présents dans le masque.
  List<int> _piecesOfMask(int mask) {
    final ids = <int>[];
    for (int id = 1; id <= 12; id++) {
      if (mask & (1 << (id - 1)) != 0) ids.add(id);
    }
    return ids;
  }

  /// Court-circuit pour le rectangle complet 6×10 : tirage forcé des 12 pièces, compte connu
  /// (9356), solutions laissées **vides** (branchées via la table au temps 2). Évite le chemin
  /// normal du générateur, qui sur 12 pièces coûterait très cher (voir PLAN_6X10 §3.1).
  PentoscopePuzzle _buildFullRectanglePuzzle(PentoscopeSize size) =>
      PentoscopePuzzle(
        size: size,
        pieceIds: List.generate(12, (i) => i + 1),
        solutionCount: 9356,
      );

  /// Génère un puzzle aléatoire pour une taille donnée.
  ///
  /// Hors 6×10 : on tire **au hasard un masque parmi les solubles** de `size.numPieces`
  /// (distribution identique au rejet successif d'avant : uniforme sur les solubles), et on lit
  /// `solutionCount = table[masque]` — un compte honnête, d'où `solutionCount` non nullable.
  /// Aucun appel-boucle au solveur, aucune borne, aucune question de timeout.
  Future<PentoscopePuzzle> generate(PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    await _ensureTable();
    final masks = _solubleByPopcount![size.numPieces]!;
    return puzzleFromMask(size, masks[_random.nextInt(masks.length)]);
  }

  /// Construit le puzzle d'un masque donné : pièces + compte (`table[masque]`). La solution
  /// « à afficher » n'est plus calculée ici — elle vient de la SolutionSource (corpus/table) via
  /// `hintFrom`, côté provider. La table doit être chargée (via `drawMask`/`generate`).
  PentoscopePuzzle puzzleFromMask(PentoscopeSize size, int mask) {
    return PentoscopePuzzle(
      size: size,
      pieceIds: _piecesOfMask(mask),
      solutionCount: _counts![mask],
    );
  }

  /// 🎮 Génère un puzzle avec des pièces spécifiques (mode multiplayer). Le compte vient de la
  /// table (`subset_counts.bin`), plus du solveur : exact, sans troncature. [seed] n'entre pas
  /// dans le compte (il pilote le tirage des pièces, fait en amont côté duel).
  Future<PentoscopePuzzle> generateFromSeed(
    PentoscopeSize size,
    int seed,
    List<int> pieceIds,
  ) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    await _ensureTable();
    var mask = 0;
    for (final id in pieceIds) {
      mask |= 1 << (id - 1);
    }
    return PentoscopePuzzle(
      size: size,
      pieceIds: pieceIds,
      solutionCount: _counts![mask],
    );
  }
}

/// Configuration d'un puzzle Pentoscope
class PentoscopePuzzle {
  /// Noms des pièces (X, P, T, F, Y, V, U, L, N, W, Z, I)
  static const _pieceNames = [
    'X',
    'P',
    'T',
    'F',
    'Y',
    'V',
    'U',
    'L',
    'N',
    'W',
    'Z',
    'I',
  ];

  final PentoscopeSize size;
  final List<int> pieceIds;

  /// Nombre de solutions du puzzle (connu : table pour les petites tailles, 9356 pour le 6×10).
  final int solutionCount;

  const PentoscopePuzzle({
    required this.size,
    required this.pieceIds,
    required this.solutionCount,
  });

  /// Description lisible
  String get description =>
      '${size.label} avec ${pieceNames.join(", ")} ($solutionCount solution${solutionCount > 1 ? "s" : ""})';

  /// Retourne les noms des pièces du puzzle
  List<String> get pieceNames =>
      pieceIds.map((id) => _pieceNames[id - 1]).toList();

  @override
  String toString() => 'PentoscopePuzzle($description)';
}

/// Table de solutions pré-calculées d'un rectangle complet de pentominos.
///
/// Une seule valeur au temps 1 (le 6×10, seule table déjà générée). Les autres
/// rectangles complets (5×12, 4×15, 3×20) s'ajouteront avec leurs tables — voir
/// PLAN_6X10_DANS_PENTOSCOPE.md §5.
enum SolutionTable {
  r6x10('assets/data/solutions_6x10_normalisees.bin', 6, 10, 2339);

  const SolutionTable(this.asset, this.width, this.height, this.canonicalCount);
  final String asset;
  final int width;
  final int height;

  /// Solutions à symétrie près, telles que stockées dans le .bin.
  final int canonicalCount;

  /// Après expansion identité / rot180 / miroirH / miroirV. Valide tant qu'aucune
  /// solution n'est invariante par l'une des trois — vérifié à la génération.
  int get totalCount => canonicalCount * 4;
}

/// Tailles de plateau disponibles (TRANSPOSÉES pour portrait)
enum PentoscopeSize {
  size3x5(0, 3, 5, 3, '3', null),
  size4x5(1, 4, 5, 4, '4', null),
  size5x5(2, 5, 5, 5, '5', null),
  size6x5(3, 5, 6, 6, '6', null),
  size7x5(4, 5, 7, 7, '7', null),
  size8x5(5, 5, 8, 8, '8', null),
  size9x5(6, 5, 9, 9, '9', null),
  size10x5(7, 5, 10, 10, '10', null),
  size6x10(8, 6, 10, 12, '6×10', SolutionTable.r6x10);

  final int dataIndex; // Legacy
  final int width;
  final int height;
  final int numPieces;
  final String label;

  /// Table de solutions pré-calculées, ou null si le puzzle est résolu à la volée.
  ///
  /// N'est valide que si la configuration emploie **toutes** les pièces de la table
  /// et qu'**aucune case n'est masquée** — voir PLAN_6X10_DANS_PENTOSCOPE.md §2.
  final SolutionTable? table;

  const PentoscopeSize(
      this.dataIndex,
      this.width,
      this.height,
      this.numPieces,
      this.label,
      this.table,
      );

  int get area => width * height;
}

/// Statistiques (optionnel - pas vraiment utilisé en lazy mode)
class PentoscopeStats {
  final PentoscopeSize size;
  final String description;

  const PentoscopeStats({
    required this.size,
    required this.description,
  });

  @override
  String toString() => '$description';
}
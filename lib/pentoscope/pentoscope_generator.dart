// Modified: 2026-08-31 17:00 — suppression de la difficulté : generateEasy/generateHard retirés ;
//           generate ne fait plus qu'une passe (findSolutionFrom sur plateau vide) au lieu de
//           findFirstSolution + findAllSolutions ; boucle bornée (200) au lieu d'infinie ;
//           solutions: [solutionTrouvée] (répare « afficher la solution ») ; solutionCount → int?.
// lib/pentoscope/pentoscope_generator.dart
// Historique: 2026-08-29 07:46 — 6×10 (temps 1) : court-circuit _buildFullRectanglePuzzle (9356).
// Historique: 2512161105 — Générateur lazy : solutions en live (pas de table).
// Dimensions transposées: 3×5 = 3 colonnes × 5 lignes (portrait)

import 'dart:math';
import 'package:pentapol/pentoscope/pentoscope_solver.dart';


/// Générateur de puzzles Pentoscope (lazy, sans table pré-calculée)
class PentoscopeGenerator {
  final Random _random;
  late final PentoscopeSolver _solver;

  PentoscopeGenerator([Random? random])
      : _random = random ?? Random() {
    _solver = PentoscopeSolver();
  }

  /// Court-circuit pour le rectangle complet 6×10 : tirage forcé des 12 pièces, compte connu
  /// (9356), solutions laissées **vides** (branchées via la table au temps 2). Évite le chemin
  /// normal du générateur, qui sur 12 pièces coûterait très cher (voir PLAN_6X10 §3.1).
  PentoscopePuzzle _buildFullRectanglePuzzle(PentoscopeSize size) =>
      PentoscopePuzzle(
        size: size,
        pieceIds: List.generate(12, (i) => i + 1),
        solutionCount: 9356,
        solutions: const [],
      );

  /// Génère un puzzle aléatoire pour une taille donnée.
  ///
  /// Une seule passe du solveur par tirage : `findSolutionFrom` sur le plateau vide renvoie
  /// `null` si le tirage est insoluble (⟹ nouveau tirage), sinon **la** solution trouvée, qu'on
  /// stocke — ce qui répare l'option « afficher la solution » sur ces tailles. On n'énumère plus
  /// toutes les solutions (calcul mort depuis la suppression de la difficulté), donc `solutionCount`
  /// n'a pas de valeur honnête hors 6×10 : `null`.
  ///
  /// Boucle **bornée** (pas de timeout au solveur : « insoluble » et « pas terminé » doivent
  /// rester distincts — question renvoyée au chantier de mesure). Sur ces petites tailles un
  /// tirage aléatoire est presque toujours soluble ; atteindre la borne signalerait une anomalie.
  Future<PentoscopePuzzle> generate(PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);

    final emptyGrid = List<List<int>>.generate(
      size.height,
      (_) => List<int>.filled(size.width, 0),
    );

    const maxAttempts = 200;
    List<int> lastPieceIds = const [];
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final pieceIds = _selectRandomPieces(size.numPieces);
      lastPieceIds = pieceIds;

      final solution =
          _solver.findSolutionFrom(pieceIds, size.width, size.height, emptyGrid);
      if (solution != null) {
        return PentoscopePuzzle(
          size: size,
          pieceIds: pieceIds,
          solutionCount: null, // hors 6×10 : aucun compte honnête (plus d'énumération)
          solutions: [solution],
        );
      }
    }

    // Repli explicite : borne atteinte. On rend le dernier tirage sans solution — la partie
    // démarre quand même et le joueur peut relancer (ne devrait jamais arriver sur ces tailles).
    return PentoscopePuzzle(
      size: size,
      pieceIds: lastPieceIds,
      solutionCount: null,
      solutions: const [],
    );
  }

  /// Sélectionne N pièces aléatoires parmi les 12 disponibles
  List<int> _selectRandomPieces(int count) {
    final all = List<int>.generate(12, (i) => i + 1); // 1..12
    all.shuffle(_random);
    return all.sublist(0, count);
  }

  /// 🎮 Génère un puzzle avec un seed et des pièces spécifiques (mode multiplayer)
  /// Ne vérifie pas les solutions - on fait confiance aux paramètres fournis
  Future<PentoscopePuzzle> generateFromSeed(
    PentoscopeSize size,
    int seed,
    List<int> pieceIds,
  ) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    // Chercher les solutions (optionnel, pour le scoring)
    final result = await _solver.findAllSolutions(
      pieceIds,
      size.width,
      size.height,
      timeout: const Duration(seconds: 2),
    );

    return PentoscopePuzzle(
      size: size,
      pieceIds: pieceIds,
      solutionCount: result.solutionCount,
      solutions: result.solutions,
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

  /// Nombre de solutions du puzzle, ou `null` quand il n'est pas connu de façon honnête :
  /// hors 6×10, on ne fait plus d'énumération (une seule solution est trouvée et stockée).
  final int? solutionCount;
  final List<Solution> solutions; // La (ou les) solution(s) trouvée(s)

  const PentoscopePuzzle({
    required this.size,
    required this.pieceIds,
    required this.solutionCount,
    required this.solutions,
  });

  /// Description lisible
  String get description {
    final count = solutionCount;
    final countPart =
        count != null ? ' ($count solution${count > 1 ? "s" : ""})' : '';
    return '${size.label} avec ${pieceNames.join(", ")}$countPart';
  }

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
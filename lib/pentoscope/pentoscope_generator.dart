// Modified: 2026-08-29 07:46 — 6×10 dans Pentoscope (temps 1) : enum SolutionTable (r6x10),
//           taille size6x10 (12 pièces) portant sa table, et court-circuit
//           _buildFullRectanglePuzzle dans les 4 points d'entrée du générateur (solutions
//           laissées vides, compte 9356) pour éviter tirage forcé et timeout silencieux.
// lib/pentoscope/pentoscope_generator.dart
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

  /// Court-circuit pour le rectangle complet 6×10 : tirage forcé des 12 pièces,
  /// compte connu (9356), solutions laissées **vides** — elles seront branchées
  /// au temps 2. Évite le chemin normal du générateur, qui sur 12 pièces donne un
  /// tirage forcé, un compte partiel silencieux à l'expiration du timeout, et une
  /// boucle infinie côté generateEasy (voir PLAN_6X10_DANS_PENTOSCOPE.md §3.1).
  PentoscopePuzzle _buildFullRectanglePuzzle(PentoscopeSize size) =>
      PentoscopePuzzle(
        size: size,
        pieceIds: List.generate(12, (i) => i + 1),
        solutionCount: 9356,
        solutions: const [],
      );

  /// Génère un puzzle aléatoire pour une taille donnée
  /// Boucle jusqu'à trouver une combinaison valide (avec 1+ solution)
  Future<PentoscopePuzzle> generate(PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    while (true) {
      final pieceIds = _selectRandomPieces(size.numPieces);

      // Étape 2: chercher rapidement si solution existe
      final hasFirst = _solver.findFirstSolution(
        pieceIds,
        size.width,
        size.height,
      );

      if (!hasFirst) {
        continue; // Retry
      }

      // Étape 3: chercher TOUTES les solutions avec timeout 2s
      final result = await _solver.findAllSolutions(
        pieceIds,
        size.width,
        size.height,
        timeout: const Duration(seconds: 2),
      );

      // Étape 4: créer puzzle
      return PentoscopePuzzle(
        size: size,
        pieceIds: pieceIds,
        solutionCount: result.solutionCount,
        solutions: result.solutions,
      );
    }
  }

  /// Génère un puzzle en favorisant ceux avec plus de solutions (faciles)
  /// Boucle jusqu'à solutionCount >= threshold
  Future<PentoscopePuzzle> generateEasy(PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    const minSolutions = 4; // Au moins 4 solutions pour être "facile"

    while (true) {
      final pieceIds = _selectRandomPieces(size.numPieces);

      final hasFirst = _solver.findFirstSolution(
        pieceIds,
        size.width,
        size.height,
      );

      if (!hasFirst) {
        continue;
      }

      final result = await _solver.findAllSolutions(
        pieceIds,
        size.width,
        size.height,
        timeout: const Duration(seconds: 2),
      );

      // Garder si assez de solutions
      if (result.solutionCount >= minSolutions) {
        return PentoscopePuzzle(
          size: size,
          pieceIds: pieceIds,
          solutionCount: result.solutionCount,
          solutions: result.solutions,
        );
      }
      // Sinon: retry
    }
  }

  /// Génère un puzzle en favorisant ceux avec peu de solutions (durs)
  /// Boucle jusqu'à solutionCount <= threshold
  Future<PentoscopePuzzle> generateHard(PentoscopeSize size) async {
    if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
    const maxSolutions = 2; // Max 2 solutions pour être "difficile"

    while (true) {
      final pieceIds = _selectRandomPieces(size.numPieces);

      final hasFirst = _solver.findFirstSolution(
        pieceIds,
        size.width,
        size.height,
      );

      if (!hasFirst) {
        continue;
      }

      final result = await _solver.findAllSolutions(
        pieceIds,
        size.width,
        size.height,
        timeout: const Duration(seconds: 2),
      );

      // Garder si peu de solutions
      if (result.solutionCount <= maxSolutions) {
        return PentoscopePuzzle(
          size: size,
          pieceIds: pieceIds,
          solutionCount: result.solutionCount,
          solutions: result.solutions,
        );
      }
      // Sinon: retry
    }
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
  final int solutionCount;
  final List<Solution> solutions; // Toutes les solutions trouvées

  const PentoscopePuzzle({
    required this.size,
    required this.pieceIds,
    required this.solutionCount,
    required this.solutions,
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
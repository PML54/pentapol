/// Génération et gestion des puzzles pour le mode Duel Isométries
///
/// Ce fichier gère :
/// - La génération d'un puzzle avec solution et cible
/// - La création de pièces "faussées" (isométries aléatoires)
/// - Le calcul du nombre optimal d'isométries
/// - Les structures de données pour le jeu
///
/// Note: Les messages WebSocket sont dans duel_isometry_messages.dart

import 'dart:math';

import 'isometry_utils.dart';

// ============================================================================
// STRUCTURES DE DONNÉES
// ============================================================================

/// Représente une pièce dans la solution cible du puzzle
class TargetPiece {
  /// Identifiant de la pièce (1-12 correspondant aux pentominos)
  final int pieceId;

  /// Nom de la pièce ("F", "I", "L", "N", "P", "T", "U", "V", "W", "X", "Y", "Z")
  final String pieceName;

  /// Position cible sur le plateau (ancre)
  final int targetGridX;
  final int targetGridY;

  /// Index de la position/variante dans le modèle de pièce (0-7 typiquement)
  final int targetPositionIndex;

  /// Configuration d'isométrie cible (calculée depuis positionIndex)
  final PieceConfiguration targetConfig;

  /// Configuration initiale "faussée" (isométries aléatoires appliquées)
  final PieceConfiguration initialConfig;

  /// Index de position initial correspondant à initialConfig
  final int initialPositionIndex;

  /// Nombre minimal d'isométries pour passer de initial à target
  final int minIsometries;

  const TargetPiece({
    required this.pieceId,
    required this.pieceName,
    required this.targetGridX,
    required this.targetGridY,
    required this.targetPositionIndex,
    required this.targetConfig,
    required this.initialConfig,
    required this.initialPositionIndex,
    required this.minIsometries,
  });

  @override
  String toString() =>
      'TargetPiece($pieceName: target=r${targetConfig.rotation}${targetConfig.flipped ? "f" : "n"}, '
          'initial=r${initialConfig.rotation}${initialConfig.flipped ? "f" : "n"}, minIso=$minIsometries)';
}

/// Représente un puzzle complet pour le mode Duel Isométries
class IsometryPuzzle {
  /// Dimensions du plateau
  final int width;
  final int height;

  /// Seed utilisé pour la génération (pour reproductibilité)
  final int seed;

  /// Liste des pièces avec leurs configurations cible et initiale
  final List<TargetPiece> pieces;

  /// Nombre total minimal d'isométries pour résoudre le puzzle
  final int totalMinIsometries;

  /// Représentation de la forme cible (grille avec IDs des pièces)
  /// 0 = case vide, 1-12 = ID de pièce
  final List<List<int>> targetGrid;

  const IsometryPuzzle({
    required this.width,
    required this.height,
    required this.seed,
    required this.pieces,
    required this.totalMinIsometries,
    required this.targetGrid,
  });

  /// Nombre de pièces dans le puzzle
  int get pieceCount => pieces.length;

  /// Génère un puzzle aléatoire avec les paramètres donnés
  factory IsometryPuzzle.generate({
    required int width,
    required int height,
    int? seed,
    int minIsometriesPerPiece = 1,
    int maxIsometriesPerPiece = 3,
  }) {
    final actualSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final random = Random(actualSeed);

    // Générer une solution valide
    final solution = _generateSolution(width, height, random);

    // Créer les pièces faussées
    final pieces = <TargetPiece>[];
    int totalMin = 0;

    for (final solPiece in solution.pieces) {
      // Configuration cible
      final targetConfig = _positionIndexToConfig(solPiece.positionIndex);

      // Générer une configuration initiale faussée
      final (initialConfig, distance) = _generateFaussedConfig(
        targetConfig,
        random,
        minDistance: minIsometriesPerPiece,
        maxDistance: maxIsometriesPerPiece,
      );

      // Trouver le positionIndex correspondant à initialConfig
      final initialPosIndex = _configToPositionIndex(
        solPiece.pieceId,
        initialConfig,
        solPiece.positionIndex, // fallback si non trouvé
      );

      pieces.add(TargetPiece(
        pieceId: solPiece.pieceId,
        pieceName: solPiece.pieceName,
        targetGridX: solPiece.gridX,
        targetGridY: solPiece.gridY,
        targetPositionIndex: solPiece.positionIndex,
        targetConfig: targetConfig,
        initialConfig: initialConfig,
        initialPositionIndex: initialPosIndex,
        minIsometries: distance,
      ));

      totalMin += distance;
    }

    return IsometryPuzzle(
      width: width,
      height: height,
      seed: actualSeed,
      pieces: pieces,
      totalMinIsometries: totalMin,
      targetGrid: solution.grid,
    );
  }

  /// Vérifie si une pièce est correctement placée et orientée
  bool isPieceCorrect(int pieceId, int gridX, int gridY, int positionIndex) {
    final target = pieces.firstWhere(
          (p) => p.pieceId == pieceId,
      orElse: () => throw ArgumentError('Pièce $pieceId non trouvée'),
    );

    return target.targetGridX == gridX &&
        target.targetGridY == gridY &&
        target.targetPositionIndex == positionIndex;
  }

  @override
  String toString() =>
      'IsometryPuzzle(${width}x$height, ${pieces.length} pièces, minIso=$totalMinIsometries)';
}

// ============================================================================
// GÉNÉRATION DE SOLUTION
// ============================================================================

/// Solution intermédiaire (avant création des pièces faussées)
class _SolutionPiece {
  final int pieceId;
  final String pieceName;
  final int gridX;
  final int gridY;
  final int positionIndex;

  const _SolutionPiece({
    required this.pieceId,
    required this.pieceName,
    required this.gridX,
    required this.gridY,
    required this.positionIndex,
  });
}

class _Solution {
  final List<_SolutionPiece> pieces;
  final List<List<int>> grid;

  const _Solution(this.pieces, this.grid);
}

/// Noms des 12 pentominos
const _pieceNames = ['F', 'I', 'L', 'N', 'P', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

/// Nombre de variantes (positions/isométries) par pièce
/// Ces valeurs correspondent exactement aux numPositions dans pentominos.dart
const _pieceVariantCounts = {
  1: 1,  // X (très symétrique)
  2: 8,  // F
  3: 4,  // T (symétrique)
  4: 8,  // L
  5: 8,  // N
  6: 4,  // U (symétrique)
  7: 4,  // V (symétrique)
  8: 8,  // P
  9: 8,  // Y
  10: 4, // W (symétrique)
  11: 4, // Z (symétrique)
  12: 2, // I (symétrique)
};

/// Génère une solution valide pour un plateau de taille donnée
/// Utilise un backtracking simplifié
_Solution _generateSolution(int width, int height, Random random) {
  final grid = List.generate(height, (_) => List.filled(width, 0));
  final pieces = <_SolutionPiece>[];

  // Nombre de pièces nécessaires pour remplir width * 5 cases
  // (chaque pentomino = 5 cases)
  final targetPieces = width; // 3x5=15 cases = 3 pièces, 4x5=20 = 4 pièces, etc.

  // Sélectionner des pièces aléatoires
  final availablePieceIds = List.generate(12, (i) => i + 1);
  availablePieceIds.shuffle(random);
  final selectedPieceIds = availablePieceIds.take(targetPieces).toList();

  // Placer chaque pièce
  for (final pieceId in selectedPieceIds) {
    final placed = _placePieceRandomly(
      grid,
      pieceId,
      random,
      width,
      height,
    );

    if (placed != null) {
      pieces.add(placed);
    } else {
      // Si on ne peut pas placer une pièce, on réessaie avec la génération complète
      // (ceci est une simplification - en production, utiliser un vrai backtracking)
      return _generateSolution(width, height, Random(random.nextInt(1000000)));
    }
  }

  return _Solution(pieces, grid);
}

// ============================================================================
// PLACEMENT DE PIÈCES
// ============================================================================

/// Tente de placer une pièce aléatoirement sur le plateau
_SolutionPiece? _placePieceRandomly(
    List<List<int>> grid,
    int pieceId,
    Random random,
    int width,
    int height,
    ) {
  final shapes = _getPieceShapes(pieceId);
  final variantCount = shapes.length;

  // Essayer plusieurs positions aléatoires
  final positions = <(int, int, int)>[]; // (x, y, variantIndex)

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      for (int v = 0; v < variantCount; v++) {
        if (_canPlace(grid, shapes[v], x, y, width, height)) {
          positions.add((x, y, v));
        }
      }
    }
  }

  if (positions.isEmpty) return null;

  // Choisir une position aléatoire
  final (x, y, v) = positions[random.nextInt(positions.length)];

  // Placer la pièce
  _place(grid, shapes[v], x, y, pieceId);

  // 🔧 FIX : Normaliser l'ancre (coin haut-gauche de la pièce)
  final (normalizedX, normalizedY) = _getNormalizedAnchor(shapes[v], x, y);

  return _SolutionPiece(
    pieceId: pieceId,
    pieceName: _pieceNames[pieceId - 1],
    gridX: normalizedX,
    gridY: normalizedY,
    positionIndex: v,
  );
}

/// Vérifie si une forme peut être placée à une position
bool _canPlace(
    List<List<int>> grid,
    List<List<int>> shape,
    int anchorX,
    int anchorY,
    int width,
    int height,
    ) {
  for (final cell in shape) {
    final x = anchorX + cell[0];
    final y = anchorY + cell[1];

    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    if (grid[y][x] != 0) return false;
  }
  return true;
}

/// Place une pièce sur le plateau
void _place(
    List<List<int>> grid,
    List<List<int>> shape,
    int anchorX,
    int anchorY,
    int pieceId,
    ) {
  for (final cell in shape) {
    final x = anchorX + cell[0];
    final y = anchorY + cell[1];
    grid[y][x] = pieceId;
  }
}

/// 🔧 NOUVELLE FONCTION : Calcule l'ancre normalisée (coin haut-gauche de la pièce)
/// Retourne les coordonnées réelles de l'ancre après normalisation
(int, int) _getNormalizedAnchor(List<List<int>> shape, int baseX, int baseY) {
  int minX = 5, minY = 5;

  // Trouver le coin haut-gauche relatif dans la shape
  for (final cell in shape) {
    if (cell[0] < minX) minX = cell[0];
    if (cell[1] < minY) minY = cell[1];
  }

  // Retourner l'ancre normalisée (coin haut-gauche absolu)
  return (baseX + minX, baseY + minY);
}

// ============================================================================
// DÉFINITIONS DES FORMES DES PIÈCES
// ============================================================================

/// Retourne les variantes d'une pièce basées sur cartesianCoords de pentominos.dart
/// IMPORTANT: pieceId 1-12 correspondent aux indices 0-11 dans le tableau pentominos
/// pieceId 1 (X) → cartesianCoords[0]
/// pieceId 2 (F) → cartesianCoords[1]
/// ... etc
List<List<List<int>>> _getPieceShapes(int pieceId) {
  // Convertir pieceId (1-12) en coordonnées cartésiennes normalisées
  // Les coordonnées sont déjà dans le bon format [x, y]
  switch (pieceId) {
    case 1: // X (pieceId 1) - ultra-symétrique
      return [
        [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]], // seule variante
      ];

    case 2: // F (pieceId 2)
      return [
        [[0, 0], [0, 1], [1, 0], [1, 1], [1, 2]],
        [[0, 1], [1, 0], [1, 1], [2, 0], [2, 1]],
        [[0, 0], [0, 1], [0, 2], [1, 1], [1, 2]],
        [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0]],
        [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1]],
        [[0, 0], [1, 0], [1, 1], [2, 0], [2, 1]],
        [[0, 1], [0, 2], [1, 0], [1, 1], [1, 2]],
        [[0, 0], [0, 1], [1, 0], [1, 1], [2, 1]],
      ];

    case 3: // T (pieceId 3)
      return [
        [[0, 1], [1, 1], [2, 0], [2, 1], [2, 2]],
        [[0, 2], [1, 0], [1, 1], [1, 2], [2, 2]],
        [[0, 0], [0, 1], [0, 2], [1, 1], [2, 1]],
        [[0, 0], [1, 0], [1, 1], [1, 2], [2, 0]],
      ];

    case 4: // L (pieceId 4)
      return [
        [[0, 1], [1, 1], [2, 0], [2, 1], [3, 0]],
        [[0, 1], [1, 0], [1, 1], [2, 1], [2, 2]],
        [[0, 2], [1, 0], [1, 1], [1, 2], [2, 1]],
        [[0, 0], [0, 1], [1, 1], [1, 2], [2, 1]],
        [[0, 0], [1, 0], [1, 1], [1, 2], [2, 1]],
        [[0, 1], [1, 1], [1, 2], [2, 0], [2, 1]],
        [[0, 1], [1, 0], [1, 1], [1, 2], [2, 2]],
        [[0, 1], [0, 2], [1, 0], [1, 1], [2, 1]],
      ];

    case 5: // N (pieceId 5)
      return [
        [[0, 2], [1, 0], [1, 1], [1, 2], [1, 3]],
        [[0, 1], [1, 1], [2, 0], [2, 1], [3, 1]],
        [[0, 0], [0, 1], [0, 2], [0, 3], [1, 1]],
        [[0, 0], [1, 0], [2, 0], [2, 1], [3, 0]],
        [[0, 0], [0, 1], [0, 2], [0, 3], [1, 2]],
        [[0, 0], [1, 0], [1, 1], [2, 0], [3, 0]],
        [[0, 1], [1, 0], [1, 1], [1, 2], [1, 3]],
        [[0, 1], [1, 1], [2, 0], [2, 1], [3, 1]],
      ];

    case 6: // U (pieceId 6)
      return [
        [[0, 2], [1, 2], [2, 0], [2, 1], [2, 2]],
        [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]],
        [[0, 0], [0, 1], [0, 2], [1, 0], [2, 0]],
        [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]],
      ];

    case 7: // V (pieceId 7)
      return [
        [[0, 0], [0, 1], [1, 1], [2, 0], [2, 1]],
        [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2]],
        [[0, 0], [0, 1], [1, 0], [2, 0], [2, 1]],
        [[0, 0], [0, 2], [1, 0], [1, 1], [1, 2]],
      ];

    case 8: // P (pieceId 8)
      return [
        [[0, 1], [1, 1], [2, 1], [3, 0], [3, 1]],
        [[0, 0], [0, 1], [0, 2], [0, 3], [1, 3]],
        [[0, 0], [0, 1], [1, 0], [2, 0], [3, 0]],
        [[0, 0], [1, 0], [1, 1], [1, 2], [1, 3]],
        [[0, 0], [0, 1], [1, 1], [2, 1], [3, 1]],
        [[0, 0], [0, 1], [0, 2], [0, 3], [1, 0]],
        [[0, 0], [1, 0], [2, 0], [3, 0], [3, 1]],
        [[0, 3], [1, 0], [1, 1], [1, 2], [1, 3]],
      ];

    case 9: // Y (pieceId 9)
      return [
        [[0, 1], [1, 1], [2, 0], [2, 1], [3, 0]],
        [[0, 0], [0, 1], [1, 1], [1, 2], [1, 3]],
        [[0, 1], [1, 0], [1, 1], [2, 0], [3, 0]],
        [[0, 0], [0, 1], [1, 1], [1, 2], [1, 3]],
        [[0, 0], [1, 0], [1, 1], [2, 1], [3, 1]],
        [[0, 1], [0, 2], [0, 3], [1, 0], [1, 1]],
        [[0, 0], [1, 0], [2, 0], [2, 1], [3, 1]],
        [[0, 2], [0, 3], [1, 0], [1, 1], [1, 2]],
      ];

    case 10: // W (pieceId 10)
      return [
        [[0, 1], [0, 2], [1, 1], [2, 0], [2, 1]],
        [[0, 0], [1, 0], [1, 1], [1, 2], [2, 2]],
        [[0, 0], [0, 1], [1, 1], [2, 1], [2, 2]],
        [[0, 2], [1, 0], [1, 1], [1, 2], [2, 0]],
      ];

    case 11: // Z (pieceId 11)
      return [
        [[0, 2], [1, 1], [1, 2], [2, 0], [2, 1]],
        [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2]],
        [[0, 1], [0, 2], [1, 0], [1, 1], [2, 0]],
        [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2]],
      ];

    case 12: // I (pieceId 12)
      return [
        [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]],
        [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]],
      ];

    default:
      return [];
  }
}

// ============================================================================
// CONVERSION CONFIG <-> POSITION INDEX
// ============================================================================

/// Convertit un positionIndex en PieceConfiguration
/// Mapping simplifié basé sur le groupe D₄
PieceConfiguration _positionIndexToConfig(int positionIndex) {
  // Les 8 premiers indices correspondent aux 8 isométries
  // 0-3: rotations sans flip, 4-7: rotations avec flip
  if (positionIndex < 4) {
    return PieceConfiguration(positionIndex, false);
  } else if (positionIndex < 8) {
    return PieceConfiguration(positionIndex - 4, true);
  }
  // Pour les pièces avec moins de 8 variantes, on mappe comme on peut
  return PieceConfiguration(positionIndex % 4, positionIndex >= 4);
}

/// Convertit une PieceConfiguration en positionIndex pour une pièce donnée
int _configToPositionIndex(
    int pieceId,
    PieceConfiguration config,
    int fallback,
    ) {
  final variantCount = _pieceVariantCounts[pieceId] ?? 8;

  // Calcul direct
  int index = config.rotation + (config.flipped ? 4 : 0);

  // S'assurer qu'on ne dépasse pas le nombre de variantes
  if (index >= variantCount) {
    // Pour les pièces symétriques, réduire modulo le nombre de variantes
    index = index % variantCount;
  }

  return index;
}

/// Génère une configuration faussée à une distance donnée de la cible
(PieceConfiguration, int) _generateFaussedConfig(
    PieceConfiguration target,
    Random random, {
      int minDistance = 1,
      int maxDistance = 3,
    }) {
  // Liste des configurations à distance >= minDistance et <= maxDistance
  final candidates = <(PieceConfiguration, int)>[];

  for (int i = 0; i < 8; i++) {
    final config = PieceConfiguration.fromIndex(i);
    final distance = IsometryUtils.minIsometries(config, target);

    if (distance >= minDistance && distance <= maxDistance) {
      candidates.add((config, distance));
    }
  }

  if (candidates.isEmpty) {
    // Fallback: prendre n'importe quelle config différente de target
    for (int i = 0; i < 8; i++) {
      final config = PieceConfiguration.fromIndex(i);
      if (config != target) {
        candidates.add((config, IsometryUtils.minIsometries(config, target)));
      }
    }
  }

  // Choisir aléatoirement
  return candidates[random.nextInt(candidates.length)];
}

// ============================================================================
// ÉTAT DU JEU DUEL ISOMÉTRIES
// ============================================================================

/// État d'une pièce pendant le jeu
class PieceGameState {
  final TargetPiece target;

  /// Configuration actuelle (modifiée par les isométries du joueur)
  PieceConfiguration currentConfig;

  /// Position actuelle sur le plateau (null si pas encore placée)
  int? gridX;
  int? gridY;

  /// Nombre d'isométries appliquées par le joueur
  int isometryCount;

  /// Est-ce que la pièce est correctement placée et orientée ?
  bool get isCorrect =>
      gridX == target.targetGridX &&
          gridY == target.targetGridY &&
          currentConfig == target.targetConfig;

  /// Est-ce que l'isométrie est correcte (indépendamment de la position) ?
  bool get hasCorrectOrientation => currentConfig == target.targetConfig;

  PieceGameState({
    required this.target,
    required this.currentConfig,
    this.gridX,
    this.gridY,
    this.isometryCount = 0,
  });

  /// Crée l'état initial pour une pièce (configuration faussée)
  factory PieceGameState.initial(TargetPiece target) {
    return PieceGameState(
      target: target,
      currentConfig: target.initialConfig,
    );
  }

  /// Applique une rotation R (90° horaire)
  void rotateRight() {
    currentConfig = currentConfig.rotateRight();
    isometryCount++;
  }

  /// Applique une rotation L (90° anti-horaire)
  void rotateLeft() {
    currentConfig = currentConfig.rotateLeft();
    isometryCount++;
  }

  /// Applique un flip horizontal
  void flipHorizontal() {
    currentConfig = currentConfig.flipHorizontal();
    isometryCount++;
  }

  /// Applique un flip vertical
  void flipVertical() {
    currentConfig = currentConfig.flipVertical();
    isometryCount++;
  }
}
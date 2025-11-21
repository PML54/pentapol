// Modified: 2025-11-15 06:45:00
// lib/providers/pentomino_game_state.dart
// État du jeu de pentominos (mode libre)

import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';

/// Représente une pièce placée sur le plateau
class PlacedPiece
{
  final Pento piece;
  final int positionIndex; // Index dans piece.positions
  final int gridX; // Position X sur le plateau (0-5)
  final int gridY; // Position Y sur le plateau (0-9)

  PlacedPiece({
    required this.piece,
    required this.positionIndex,
    required this.gridX,
    required this.gridY,
  });

  /// Obtient les cellules occupées par cette pièce sur le plateau
  List<int> getOccupiedCells() {
    final position = piece.positions[positionIndex];
    final cells = <int>[];

    for (final cellNum in position) {
      // Convertir cellNum (1-25 sur grille 5×5) en coordonnées (x, y)
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;

      // Position absolue sur le plateau
      final x = gridX + localX;
      final y = gridY + localY;

      // Vérifier que c'est dans les limites
      if (x >= 0 && x < 6 && y >= 0 && y < 10) {
        cells.add(y * 6 + x + 1); // cellNum de 1 à 60
      }
    }

    return cells;
  }

  PlacedPiece copyWith({
    Pento? piece,
    int? positionIndex,
    int? gridX,
    int? gridY,
  }) {
    return PlacedPiece(
      piece: piece ?? this.piece,
      positionIndex: positionIndex ?? this.positionIndex,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
    );
  }

  Iterable<Point> get absoluteCells sync* {
    final position = piece.positions[positionIndex];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      yield Point(gridX + localX, gridY + localY);
    }
  }



}

/// État du jeu de pentominos
class PentominoGameState {
  final Plateau plateau;
  final List<Pento> availablePieces; // Pièces encore disponibles dans le slider
  final List<PlacedPiece> placedPieces; // Pièces déjà placées sur le plateau
  final Pento? selectedPiece; // Pièce actuellement sélectionnée (en cours de drag)
  final int selectedPositionIndex; // Position de la pièce sélectionnée
  final PlacedPiece? selectedPlacedPiece; // Référence à la pièce placée sélectionnée
  final Map<int, int> piecePositionIndices; // Index de position pour chaque pièce (par ID)
  final Point? selectedCellInPiece; // Case sélectionnée dans la pièce (point de référence pour le drag)

  // Prévisualisation du placement
  final int? previewX; // Position X de la preview
  final int? previewY; // Position Y de la preview
  final bool isPreviewValid; // La preview est-elle un placement valide ?
  // Validation du plateau
  final bool boardIsValid; // true si pas de chevauchement ni débordement
  final Set<Point> overlappingCells; // Cases où au moins 2 pièces se chevauchent
  final Set<Point> offBoardCells; // Cases de pièces en dehors du plateau

  // Nombre de solutions possibles
  final int? solutionsCount; // Nombre de solutions possibles avec l'état actuel

  // Mode isométries
  final bool isIsometriesMode; // true = mode isométries, false = mode jeu normal
  final PentominoGameState? savedGameState; // État du jeu sauvegardé avant d'entrer en mode isométries

  PentominoGameState({
    required this.plateau,
    required this.availablePieces,
    required this.placedPieces,
    this.selectedPiece,
    this.selectedPositionIndex = 0,
    this.selectedPlacedPiece,
    Map<int, int>? piecePositionIndices,
    this.selectedCellInPiece,
    this.previewX,
    this.previewY,
    this.isPreviewValid = false,
    this.solutionsCount,
    this.isIsometriesMode = false,
    this.savedGameState,

    // Nouveaux champs
    this.boardIsValid = true,
    Set<Point>? overlappingCells,
    Set<Point>? offBoardCells,
  })  : piecePositionIndices = piecePositionIndices ?? {},
        overlappingCells = overlappingCells ?? <Point>{},
        offBoardCells = offBoardCells ?? <Point>{};


  /// État initial du jeu
  factory PentominoGameState.initial() {
    return PentominoGameState(
      plateau: Plateau.allVisible(6, 10),
      availablePieces: List.from(pentominos),
      placedPieces: [],
      selectedPiece: null,
      selectedPositionIndex: 0,
      piecePositionIndices: {},
      boardIsValid: true,
      overlappingCells: <Point>{},
      offBoardCells: <Point>{},
    );
  }


  /// Obtient l'index de position pour une pièce (par défaut 0)
  int getPiecePositionIndex(int pieceId) {
    return piecePositionIndices[pieceId] ?? 0;
  }

  /// Vérifie si une pièce peut être placée à une position donnée
  bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
    final position = piece.positions[positionIndex];

    for (final cellNum in position) {
      // Convertir cellNum (1-25 sur grille 5×5) en coordonnées (x, y)
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;

      // Position absolue sur le plateau
      final x = gridX + localX;
      final y = gridY + localY;

      // Hors limites ?
      if (x < 0 || x >= 6 || y < 0 || y >= 10) {
        return false;
      }

      // Case déjà occupée ?
      final cellValue = plateau.getCell(x, y);
      if (cellValue != 0) {
        return false;
      }
    }

    return true;
  }

  PentominoGameState copyWith({
    Plateau? plateau,
    List<Pento>? availablePieces,
    List<PlacedPiece>? placedPieces,
    Pento? selectedPiece,
    bool clearSelectedPiece = false,
    int? selectedPositionIndex,
    PlacedPiece? selectedPlacedPiece,
    bool clearSelectedPlacedPiece = false,
    Map<int, int>? piecePositionIndices,
    Point? selectedCellInPiece,
    bool clearSelectedCellInPiece = false,
    int? previewX,
    int? previewY,
    bool? isPreviewValid,
    bool clearPreview = false,
    int? solutionsCount,
    bool? isIsometriesMode,
    PentominoGameState? savedGameState,
    bool clearSavedGameState = false,

    // Nouveaux paramètres
    bool? boardIsValid,
    Set<Point>? overlappingCells,
    Set<Point>? offBoardCells,
  }) {
    return PentominoGameState(
      plateau: plateau ?? this.plateau,
      availablePieces: availablePieces ?? this.availablePieces,
      placedPieces: placedPieces ?? this.placedPieces,
      selectedPiece: clearSelectedPiece ? null : (selectedPiece ?? this.selectedPiece),
      selectedPositionIndex: selectedPositionIndex ?? this.selectedPositionIndex,
      selectedPlacedPiece: clearSelectedPlacedPiece ? null : (selectedPlacedPiece ?? this.selectedPlacedPiece),
      piecePositionIndices: piecePositionIndices ?? this.piecePositionIndices,
      selectedCellInPiece: clearSelectedCellInPiece ? null : (selectedCellInPiece ?? this.selectedCellInPiece),
      previewX: clearPreview ? null : (previewX ?? this.previewX),
      previewY: clearPreview ? null : (previewY ?? this.previewY),
      isPreviewValid: clearPreview ? false : (isPreviewValid ?? this.isPreviewValid),
      solutionsCount: solutionsCount ?? this.solutionsCount,
      isIsometriesMode: isIsometriesMode ?? this.isIsometriesMode,
      savedGameState: clearSavedGameState ? null : (savedGameState ?? this.savedGameState),

      // Nouveaux champs
      boardIsValid: boardIsValid ?? this.boardIsValid,
      overlappingCells: overlappingCells ?? this.overlappingCells,
      offBoardCells: offBoardCells ?? this.offBoardCells,
    );
  }

}
// lib/pentoscope/pentoscope_provider.dart
// Provider Pentoscope - calqué sur pentomino_game_provider
// v2: Ajout du snap intelligent + fix cancelSelection

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';
import '../services/isometry_transforms.dart';
import '../services/shape_recognizer.dart';
import 'pentoscope_generator.dart';

// ============================================================================
// ÉTAT
// ============================================================================

/// Pièce placée sur le plateau Pentoscope
class PentoscopePlacedPiece {
  final Pento piece;
  final int positionIndex;
  final int gridX;
  final int gridY;

  const PentoscopePlacedPiece({
    required this.piece,
    required this.positionIndex,
    required this.gridX,
    required this.gridY,
  });

  PentoscopePlacedPiece copyWith({
    Pento? piece,
    int? positionIndex,
    int? gridX,
    int? gridY,
  }) {
    return PentoscopePlacedPiece(
      piece: piece ?? this.piece,
      positionIndex: positionIndex ?? this.positionIndex,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
    );
  }

  /// Coordonnées absolues des cellules occupées (normalisées)
  Iterable<Point> get absoluteCells sync* {
    final position = piece.positions[positionIndex];

    // Trouver le décalage minimum pour normaliser
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minLocalX;
      final localY = (cellNum - 1) ~/ 5 - minLocalY;
      yield Point(gridX + localX, gridY + localY);
    }
  }
}

/// État du jeu Pentoscope
class PentoscopeState {
  final PentoscopePuzzle? puzzle;
  final Plateau plateau;
  final List<Pento> availablePieces;
  final List<PentoscopePlacedPiece> placedPieces;

  // Sélection pièce du slider
  final Pento? selectedPiece;
  final int selectedPositionIndex;
  final Map<int, int> piecePositionIndices;

  // Sélection pièce placée
  final PentoscopePlacedPiece? selectedPlacedPiece;
  final Point? selectedCellInPiece; // Mastercase

  // Preview
  final int? previewX;
  final int? previewY;
  final bool isPreviewValid;
  final bool isSnapped; // Indique si la preview est "aimantée"

  // État du jeu
  final bool isComplete;
  final int isometryCount;
  final int translationCount;

  const PentoscopeState({
    this.puzzle,
    required this.plateau,
    this.availablePieces = const [],
    this.placedPieces = const [],
    this.selectedPiece,
    this.selectedPositionIndex = 0,
    this.piecePositionIndices = const {},
    this.selectedPlacedPiece,
    this.selectedCellInPiece,
    this.previewX,
    this.previewY,
    this.isPreviewValid = false,
    this.isSnapped = false,
    this.isComplete = false,
    this.isometryCount = 0,
    this.translationCount = 0,
  });

  factory PentoscopeState.initial() {
    return PentoscopeState(
      plateau: Plateau.allVisible(5, 5),
    );
  }

  int getPiecePositionIndex(int pieceId) {
    return piecePositionIndices[pieceId] ?? 0;
  }

  bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
    final position = piece.positions[positionIndex];

    // Trouver le décalage minimum pour normaliser la forme
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minLocalX; // Normalisé
      final localY = (cellNum - 1) ~/ 5 - minLocalY; // Normalisé
      final x = gridX + localX;
      final y = gridY + localY;

      if (x < 0 || x >= plateau.width || y < 0 || y >= plateau.height) {
        return false;
      }

      final cellValue = plateau.getCell(x, y);
      if (cellValue != 0) {
        return false;
      }
    }

    return true;
  }

  PentoscopeState copyWith({
    PentoscopePuzzle? puzzle,
    Plateau? plateau,
    List<Pento>? availablePieces,
    List<PentoscopePlacedPiece>? placedPieces,
    Pento? selectedPiece,
    bool clearSelectedPiece = false,
    int? selectedPositionIndex,
    Map<int, int>? piecePositionIndices,
    PentoscopePlacedPiece? selectedPlacedPiece,
    bool clearSelectedPlacedPiece = false,
    Point? selectedCellInPiece,
    bool clearSelectedCellInPiece = false,
    int? previewX,
    int? previewY,
    bool? isPreviewValid,
    bool? isSnapped,
    bool clearPreview = false,
    bool? isComplete,
    int? isometryCount,
    int? translationCount,
  }) {
    return PentoscopeState(
      puzzle: puzzle ?? this.puzzle,
      plateau: plateau ?? this.plateau,
      availablePieces: availablePieces ?? this.availablePieces,
      placedPieces: placedPieces ?? this.placedPieces,
      selectedPiece: clearSelectedPiece ? null : (selectedPiece ?? this.selectedPiece),
      selectedPositionIndex: selectedPositionIndex ?? this.selectedPositionIndex,
      piecePositionIndices: piecePositionIndices ?? this.piecePositionIndices,
      selectedPlacedPiece: clearSelectedPlacedPiece ? null : (selectedPlacedPiece ?? this.selectedPlacedPiece),
      selectedCellInPiece: clearSelectedCellInPiece ? null : (selectedCellInPiece ?? this.selectedCellInPiece),
      previewX: clearPreview ? null : (previewX ?? this.previewX),
      previewY: clearPreview ? null : (previewY ?? this.previewY),
      isPreviewValid: clearPreview ? false : (isPreviewValid ?? this.isPreviewValid),
      isSnapped: clearPreview ? false : (isSnapped ?? this.isSnapped),
      isComplete: isComplete ?? this.isComplete,
      isometryCount: isometryCount ?? this.isometryCount,
      translationCount: translationCount ?? this.translationCount,
    );
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

enum PentoscopeDifficulty { easy, random, hard }

class PentoscopeNotifier extends Notifier<PentoscopeState> {
  late final PentoscopeGenerator _generator;

  /// Rayon de recherche pour le snap (en cases)
  static const int _snapRadius = 2;

  @override
  PentoscopeState build() {
    _generator = PentoscopeGenerator();
    return PentoscopeState.initial();
  }

  // ==========================================================================
  // DÉMARRAGE
  // ==========================================================================

  void startPuzzle(PentoscopeSize size, {PentoscopeDifficulty difficulty = PentoscopeDifficulty.random}) {
    final puzzle = switch (difficulty) {
      PentoscopeDifficulty.easy => _generator.generateEasy(size),
      PentoscopeDifficulty.hard => _generator.generateHard(size),
      PentoscopeDifficulty.random => _generator.generate(size),
    };

    final pieces = puzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final plateau = Plateau.allVisible(size.width, size.height);

    state = PentoscopeState(
      puzzle: puzzle,
      plateau: plateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: {},
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
    );
  }

  // ==========================================================================
  // SÉLECTION PIÈCE (SLIDER)
  // ==========================================================================

  void selectPiece(Pento piece) {
    final positionIndex = state.getPiecePositionIndex(piece.id);
    final defaultCell = _calculateDefaultCell(piece, positionIndex);

    state = state.copyWith(
      selectedPiece: piece,
      selectedPositionIndex: positionIndex,
      clearSelectedPlacedPiece: true,
      selectedCellInPiece: defaultCell,
    );
  }

  /// Annule la sélection courante
  /// FIX: Reconstruit le plateau si une pièce placée était sélectionnée
  void cancelSelection() {
    // Si une pièce placée était sélectionnée, la remettre sur le plateau
    if (state.selectedPlacedPiece != null) {
      final newPlateau = _rebuildPlateau();
      state = state.copyWith(
        plateau: newPlateau,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        clearPreview: true,
      );
    } else {
      state = state.copyWith(
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        clearPreview: true,
      );
    }
  }

  /// Reconstruit le plateau à partir de toutes les pièces placées
  Plateau _rebuildPlateau() {
    final newPlateau = Plateau.allVisible(state.plateau.width, state.plateau.height);
    for (final p in state.placedPieces) {
      for (final cell in p.absoluteCells) {
        newPlateau.setCell(cell.x, cell.y, p.piece.id);
      }
    }
    return newPlateau;
  }

  void cycleToNextOrientation() {
    if (state.selectedPiece == null) return;

    final piece = state.selectedPiece!;
    final newIndex = (state.selectedPositionIndex + 1) % piece.numPositions;
    final newCell = _calculateDefaultCell(piece, newIndex);

    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = newIndex;

    state = state.copyWith(
      selectedPositionIndex: newIndex,
      piecePositionIndices: newIndices,
      selectedCellInPiece: newCell,
    );
  }

  // ==========================================================================
  // SÉLECTION PIÈCE PLACÉE (avec mastercase)
  // ==========================================================================

  void selectPlacedPiece(PentoscopePlacedPiece placed, int absoluteX, int absoluteY) {
    // Calculer la cellule locale cliquée (mastercase)
    final localX = absoluteX - placed.gridX;
    final localY = absoluteY - placed.gridY;

    // Retirer la pièce du plateau temporairement
    final newPlateau = Plateau.allVisible(state.plateau.width, state.plateau.height);
    for (final p in state.placedPieces) {
      if (p.piece.id == placed.piece.id) continue;
      for (final cell in p.absoluteCells) {
        newPlateau.setCell(cell.x, cell.y, p.piece.id);
      }
    }

    state = state.copyWith(
      plateau: newPlateau,
      selectedPiece: placed.piece,
      selectedPlacedPiece: placed,
      selectedPositionIndex: placed.positionIndex,
      selectedCellInPiece: Point(localX, localY),
      clearPreview: true,
    );
  }

  PentoscopePlacedPiece? getPlacedPieceAt(int x, int y) {
    for (final placed in state.placedPieces) {
      for (final cell in placed.absoluteCells) {
        if (cell.x == x && cell.y == y) {
          return placed;
        }
      }
    }
    return null;
  }

  // ==========================================================================
  // PREVIEW AVEC SNAP INTELLIGENT
  // ==========================================================================

  void updatePreview(int gridX, int gridY) {
    if (state.selectedPiece == null) {
      if (state.previewX != null || state.previewY != null) {
        state = state.copyWith(clearPreview: true);
      }
      return;
    }

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;

    // Calculer l'ancre en tenant compte de la mastercase
    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;
    }

    // 1. Vérifier la position exacte d'abord
    if (state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      _updatePreviewState(anchorX, anchorY, isValid: true, isSnapped: false);
      return;
    }

    // 2. Chercher la position valide la plus proche (snap)
    final snapped = _findNearestValidPosition(piece, positionIndex, anchorX, anchorY);

    if (snapped != null) {
      _updatePreviewState(snapped.x, snapped.y, isValid: true, isSnapped: true);
    } else {
      // Aucune position valide proche → preview rouge à la position du curseur
      _updatePreviewState(anchorX, anchorY, isValid: false, isSnapped: false);
    }
  }

  /// Cherche la position valide la plus proche dans un rayon donné
  /// Utilise la distance euclidienne pour trouver vraiment la plus proche
  Point? _findNearestValidPosition(Pento piece, int positionIndex, int anchorX, int anchorY) {
    Point? best;
    double bestDistanceSquared = double.infinity;

    for (int dx = -_snapRadius; dx <= _snapRadius; dx++) {
      for (int dy = -_snapRadius; dy <= _snapRadius; dy++) {
        if (dx == 0 && dy == 0) continue; // Position exacte déjà testée

        final testX = anchorX + dx;
        final testY = anchorY + dy;

        if (state.canPlacePiece(piece, positionIndex, testX, testY)) {
          // Distance euclidienne au carré (évite sqrt pour la perf)
          final distanceSquared = (dx * dx + dy * dy).toDouble();

          if (distanceSquared < bestDistanceSquared) {
            bestDistanceSquared = distanceSquared;
            best = Point(testX, testY);
          }
        }
      }
    }

    return best;
  }

  /// Met à jour l'état de la preview (évite les rebuilds inutiles)
  void _updatePreviewState(int x, int y, {required bool isValid, required bool isSnapped}) {
    if (state.previewX != x ||
        state.previewY != y ||
        state.isPreviewValid != isValid ||
        state.isSnapped != isSnapped) {
      state = state.copyWith(
        previewX: x,
        previewY: y,
        isPreviewValid: isValid,
        isSnapped: isSnapped,
      );
    }
  }

  void clearPreview() {
    state = state.copyWith(clearPreview: true);
  }

  // ==========================================================================
  // PLACEMENT
  // ==========================================================================

  bool tryPlacePiece(int gridX, int gridY) {
    if (state.selectedPiece == null) return false;

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;

    // Calculer l'ancre
    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;
    }

    // Vérifier position exacte
    bool canPlace = state.canPlacePiece(piece, positionIndex, anchorX, anchorY);

    // Si pas valide, essayer le snap
    if (!canPlace) {
      final snapped = _findNearestValidPosition(piece, positionIndex, anchorX, anchorY);
      if (snapped != null) {
        anchorX = snapped.x;
        anchorY = snapped.y;
        canPlace = true;
      }
    }

    if (!canPlace) {
      return false;
    }

    // Créer le nouveau plateau
    final newPlateau = Plateau.allVisible(state.plateau.width, state.plateau.height);

    // Copier les pièces existantes (sauf celle qu'on déplace si c'est une pièce placée)
    for (final p in state.placedPieces) {
      if (state.selectedPlacedPiece != null && p.piece.id == state.selectedPlacedPiece!.piece.id) {
        continue;
      }
      for (final cell in p.absoluteCells) {
        newPlateau.setCell(cell.x, cell.y, p.piece.id);
      }
    }

    // Placer la nouvelle pièce
    final newPlaced = PentoscopePlacedPiece(
      piece: piece,
      positionIndex: positionIndex,
      gridX: anchorX,
      gridY: anchorY,
    );

    for (final cell in newPlaced.absoluteCells) {
      newPlateau.setCell(cell.x, cell.y, piece.id);
    }

    // Mettre à jour les listes
    List<PentoscopePlacedPiece> newPlacedPieces;
    List<Pento> newAvailable;

    if (state.selectedPlacedPiece != null) {
      // Déplacement d'une pièce existante
      newPlacedPieces = state.placedPieces
          .map((p) => p.piece.id == piece.id ? newPlaced : p)
          .toList();
      newAvailable = state.availablePieces;
    } else {
      // Nouvelle pièce
      newPlacedPieces = [...state.placedPieces, newPlaced];
      newAvailable = state.availablePieces.where((p) => p.id != piece.id).toList();
    }

    final isComplete = newPlacedPieces.length == (state.puzzle?.size.numPieces ?? 0);

    // Compter les translations (déplacement d'une pièce déjà placée)
    final newTranslationCount = state.selectedPlacedPiece != null
        ? state.translationCount + 1
        : state.translationCount;

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlacedPieces,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      clearPreview: true,
      isComplete: isComplete,
      translationCount: newTranslationCount,
    );

    return true;
  }

  void removePlacedPiece(PentoscopePlacedPiece placed) {
    final newPlateau = Plateau.allVisible(state.plateau.width, state.plateau.height);

    for (final p in state.placedPieces) {
      if (p.piece.id == placed.piece.id) continue;
      for (final cell in p.absoluteCells) {
        newPlateau.setCell(cell.x, cell.y, p.piece.id);
      }
    }

    final newPlaced = state.placedPieces.where((p) => p.piece.id != placed.piece.id).toList();
    final newAvailable = [...state.availablePieces, placed.piece];

    state = state.copyWith(
      plateau: newPlateau,
      placedPieces: newPlaced,
      availablePieces: newAvailable,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      isComplete: false,
    );
  }

  // ==========================================================================
  // ISOMÉTRIES (fonctionne sur pièce slider ET pièce placée)
  // ==========================================================================

  void applyIsometryRotation() {
    if (state.selectedPlacedPiece != null) {
      _applyPlacedPieceIsometry((coords, cx, cy) => rotateAroundPoint(coords, cx, cy, 1));
    } else if (state.selectedPiece != null) {
      _applySliderPieceIsometry((coords, cx, cy) => rotateAroundPoint(coords, cx, cy, 1));
    }
  }

  void applyIsometryRotationCW() {
    if (state.selectedPlacedPiece != null) {
      _applyPlacedPieceIsometry((coords, cx, cy) => rotateAroundPoint(coords, cx, cy, 3));
    } else if (state.selectedPiece != null) {
      _applySliderPieceIsometry((coords, cx, cy) => rotateAroundPoint(coords, cx, cy, 3));
    }
  }

  void applyIsometrySymmetryH() {
    if (state.selectedPlacedPiece != null) {
      _applyPlacedPieceSymmetryH();
    } else if (state.selectedPiece != null) {
      _applySliderPieceSymmetryH();
    }
  }

  void applyIsometrySymmetryV() {
    if (state.selectedPlacedPiece != null) {
      _applyPlacedPieceSymmetryV();
    } else if (state.selectedPiece != null) {
      _applySliderPieceSymmetryV();
    }
  }

  void _applyPlacedPieceIsometry(
      List<List<int>> Function(List<List<int>>, int, int) transform,
      ) {
    final selectedPiece = state.selectedPlacedPiece!;

    // 1. Extraire les coordonnées absolues
    final currentCoords = _extractAbsoluteCoords(selectedPiece);

    // 2. Centre de rotation = mastercase
    final refX = (state.selectedCellInPiece?.x ?? 0);
    final refY = (state.selectedCellInPiece?.y ?? 0);
    final centerX = selectedPiece.gridX + refX;
    final centerY = selectedPiece.gridY + refY;

    // 3. Appliquer la transformation
    final transformedCoords = transform(currentCoords, centerX, centerY);

    // 4. Reconnaître la forme
    final match = recognizeShape(transformedCoords);
    if (match == null) return;

    // 5. Vérifier placement valide
    if (!_canPlacePieceAt(match, selectedPiece)) return;

    // 6. Créer la pièce transformée
    final transformedPiece = PentoscopePlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
    );

    // 7. Nouvelle mastercase
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

    // 8. Mettre à jour l'état
    state = state.copyWith(
      selectedPlacedPiece: transformedPiece,
      selectedPositionIndex: match.positionIndex,
      selectedCellInPiece: newSelectedCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  void _applySliderPieceIsometry(
      List<List<int>> Function(List<List<int>>, int, int) transform,
      ) {
    final piece = state.selectedPiece!;
    final currentIndex = state.selectedPositionIndex;

    // 1. Coordonnées actuelles
    final currentCoords = piece.cartesianCoords[currentIndex];

    // 2. Centre de rotation
    final refX = (state.selectedCellInPiece?.x ?? 0);
    final refY = (state.selectedCellInPiece?.y ?? 0);

    // 3. Appliquer la transformation
    final transformedCoords = transform(currentCoords, refX, refY);

    // 4. Reconnaître
    final match = recognizeShape(transformedCoords);
    if (match == null || match.piece.id != piece.id) return;

    // 5. Sauvegarder
    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = match.positionIndex;

    // 6. Recalculer la mastercase pour la nouvelle orientation
    final newCell = _calculateDefaultCell(piece, match.positionIndex);

    state = state.copyWith(
      selectedPositionIndex: match.positionIndex,
      piecePositionIndices: newIndices,
      selectedCellInPiece: newCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  // Symétrie H sur pièce placée (flipVertical = inverse gauche/droite)
  void _applyPlacedPieceSymmetryH() {
    final selectedPiece = state.selectedPlacedPiece!;
    final currentCoords = _extractAbsoluteCoords(selectedPiece);

    final refX = (state.selectedCellInPiece?.x ?? 0);
    final refY = (state.selectedCellInPiece?.y ?? 0);
    final axisX = selectedPiece.gridX + refX;

    final flippedCoords = flipVertical(currentCoords, axisX);
    final match = recognizeShape(flippedCoords);
    if (match == null) return;
    if (!_canPlacePieceAt(match, selectedPiece)) return;

    final transformedPiece = PentoscopePlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
    );

    final centerX = axisX;
    final centerY = selectedPiece.gridY + refY;
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

    state = state.copyWith(
      selectedPlacedPiece: transformedPiece,
      selectedPositionIndex: match.positionIndex,
      selectedCellInPiece: newSelectedCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  // Symétrie V sur pièce placée (flipHorizontal = inverse haut/bas)
  void _applyPlacedPieceSymmetryV() {
    final selectedPiece = state.selectedPlacedPiece!;
    final currentCoords = _extractAbsoluteCoords(selectedPiece);

    final refX = (state.selectedCellInPiece?.x ?? 0);
    final refY = (state.selectedCellInPiece?.y ?? 0);
    final axisY = selectedPiece.gridY + refY;

    final flippedCoords = flipHorizontal(currentCoords, axisY);
    final match = recognizeShape(flippedCoords);
    if (match == null) return;
    if (!_canPlacePieceAt(match, selectedPiece)) return;

    final transformedPiece = PentoscopePlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
    );

    final centerX = selectedPiece.gridX + refX;
    final centerY = axisY;
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

    state = state.copyWith(
      selectedPlacedPiece: transformedPiece,
      selectedPositionIndex: match.positionIndex,
      selectedCellInPiece: newSelectedCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  // Symétrie H sur pièce slider
  void _applySliderPieceSymmetryH() {
    final piece = state.selectedPiece!;
    final currentIndex = state.selectedPositionIndex;
    final currentCoords = piece.cartesianCoords[currentIndex];

    final refX = (state.selectedCellInPiece?.x ?? 0);
    final flippedCoords = flipVertical(currentCoords, refX);

    final match = recognizeShape(flippedCoords);
    if (match == null || match.piece.id != piece.id) return;

    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = match.positionIndex;

    // Recalculer la mastercase
    final newCell = _calculateDefaultCell(piece, match.positionIndex);

    state = state.copyWith(
      selectedPositionIndex: match.positionIndex,
      piecePositionIndices: newIndices,
      selectedCellInPiece: newCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  // Symétrie V sur pièce slider
  void _applySliderPieceSymmetryV() {
    final piece = state.selectedPiece!;
    final currentIndex = state.selectedPositionIndex;
    final currentCoords = piece.cartesianCoords[currentIndex];

    final refY = (state.selectedCellInPiece?.y ?? 0);
    final flippedCoords = flipHorizontal(currentCoords, refY);

    final match = recognizeShape(flippedCoords);
    if (match == null || match.piece.id != piece.id) return;

    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = match.positionIndex;

    // Recalculer la mastercase
    final newCell = _calculateDefaultCell(piece, match.positionIndex);

    state = state.copyWith(
      selectedPositionIndex: match.positionIndex,
      piecePositionIndices: newIndices,
      selectedCellInPiece: newCell,
      isometryCount: state.isometryCount + 1,
    );
  }

  /// Helper: calcule la mastercase par défaut (première cellule normalisée)
  Point? _calculateDefaultCell(Pento piece, int positionIndex) {
    final position = piece.positions[positionIndex];
    if (position.isEmpty) return null;

    int minX = 5, minY = 5;
    for (final cellNum in position) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
    }
    final firstCellNum = position[0];
    final rawX = (firstCellNum - 1) % 5;
    final rawY = (firstCellNum - 1) ~/ 5;
    return Point(rawX - minX, rawY - minY);
  }

  List<List<int>> _extractAbsoluteCoords(PentoscopePlacedPiece piece) {
    final position = piece.piece.positions[piece.positionIndex];

    // Normaliser
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    return position.map((cellNum) {
      final localX = (cellNum - 1) % 5 - minLocalX;
      final localY = (cellNum - 1) ~/ 5 - minLocalY;
      return [piece.gridX + localX, piece.gridY + localY];
    }).toList();
  }

  bool _canPlacePieceAt(ShapeMatch match, PentoscopePlacedPiece? excludePiece) {
    final position = match.piece.positions[match.positionIndex];

    // Normaliser les coordonnées
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minLocalX;
      final localY = (cellNum - 1) ~/ 5 - minLocalY;
      final absX = match.gridX + localX;
      final absY = match.gridY + localY;

      if (!state.plateau.isInBounds(absX, absY)) {
        return false;
      }

      final cell = state.plateau.getCell(absX, absY);
      if (cell != 0 && (excludePiece == null || cell != excludePiece.piece.id)) {
        return false;
      }
    }

    return true;
  }

  // ==========================================================================
  // RESET - génère un nouveau puzzle
  // ==========================================================================

  void reset() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;

    // Générer un nouveau puzzle avec la même taille
    final newPuzzle = _generator.generate(puzzle.size);

    final pieces = newPuzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final plateau = Plateau.allVisible(puzzle.size.width, puzzle.size.height);

    state = PentoscopeState(
      puzzle: newPuzzle,
      plateau: plateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: {},
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
    );
  }
}

final pentoscopeProvider = NotifierProvider<PentoscopeNotifier, PentoscopeState>(
  PentoscopeNotifier.new,
);
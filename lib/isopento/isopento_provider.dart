// lib/isopento/isopento_provider.dart
// Modified: 2512091015
// MODIFIÉ: Ajout de solutionPlateau pour afficher la solution en semi-transparent

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';
import '../services/isometry_transforms.dart';
import '../services/shape_recognizer.dart';
import 'isopento_generator.dart';
import 'isopento_solver.dart';

// ============================================================================
// ÉTAT
// ============================================================================

/// Pièce placée sur le plateau Isopento
class IsopentoPlacedPiece {
  final Pento piece;
  final int positionIndex;
  final int gridX;
  final int gridY;
  final int isometriesUsed;

  const IsopentoPlacedPiece({
    required this.piece,
    required this.positionIndex,
    required this.gridX,
    required this.gridY,
    required this.isometriesUsed,
  });

  IsopentoPlacedPiece copyWith({
    Pento? piece,
    int? positionIndex,
    int? gridX,
    int? gridY,
    int? isometriesUsed,
  }) {
    return IsopentoPlacedPiece(
      piece: piece ?? this.piece,
      positionIndex: positionIndex ?? this.positionIndex,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      isometriesUsed: isometriesUsed ?? this.isometriesUsed,
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

/// État du jeu Isopento
class IsopentoState {
  final IsopentoPuzzle? puzzle;
  final Plateau plateau;
  final Plateau solutionPlateau;
  final List<Pento> availablePieces;
  final List<IsopentoPlacedPiece> placedPieces;

// Sélection pièce du slider
  final Pento? selectedPiece;
  final int selectedPositionIndex;
  final Map<int, int> piecePositionIndices;

// Sélection pièce placée
  final IsopentoPlacedPiece? selectedPlacedPiece;
  final Point? selectedCellInPiece; // Mastercase

// Preview
  final int? previewX;
  final int? previewY;
  final bool isPreviewValid;

// État du jeu
  final bool isComplete;
  final int isometryCount;
  final int translationCount;
  final bool isSnapped;

  const IsopentoState({
    this.puzzle,
    required this.plateau,
    required this.solutionPlateau,
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
    this.isComplete = false,
    this.isometryCount = 0,
    this.translationCount = 0,
    this.isSnapped = false,
  });

  factory IsopentoState.initial() {
    final empty = Plateau.allVisible(5, 5);
    return IsopentoState(
      plateau: empty,
      solutionPlateau: empty,
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

  IsopentoState copyWith({
    IsopentoPuzzle? puzzle,
    Plateau? plateau,
    Plateau? solutionPlateau,
    List<Pento>? availablePieces,
    List<IsopentoPlacedPiece>? placedPieces,
    Pento? selectedPiece,
    bool clearSelectedPiece = false,
    int? selectedPositionIndex,
    Map<int, int>? piecePositionIndices,
    IsopentoPlacedPiece? selectedPlacedPiece,
    bool clearSelectedPlacedPiece = false,
    Point? selectedCellInPiece,
    bool clearSelectedCellInPiece = false,
    int? previewX,
    int? previewY,
    bool? isPreviewValid,
    bool clearPreview = false,
    bool? isComplete,
    int? isometryCount,
    int? translationCount,
    bool? isSnapped,
  }) {
    return IsopentoState(
      puzzle: puzzle ?? this.puzzle,
      plateau: plateau ?? this.plateau,
      solutionPlateau: solutionPlateau ?? this.solutionPlateau,
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
      isComplete: isComplete ?? this.isComplete,
      isometryCount: isometryCount ?? this.isometryCount,
      translationCount: translationCount ?? this.translationCount,
      isSnapped: isSnapped ?? this.isSnapped,
    );
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

enum IsopentoDifficulty { easy, random, hard }

class IsopentoNotifier extends Notifier<IsopentoState> {
  late final IsopentoGenerator _generator;

  @override
  IsopentoState build() {
    _generator = IsopentoGenerator();
    return IsopentoState.initial();
  }

// ==========================================================================
// DÉMARRAGE
// ==========================================================================

  void startPuzzle(IsopentoSize size, {IsopentoDifficulty difficulty = IsopentoDifficulty.random}) {
    final puzzle = switch (difficulty) {
      IsopentoDifficulty.easy => _generator.generateEasy(size),
      IsopentoDifficulty.hard => _generator.generateHard(size),
      IsopentoDifficulty.random => _generator.generate(size),
    };

    final pieces = puzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

// ✅ GÉNÉRER LA SOLUTION AVEC LE SOLVER
    final solutionPlateau = _generateSolutionPlateau(size, pieces);

// Plateau VIDE pour le joueur
    final emptyPlateau = Plateau.allVisible(size.width, size.height);

    state = IsopentoState(
      puzzle: puzzle,
      plateau: emptyPlateau,
      solutionPlateau: solutionPlateau,
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

// ==========================================================================
// CORRECTION 1: cancelSelection - reconstruire le plateau
// ==========================================================================

  void cancelSelection() {
// Si on avait une pièce placée sélectionnée, il faut la remettre sur le plateau
    if (state.selectedPlacedPiece != null) {
// Reconstruire le plateau avec TOUTES les pièces y compris celle sélectionnée
      final newPlateau = Plateau.allVisible(state.plateau.width, state.plateau.height);
      for (final p in state.placedPieces) {
        for (final cell in p.absoluteCells) {
          newPlateau.setCell(cell.x, cell.y, p.piece.id);
        }
      }

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

  void selectPlacedPiece(IsopentoPlacedPiece placed, int absoluteX, int absoluteY) {
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

  IsopentoPlacedPiece? getPlacedPieceAt(int x, int y) {
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
// PREVIEW
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

    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;
    }

    final isValid = state.canPlacePiece(piece, positionIndex, anchorX, anchorY);

    if (state.previewX != anchorX ||
        state.previewY != anchorY ||
        state.isPreviewValid != isValid) {
      state = state.copyWith(
        previewX: anchorX,
        previewY: anchorY,
        isPreviewValid: isValid,
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

    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;
    }

    if (!state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
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
    final newPlaced = IsopentoPlacedPiece(
      piece: piece,
      positionIndex: positionIndex,
      gridX: anchorX,
      gridY: anchorY,
      isometriesUsed: state.isometryCount,  // ← SAUVEGARDER les isométries
    );

    for (final cell in newPlaced.absoluteCells) {
      newPlateau.setCell(cell.x, cell.y, piece.id);
    }

// Mettre à jour les listes
    List<IsopentoPlacedPiece> newPlacedPieces;
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
      isometryCount: 0,  // ← RÉINITIALISER pour la prochaine pièce
    );

    return true;
  }

  void removePlacedPiece(IsopentoPlacedPiece placed) {
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

// ==========================================================================
// CORRECTION 2: _applyPlacedPieceIsometry - sync placedPieces
// ==========================================================================

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
    final transformedPiece = IsopentoPlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
      isometriesUsed: selectedPiece.isometriesUsed,  // ← Garder la même
    );

// 7. Nouvelle mastercase
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

// 8. CORRECTION: Mettre à jour placedPieces aussi !
    final newPlacedPieces = state.placedPieces
        .map((p) => p.piece.id == selectedPiece.piece.id ? transformedPiece : p)
        .toList();

// 9. Mettre à jour l'état
    state = state.copyWith(
      placedPieces: newPlacedPieces,
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

// ==========================================================================
// CORRECTION 3: _applyPlacedPieceSymmetryH - sync placedPieces
// ==========================================================================

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

    final transformedPiece = IsopentoPlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
      isometriesUsed: selectedPiece.isometriesUsed,  // ← Garder la même
    );

    final centerX = axisX;
    final centerY = selectedPiece.gridY + refY;
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

// CORRECTION: Mettre à jour placedPieces aussi !
    final newPlacedPieces = state.placedPieces
        .map((p) => p.piece.id == selectedPiece.piece.id ? transformedPiece : p)
        .toList();

    state = state.copyWith(
      placedPieces: newPlacedPieces,
      selectedPlacedPiece: transformedPiece,
      selectedPositionIndex: match.positionIndex,
      selectedCellInPiece: newSelectedCell,
      isometryCount: state.isometryCount + 1,
    );
  }

// ==========================================================================
// CORRECTION 4: _applyPlacedPieceSymmetryV - sync placedPieces
// ==========================================================================

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

    final transformedPiece = IsopentoPlacedPiece(
      piece: match.piece,
      positionIndex: match.positionIndex,
      gridX: match.gridX,
      gridY: match.gridY,
      isometriesUsed: selectedPiece.isometriesUsed,  // ← Garder la même
    );

    final centerX = selectedPiece.gridX + refX;
    final centerY = axisY;
    final newSelectedCell = Point(centerX - match.gridX, centerY - match.gridY);

// CORRECTION: Mettre à jour placedPieces aussi !
    final newPlacedPieces = state.placedPieces
        .map((p) => p.piece.id == selectedPiece.piece.id ? transformedPiece : p)
        .toList();

    state = state.copyWith(
      placedPieces: newPlacedPieces,
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

  List<List<int>> _extractAbsoluteCoords(IsopentoPlacedPiece piece) {
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

  bool _canPlacePieceAt(ShapeMatch match, IsopentoPlacedPiece? excludePiece) {
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
// SOLUTION GENERATOR - Génère une solution avec le solver
// ==========================================================================

  /// Génère un plateau avec une solution trouvée par le solver
  Plateau _generateSolutionPlateau(IsopentoSize size, List<Pento> pieces) {
    final solver = IsopentoSolver(
      width: size.width,
      height: size.height,
      pieces: pieces,
      maxSeconds: 5,
    );

    final solution = solver.findSolution();

    // Créer le plateau avec la solution
    final plateau = Plateau.allVisible(size.width, size.height);

    if (solution != null) {
      for (final placement in solution) {
        final piece = pieces.firstWhere((p) => p.id == placement.pieceId);
        final shape = piece.positions[placement.orientation];

        // Placer la pièce sur le plateau
        final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
        final shapeAnchorX = (minShapeCell - 1) % 5;
        final shapeAnchorY = (minShapeCell - 1) ~/ 5;

        final offsetX = (placement.offsetX - shapeAnchorX).toInt();
        final offsetY = (placement.offsetY - shapeAnchorY).toInt();

        for (final shapeCell in shape) {
          final sx = (shapeCell - 1) % 5;
          final sy = (shapeCell - 1) ~/ 5;
          plateau.setCell(sx + offsetX, sy + offsetY, placement.pieceId);
        }
      }
    }

    return plateau;
  }

// ==========================================================================
// CALCUL MINIMAL ISOMÉTRIES - BFS pour score
// ==========================================================================

  /// Calcule le nombre MINIMAL d'isométries pour placer une pièce
  /// en cherchant le chemin optimal depuis orientation initiale
  int calculateMinimalIsometries(Pento piece, int targetPositionIndex) {
    final initialPosition = 0;  // Orientation initiale

    if (initialPosition == targetPositionIndex) {
      return 0;  // Pas d'isométries nécessaires
    }

    // Queue BFS
    final queue = <(int position, int steps)>[];
    final visited = <int>{initialPosition};

    queue.add((initialPosition, 0));

    while (queue.isNotEmpty) {
      final (currentPos, steps) = queue.removeAt(0);

      // Essayer les 4 isométries
      for (int i = 1; i <= 4; i++) {
        int nextPos = currentPos;

        switch (i) {
          case 1:  // Rotation CCW
            nextPos = (currentPos + 1) % piece.numPositions;
          case 2:  // Rotation CW
            nextPos = (currentPos + piece.numPositions - 1) % piece.numPositions;
          case 3:  // Symétrie H
            nextPos = _findSymmetryHPosition(piece, currentPos) ?? currentPos;
          case 4:  // Symétrie V
            nextPos = _findSymmetryVPosition(piece, currentPos) ?? currentPos;
        }

        if (nextPos == targetPositionIndex) {
          return steps + 1;
        }

        if (!visited.contains(nextPos)) {
          visited.add(nextPos);
          queue.add((nextPos, steps + 1));
        }
      }
    }

    return piece.numPositions;
  }

  /// Helper pour trouver symétrie H
  int? _findSymmetryHPosition(Pento piece, int currentPos) {
    try {
      final currentCoords = piece.cartesianCoords[currentPos];
      final flipped = flipVertical(currentCoords, 0);
      final match = recognizeShape(flipped);

      if (match?.piece.id == piece.id) {
        return match?.positionIndex;
      }
    } catch (e) {
      // Symétrie non trouvée
    }
    return null;
  }

  /// Helper pour trouver symétrie V
  int? _findSymmetryVPosition(Pento piece, int currentPos) {
    try {
      final currentCoords = piece.cartesianCoords[currentPos];
      final flipped = flipHorizontal(currentCoords, 0);
      final match = recognizeShape(flipped);

      if (match?.piece.id == piece.id) {
        return match?.positionIndex;
      }
    } catch (e) {
      // Symétrie non trouvée
    }
    return null;
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

// Générer la solution avec le solver
    final newSolutionPlateau = _generateSolutionPlateau(newPuzzle.size, pieces);

// Plateau VIDE pour le joueur
    final emptyPlateau = Plateau.allVisible(newPuzzle.size.width, newPuzzle.size.height);

    state = IsopentoState(
      puzzle: newPuzzle,
      plateau: emptyPlateau,
      solutionPlateau: newSolutionPlateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: {},
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
    );
  }
}

final isopentoProvider = NotifierProvider<IsopentoNotifier, IsopentoState>(
  IsopentoNotifier.new,
);
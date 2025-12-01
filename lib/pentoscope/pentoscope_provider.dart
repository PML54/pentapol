// lib/pentoscope/pentoscope_provider.dart
// Provider Riverpod dédié au mode Pentoscope - INDÉPENDANT du mode 6×10

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pentominos.dart';
import 'pentoscope_generator.dart';

/// État du jeu Pentoscope
class PentoscopeState {
  final PentoscopePuzzle? puzzle;
  final List<Pento> pieces;
  final List<List<int>> board;
  final List<PlacedPiece> placedPieces;
  final int? selectedPieceIndex;
  final int selectedOrientation;
  final int? selectedPlacedPieceId;
  final int? previewX;
  final int? previewY;
  final bool isPreviewValid;
  final bool isComplete;
  final int moveCount;

  const PentoscopeState({
    this.puzzle,
    this.pieces = const [],
    this.board = const [],
    this.placedPieces = const [],
    this.selectedPieceIndex,
    this.selectedOrientation = 0,
    this.selectedPlacedPieceId,
    this.previewX,
    this.previewY,
    this.isPreviewValid = false,
    this.isComplete = false,
    this.moveCount = 0,
  });

  PentoscopeState copyWith({
    PentoscopePuzzle? puzzle,
    List<Pento>? pieces,
    List<List<int>>? board,
    List<PlacedPiece>? placedPieces,
    int? selectedPieceIndex,
    bool clearSelectedPiece = false,
    int? selectedOrientation,
    int? selectedPlacedPieceId,
    bool clearSelectedPlacedPiece = false,
    int? previewX,
    bool clearPreviewX = false,
    int? previewY,
    bool clearPreviewY = false,
    bool? isPreviewValid,
    bool? isComplete,
    int? moveCount,
  }) {
    return PentoscopeState(
      puzzle: puzzle ?? this.puzzle,
      pieces: pieces ?? this.pieces,
      board: board ?? this.board,
      placedPieces: placedPieces ?? this.placedPieces,
      selectedPieceIndex: clearSelectedPiece ? null : (selectedPieceIndex ?? this.selectedPieceIndex),
      selectedOrientation: selectedOrientation ?? this.selectedOrientation,
      selectedPlacedPieceId: clearSelectedPlacedPiece ? null : (selectedPlacedPieceId ?? this.selectedPlacedPieceId),
      previewX: clearPreviewX ? null : (previewX ?? this.previewX),
      previewY: clearPreviewY ? null : (previewY ?? this.previewY),
      isPreviewValid: isPreviewValid ?? this.isPreviewValid,
      isComplete: isComplete ?? this.isComplete,
      moveCount: moveCount ?? this.moveCount,
    );
  }

  /// Pièces non encore placées
  List<Pento> get availablePieces {
    final placedIds = placedPieces.map((p) => p.pieceId).toSet();
    return pieces.where((p) => !placedIds.contains(p.id)).toList();
  }

  /// Pièce actuellement sélectionnée (dans le slider)
  Pento? get selectedPiece {
    if (selectedPieceIndex == null) return null;
    final available = availablePieces;
    if (selectedPieceIndex! < 0 || selectedPieceIndex! >= available.length) return null;
    return available[selectedPieceIndex!];
  }

  /// Pièce placée actuellement sélectionnée
  PlacedPiece? get selectedPlacedPiece {
    if (selectedPlacedPieceId == null) return null;
    try {
      return placedPieces.firstWhere((p) => p.pieceId == selectedPlacedPieceId);
    } catch (_) {
      return null;
    }
  }

  /// Mode isométries actif
  bool get isIsometriesMode => selectedPlacedPieceId != null;
}

/// Pièce placée sur le plateau
class PlacedPiece {
  final int pieceId;
  final int orientation;
  final int gridX;
  final int gridY;
  final List<(int, int)> cells;

  const PlacedPiece({
    required this.pieceId,
    required this.orientation,
    required this.gridX,
    required this.gridY,
    required this.cells,
  });

  PlacedPiece copyWith({
    int? pieceId,
    int? orientation,
    int? gridX,
    int? gridY,
    List<(int, int)>? cells,
  }) {
    return PlacedPiece(
      pieceId: pieceId ?? this.pieceId,
      orientation: orientation ?? this.orientation,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      cells: cells ?? this.cells,
    );
  }
}

/// Difficulté du puzzle
enum PentoscopeDifficulty { easy, random, hard }

/// Provider Pentoscope (Riverpod 2.x)
class PentoscopeNotifier extends Notifier<PentoscopeState> {
  late final PentoscopeGenerator _generator;

  @override
  PentoscopeState build() {
    _generator = PentoscopeGenerator();
    return const PentoscopeState();
  }

  /// Démarre un nouveau puzzle
  void startPuzzle(PentoscopeSize size, {PentoscopeDifficulty difficulty = PentoscopeDifficulty.random}) {
    final puzzle = switch (difficulty) {
      PentoscopeDifficulty.easy => _generator.generateEasy(size),
      PentoscopeDifficulty.hard => _generator.generateHard(size),
      PentoscopeDifficulty.random => _generator.generate(size),
    };

    final pieces = puzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final board = List.generate(
      size.height,
          (_) => List.filled(size.width, 0),
    );

    state = PentoscopeState(
      puzzle: puzzle,
      pieces: pieces,
      board: board,
      placedPieces: [],
      selectedPieceIndex: null,
      selectedOrientation: 0,
      selectedPlacedPieceId: null,
      previewX: null,
      previewY: null,
      isPreviewValid: false,
      isComplete: false,
      moveCount: 0,
    );
  }

  // ===========================================================================
  // SÉLECTION PIÈCE (SLIDER)
  // ===========================================================================

  void selectPiece(int index) {
    if (index < 0 || index >= state.availablePieces.length) return;
    state = state.copyWith(
      selectedPieceIndex: index,
      selectedOrientation: 0,
      clearSelectedPlacedPiece: true,
    );
  }

  void deselectPiece() {
    state = state.copyWith(
      clearSelectedPiece: true,
      selectedOrientation: 0,
      clearPreviewX: true,
      clearPreviewY: true,
      isPreviewValid: false,
    );
  }

  void cycleOrientation() {
    final piece = state.selectedPiece;
    if (piece == null) return;

    final newOrientation = (state.selectedOrientation + 1) % piece.numPositions;
    state = state.copyWith(selectedOrientation: newOrientation);

    // Recalculer la validité du preview
    if (state.previewX != null && state.previewY != null) {
      updatePreview(state.previewX!, state.previewY!);
    }
  }

  // ===========================================================================
  // SÉLECTION PIÈCE PLACÉE (ISOMÉTRIES)
  // ===========================================================================

  void selectPlacedPiece(int pieceId) {
    final placed = state.placedPieces.where((p) => p.pieceId == pieceId).firstOrNull;
    if (placed == null) return;

    state = state.copyWith(
      selectedPlacedPieceId: pieceId,
      selectedOrientation: placed.orientation,
      clearSelectedPiece: true,
    );
  }

  void deselectPlacedPiece() {
    state = state.copyWith(
      clearSelectedPlacedPiece: true,
    );
  }

  // ===========================================================================
  // PREVIEW
  // ===========================================================================

  void updatePreview(int x, int y) {
    final piece = state.selectedPiece;
    final puzzle = state.puzzle;
    if (piece == null || puzzle == null) return;

    final shape = piece.positions[state.selectedOrientation];
    final cells = _calculateCells(shape, x, y, puzzle.size.width, puzzle.size.height);
    final isValid = cells != null && _areCellsFree(cells);

    state = state.copyWith(
      previewX: x,
      previewY: y,
      isPreviewValid: isValid,
    );
  }

  void clearPreview() {
    state = state.copyWith(
      clearPreviewX: true,
      clearPreviewY: true,
      isPreviewValid: false,
    );
  }

  // ===========================================================================
  // PLACEMENT
  // ===========================================================================

  bool tryPlacePiece(int x, int y) {
    final piece = state.selectedPiece;
    final puzzle = state.puzzle;
    if (piece == null || puzzle == null) return false;

    final shape = piece.positions[state.selectedOrientation];
    final cells = _calculateCells(shape, x, y, puzzle.size.width, puzzle.size.height);

    if (cells == null || !_areCellsFree(cells)) return false;

    // Placer la pièce
    final newBoard = state.board.map((row) => List<int>.from(row)).toList();
    for (final (cx, cy) in cells) {
      newBoard[cy][cx] = piece.id;
    }

    final newPlacedPieces = [
      ...state.placedPieces,
      PlacedPiece(
        pieceId: piece.id,
        orientation: state.selectedOrientation,
        gridX: x,
        gridY: y,
        cells: cells,
      ),
    ];

    final isComplete = newPlacedPieces.length == state.pieces.length;

    state = state.copyWith(
      board: newBoard,
      placedPieces: newPlacedPieces,
      clearSelectedPiece: true,
      selectedOrientation: 0,
      clearPreviewX: true,
      clearPreviewY: true,
      isPreviewValid: false,
      isComplete: isComplete,
      moveCount: state.moveCount + 1,
    );

    return true;
  }

  void removePiece(int pieceId) {
    final placedIndex = state.placedPieces.indexWhere((p) => p.pieceId == pieceId);
    if (placedIndex == -1) return;

    final placed = state.placedPieces[placedIndex];

    final newBoard = state.board.map((row) => List<int>.from(row)).toList();
    for (final (cx, cy) in placed.cells) {
      newBoard[cy][cx] = 0;
    }

    final newPlacedPieces = [...state.placedPieces]..removeAt(placedIndex);

    state = state.copyWith(
      board: newBoard,
      placedPieces: newPlacedPieces,
      clearSelectedPlacedPiece: true,
      isComplete: false,
    );
  }

  // ===========================================================================
  // ISOMÉTRIES
  // ===========================================================================

  void applyIsometryRotation() {
    _applyIsometry((piece, currentOrientation) {
      return piece.findRotation90(currentOrientation);
    });
  }

  void applyIsometryRotationCW() {
    // Rotation horaire = 3 rotations anti-horaires
    _applyIsometry((piece, currentOrientation) {
      int newOrientation = currentOrientation;
      for (int i = 0; i < 3; i++) {
        final next = piece.findRotation90(newOrientation);
        if (next == -1) return -1;
        newOrientation = next;
      }
      return newOrientation;
    });
  }

  void applyIsometrySymmetryH() {
    _applyIsometry((piece, currentOrientation) {
      return piece.findSymmetryH(currentOrientation);
    });
  }

  void applyIsometrySymmetryV() {
    _applyIsometry((piece, currentOrientation) {
      return piece.findSymmetryV(currentOrientation);
    });
  }

  void _applyIsometry(int Function(Pento piece, int currentOrientation) findNewOrientation) {
    final placedPieceId = state.selectedPlacedPieceId;
    if (placedPieceId == null) return;

    final placedIndex = state.placedPieces.indexWhere((p) => p.pieceId == placedPieceId);
    if (placedIndex == -1) return;

    final placed = state.placedPieces[placedIndex];
    final piece = state.pieces.firstWhere((p) => p.id == placedPieceId);
    final puzzle = state.puzzle;
    if (puzzle == null) return;

    // Trouver la nouvelle orientation
    final newOrientation = findNewOrientation(piece, placed.orientation);
    if (newOrientation == -1) return;

    // Calculer les nouvelles cellules
    final newShape = piece.positions[newOrientation];
    final newCells = _calculateCells(newShape, placed.gridX, placed.gridY, puzzle.size.width, puzzle.size.height);
    if (newCells == null) return;

    // Vérifier que les nouvelles cellules sont libres (sauf celles de la pièce actuelle)
    final currentCellsSet = placed.cells.toSet();
    for (final (cx, cy) in newCells) {
      if (!currentCellsSet.contains((cx, cy)) && state.board[cy][cx] != 0) {
        return; // Collision
      }
    }

    // Appliquer la transformation
    final newBoard = state.board.map((row) => List<int>.from(row)).toList();

    // Effacer l'ancienne position
    for (final (cx, cy) in placed.cells) {
      newBoard[cy][cx] = 0;
    }

    // Placer à la nouvelle position
    for (final (cx, cy) in newCells) {
      newBoard[cy][cx] = piece.id;
    }

    final newPlacedPieces = [...state.placedPieces];
    newPlacedPieces[placedIndex] = placed.copyWith(
      orientation: newOrientation,
      cells: newCells,
    );

    state = state.copyWith(
      board: newBoard,
      placedPieces: newPlacedPieces,
      selectedOrientation: newOrientation,
    );
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void reset() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;

    final board = List.generate(
      puzzle.size.height,
          (_) => List.filled(puzzle.size.width, 0),
    );

    state = state.copyWith(
      board: board,
      placedPieces: [],
      clearSelectedPiece: true,
      selectedOrientation: 0,
      clearSelectedPlacedPiece: true,
      clearPreviewX: true,
      clearPreviewY: true,
      isPreviewValid: false,
      isComplete: false,
      moveCount: 0,
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool _areCellsFree(List<(int, int)> cells) {
    for (final (cx, cy) in cells) {
      if (state.board[cy][cx] != 0) return false;
    }
    return true;
  }

  List<(int, int)>? _calculateCells(List<int> shape, int anchorX, int anchorY, int boardWidth, int boardHeight) {
    final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
    final shapeAnchorX = (minShapeCell - 1) % 5;
    final shapeAnchorY = (minShapeCell - 1) ~/ 5;

    final offsetX = anchorX - shapeAnchorX;
    final offsetY = anchorY - shapeAnchorY;

    final cells = <(int, int)>[];

    for (final shapeCell in shape) {
      final sx = (shapeCell - 1) % 5;
      final sy = (shapeCell - 1) ~/ 5;
      final px = sx + offsetX;
      final py = sy + offsetY;

      if (px < 0 || px >= boardWidth || py < 0 || py >= boardHeight) {
        return null;
      }

      cells.add((px, py));
    }

    return cells;
  }
}

/// Provider global
final pentoscopeProvider = NotifierProvider<PentoscopeNotifier, PentoscopeState>(
  PentoscopeNotifier.new,
);
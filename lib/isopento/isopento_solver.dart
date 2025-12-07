// lib/pentoscope/pentoscope_solver.dart
// Solver paramétré pour mini-plateaux (3×5, 4×5, 5×5)
// Copie adaptée de pentomino_solver.dart - AUCUN impact sur le mode 6×10

import '../models/pentominos.dart';

/// Résultat d'un placement de pièce
class PentoscopePlacement {
  final int pieceIndex;
  final int pieceId;
  final int orientation;
  final int offsetX;
  final int offsetY;
  final List<int> occupiedCells; // Indices linéaires des cases occupées

  PentoscopePlacement({
    required this.pieceIndex,
    required this.pieceId,
    required this.orientation,
    required this.offsetX,
    required this.offsetY,
    required this.occupiedCells,
  });

  @override
  String toString() =>
      'Pièce $pieceId (idx=$pieceIndex), orient=$orientation → cells=$occupiedCells';
}

/// Plateau simple pour Pentoscope (sans dépendance au Plateau principal)
class PentoscopeBoard {
  final int width;
  final int height;
  final List<List<int>> grid; // 0 = libre, >0 = pieceId

  PentoscopeBoard({required this.width, required this.height})
      : grid = List.generate(height, (_) => List.filled(width, 0));

  PentoscopeBoard._copy(this.width, this.height, this.grid);

  int get totalCells => width * height;

  bool isInBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  int getCell(int x, int y) => isInBounds(x, y) ? grid[y][x] : -1;

  void setCell(int x, int y, int value) {
    if (isInBounds(x, y)) grid[y][x] = value;
  }

  bool isFree(int x, int y) => getCell(x, y) == 0;

  PentoscopeBoard copy() {
    return PentoscopeBoard._copy(
      width,
      height,
      grid.map((row) => List<int>.from(row)).toList(),
    );
  }

  /// Convertit (x, y) en index linéaire
  int cellIndex(int x, int y) => y * width + x;

  /// Convertit index linéaire en (x, y)
  (int, int) cellCoords(int index) => (index % width, index ~/ width);
}

/// Solver paramétré pour Pentoscope
class PentoscopeSolver {
  final int width;
  final int height;
  final List<Pento> pieces;
  final int maxSeconds;

  late PentoscopeBoard _board;
  late List<bool> _piecesUsed;
  late DateTime _startTime;
  late List<PentoscopePlacement> _history;

  int _attemptCount = 0;
  bool _shouldStop = false;

  PentoscopeSolver({
    required this.width,
    required this.height,
    required this.pieces,
    this.maxSeconds = 30,
  }) {
    _board = PentoscopeBoard(width: width, height: height);
    _piecesUsed = List.filled(pieces.length, false);
    _history = [];
  }

  /// Vérifie si une solution existe (rapide, s'arrête à la première)
  bool hasSolution() {
    _reset();
    return _backtrack();
  }

  /// Trouve une solution et la retourne
  List<PentoscopePlacement>? findSolution() {
    _reset();
    if (_backtrack()) {
      return List.from(_history);
    }
    return null;
  }

  /// Compte TOUTES les solutions (peut être long pour 5×5)
  int countAllSolutions() {
    _reset();
    _shouldStop = false;
    return _countBacktrack();
  }

  /// Arrête le comptage en cours
  void stopCounting() {
    _shouldStop = true;
  }

  void _reset() {
    _board = PentoscopeBoard(width: width, height: height);
    _piecesUsed = List.filled(pieces.length, false);
    _history = [];
    _attemptCount = 0;
    _startTime = DateTime.now();
    _shouldStop = false;
  }

  /// Backtracking principal - trouve une solution
  bool _backtrack() {
    // Timeout
    if (DateTime.now().difference(_startTime).inSeconds > maxSeconds) {
      return false;
    }

    // Toutes les pièces placées ?
    if (_piecesUsed.every((used) => used)) {
      return true;
    }

    // Trouver la première case libre (stratégie simple mais efficace)
    final targetCell = _findFirstFreeCell();
    if (targetCell == -1) {
      return _piecesUsed.every((used) => used);
    }

    final (targetX, targetY) = _board.cellCoords(targetCell);

    // Essayer chaque pièce non utilisée
    for (int pieceIndex = 0; pieceIndex < pieces.length; pieceIndex++) {
      if (_piecesUsed[pieceIndex]) continue;

      final piece = pieces[pieceIndex];

      // Essayer chaque orientation
      for (int orientation = 0; orientation < piece.numPositions; orientation++) {
        _attemptCount++;

        final shape = piece.positions[orientation];
        final occupiedCells = <int>[];

        if (_canPlace(shape, targetX, targetY, occupiedCells)) {
          // Placer la pièce
          _place(shape, targetX, targetY, piece.id);
          _piecesUsed[pieceIndex] = true;

          _history.add(PentoscopePlacement(
            pieceIndex: pieceIndex,
            pieceId: piece.id,
            orientation: orientation,
            offsetX: targetX,
            offsetY: targetY,
            occupiedCells: occupiedCells,
          ));

          // Vérifier que les régions isolées sont valides
          if (_areIsolatedRegionsValid()) {
            if (_backtrack()) {
              return true;
            }
          }

          // Backtrack
          _remove(shape, targetX, targetY);
          _piecesUsed[pieceIndex] = false;
          _history.removeLast();
        }
      }
    }

    return false;
  }

  /// Backtracking pour compter toutes les solutions
  int _countBacktrack() {
    if (_shouldStop) return 0;

    // Timeout
    if (DateTime.now().difference(_startTime).inSeconds > maxSeconds) {
      return 0;
    }

    // Toutes les pièces placées = une solution !
    if (_piecesUsed.every((used) => used)) {
      return 1;
    }

    final targetCell = _findFirstFreeCell();
    if (targetCell == -1) {
      return _piecesUsed.every((used) => used) ? 1 : 0;
    }

    final (targetX, targetY) = _board.cellCoords(targetCell);
    int count = 0;

    for (int pieceIndex = 0; pieceIndex < pieces.length; pieceIndex++) {
      if (_piecesUsed[pieceIndex]) continue;

      final piece = pieces[pieceIndex];

      for (int orientation = 0; orientation < piece.numPositions; orientation++) {
        if (_shouldStop) return count;

        final shape = piece.positions[orientation];
        final occupiedCells = <int>[];

        if (_canPlace(shape, targetX, targetY, occupiedCells)) {
          _place(shape, targetX, targetY, piece.id);
          _piecesUsed[pieceIndex] = true;

          if (_areIsolatedRegionsValid()) {
            count += _countBacktrack();
          }

          _remove(shape, targetX, targetY);
          _piecesUsed[pieceIndex] = false;
        }
      }
    }

    return count;
  }

  /// Trouve la première case libre (index linéaire)
  int _findFirstFreeCell() {
    for (int i = 0; i < _board.totalCells; i++) {
      final (x, y) = _board.cellCoords(i);
      if (_board.isFree(x, y)) {
        return i;
      }
    }
    return -1;
  }

  /// Vérifie si on peut placer une forme à partir de (anchorX, anchorY)
  /// La forme est décalée pour que sa case min corresponde à l'ancre
  bool _canPlace(List<int> shape, int anchorX, int anchorY, List<int> outCells) {
    // Trouver le décalage de la forme (grille 5×5 interne des pentominos)
    final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
    final shapeAnchorX = (minShapeCell - 1) % 5;
    final shapeAnchorY = (minShapeCell - 1) ~/ 5;

    final offsetX = anchorX - shapeAnchorX;
    final offsetY = anchorY - shapeAnchorY;

    outCells.clear();

    for (final shapeCell in shape) {
      final sx = (shapeCell - 1) % 5;
      final sy = (shapeCell - 1) ~/ 5;
      final px = sx + offsetX;
      final py = sy + offsetY;

      if (!_board.isInBounds(px, py)) return false;
      if (!_board.isFree(px, py)) return false;

      outCells.add(_board.cellIndex(px, py));
    }

    return true;
  }

  /// Place une forme sur le plateau
  void _place(List<int> shape, int anchorX, int anchorY, int pieceId) {
    final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
    final shapeAnchorX = (minShapeCell - 1) % 5;
    final shapeAnchorY = (minShapeCell - 1) ~/ 5;

    final offsetX = anchorX - shapeAnchorX;
    final offsetY = anchorY - shapeAnchorY;

    for (final shapeCell in shape) {
      final sx = (shapeCell - 1) % 5;
      final sy = (shapeCell - 1) ~/ 5;
      _board.setCell(sx + offsetX, sy + offsetY, pieceId);
    }
  }

  /// Retire une forme du plateau
  void _remove(List<int> shape, int anchorX, int anchorY) {
    final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
    final shapeAnchorX = (minShapeCell - 1) % 5;
    final shapeAnchorY = (minShapeCell - 1) ~/ 5;

    final offsetX = anchorX - shapeAnchorX;
    final offsetY = anchorY - shapeAnchorY;

    for (final shapeCell in shape) {
      final sx = (shapeCell - 1) % 5;
      final sy = (shapeCell - 1) ~/ 5;
      _board.setCell(sx + offsetX, sy + offsetY, 0);
    }
  }

  /// Vérifie que toutes les régions isolées sont valides
  /// (taille multiple de 5, >= 5, et si == 5, une pièce dispo peut la remplir)
  bool _areIsolatedRegionsValid() {
    final visited = List.generate(
      _board.height,
          (_) => List.filled(_board.width, false),
    );

    for (int y = 0; y < _board.height; y++) {
      for (int x = 0; x < _board.width; x++) {
        if (_board.isFree(x, y) && !visited[y][x]) {
          final region = <(int, int)>[];
          final size = _floodFill(x, y, visited, region);

          // Taille < 5 : impossible
          if (size < 5) return false;

          // Taille non multiple de 5 : impossible
          if (size % 5 != 0) return false;

          // Taille == 5 : vérifier qu'une pièce disponible peut remplir
          if (size == 5 && !_canAnyPieceFitRegion(region)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Flood fill pour mesurer une région et collecter ses cellules
  int _floodFill(int x, int y, List<List<bool>> visited, List<(int, int)> region) {
    if (!_board.isInBounds(x, y) || visited[y][x] || !_board.isFree(x, y)) {
      return 0;
    }

    visited[y][x] = true;
    region.add((x, y));
    int size = 1;

    size += _floodFill(x - 1, y, visited, region);
    size += _floodFill(x + 1, y, visited, region);
    size += _floodFill(x, y - 1, visited, region);
    size += _floodFill(x, y + 1, visited, region);

    return size;
  }

  /// Vérifie si une pièce disponible peut remplir exactement une région de 5 cases
  bool _canAnyPieceFitRegion(List<(int, int)> region) {
    if (region.length != 5) return true;

    // Normaliser la région
    final minX = region.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
    final minY = region.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
    final normalizedRegion = region.map((p) => (p.$1 - minX, p.$2 - minY)).toSet();

    // Tester chaque pièce disponible
    for (int i = 0; i < pieces.length; i++) {
      if (_piecesUsed[i]) continue;

      final piece = pieces[i];
      for (int orientation = 0; orientation < piece.numPositions; orientation++) {
        final shape = piece.positions[orientation];

        // Convertir shape (indices 1-25) en coordonnées
        final shapeCoords = shape.map((cell) {
          final x = (cell - 1) % 5;
          final y = (cell - 1) ~/ 5;
          return (x, y);
        }).toList();

        // Normaliser
        final shapeMinX = shapeCoords.map((p) => p.$1).reduce((a, b) => a < b ? a : b);
        final shapeMinY = shapeCoords.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
        final normalizedShape = shapeCoords
            .map((p) => (p.$1 - shapeMinX, p.$2 - shapeMinY))
            .toSet();

        if (normalizedShape.length == normalizedRegion.length &&
            normalizedShape.every((p) => normalizedRegion.contains(p))) {
          return true;
        }
      }
    }

    return false;
  }
}
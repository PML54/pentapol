import 'pentominos.dart';
import 'plateau.dart';
import 'game_piece.dart';

class Game {
  final Plateau plateau;
  final List<GamePiece> pieces;
  final DateTime createdAt;
  final String? seed;

  const Game({
    required this.plateau,
    required this.pieces,
    required this.createdAt,
    this.seed,
  });

  factory Game.create({
    required Plateau plateau,
    required List<int> pieceIds,
    String? seed,
  }) {
    final pieces = pieceIds.map((id) {
      final pento = pentominos.firstWhere((p) => p.id == id);
      return GamePiece(pento: pento);
    }).toList();

    return Game(
      plateau: plateau,
      pieces: pieces,
      createdAt: DateTime.now(),
      seed: seed,
    );
  }

  int get totalPieceCells => pieces.length * 5;

  bool get isPlateauValid => plateau.numVisibleCells >= totalPieceCells;

  int get numPlacedPieces => pieces.where((p) => p.isPlaced).length;

  bool get isCompleted => numPlacedPieces == pieces.length;

  bool canPlacePiece(GamePiece piece, int x, int y) {
    final coords = GamePiece.shapeToCoordinates(piece.currentShape);

    for (var point in coords) {
      final absX = x + point.x;
      final absY = y + point.y;

      if (!plateau.isInBounds(absX, absY)) return false;
      if (plateau.getCell(absX, absY) == -1) return false;
      if (plateau.getCell(absX, absY) == 1) return false;
    }

    return true;
  }

  Game? placePieceAt(int pieceIndex, int x, int y) {
    if (pieceIndex < 0 || pieceIndex >= pieces.length) return null;

    final piece = pieces[pieceIndex];
    if (!canPlacePiece(piece, x, y)) return null;

    final newPlateau = plateau.copy();
    final coords = GamePiece.shapeToCoordinates(piece.currentShape);
    for (var point in coords) {
      newPlateau.setCell(x + point.x, y + point.y, 1);
    }

    final newPiece = piece.place(x, y);
    final newPieces = List<GamePiece>.from(pieces);
    newPieces[pieceIndex] = newPiece;

    return Game(
      plateau: newPlateau,
      pieces: newPieces,
      createdAt: createdAt,
      seed: seed,
    );
  }

  Game? removePiece(int pieceIndex) {
    if (pieceIndex < 0 || pieceIndex >= pieces.length) return null;

    final piece = pieces[pieceIndex];
    if (!piece.isPlaced) return null;

    final newPlateau = plateau.copy();
    final absCoords = piece.absoluteCoordinates;
    if (absCoords != null) {
      for (var point in absCoords) {
        newPlateau.setCell(point.x, point.y, 0);
      }
    }

    final newPiece = piece.unplace();
    final newPieces = List<GamePiece>.from(pieces);
    newPieces[pieceIndex] = newPiece;

    return Game(
      plateau: newPlateau,
      pieces: newPieces,
      createdAt: createdAt,
      seed: seed,
    );
  }

  Game updatePiece(int index, GamePiece newPiece) {
    final newPieces = List<GamePiece>.from(pieces);
    newPieces[index] = newPiece;
    return Game(
      plateau: plateau,
      pieces: newPieces,
      createdAt: createdAt,
      seed: seed,
    );
  }
}
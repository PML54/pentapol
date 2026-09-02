// GÉNÉRÉ par tools/generate_home_tirages.dart — NE PAS MODIFIER À LA MAIN.
// Les 7 tirages du 3×5 (plateau d'accueil 3 large × 5 haut, vertical), une solution réelle
// chacun. Chaque pièce : id (1..12, couleur via getPieceColor) + ses 5 cellules (x,y).
// lib/pentoscope/home/home_tirages_data.dart

/// Un tirage de l'écran d'accueil : nom (lettres des pièces) + les 3 pièces posées.
class HomeTirage {
  final String name;
  final List<HomePiece> pieces;
  const HomeTirage(this.name, this.pieces);
}

/// Une pièce posée : id du pentomino et ses 5 cellules [x, y] sur le plateau 3×5.
class HomePiece {
  final int id;
  final List<List<int>> cells;
  const HomePiece(this.id, this.cells);
}

/// Plateau d'accueil : 3 cases de large × 5 de haut.
const int kHomeBoardWidth = 3;
const int kHomeBoardHeight = 5;

const List<HomeTirage> kHomeTirages = [
  HomeTirage('PFU', [
    HomePiece(2, [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1]]),
    HomePiece(4, [[2, 1], [0, 2], [1, 2], [2, 2], [1, 3]]),
    HomePiece(7, [[0, 3], [2, 3], [0, 4], [1, 4], [2, 4]]),
  ]),
  HomeTirage('PUN', [
    HomePiece(2, [[0, 0], [1, 0], [0, 1], [1, 1], [0, 2]]),
    HomePiece(7, [[0, 3], [2, 3], [0, 4], [1, 4], [2, 4]]),
    HomePiece(9, [[2, 0], [2, 1], [1, 2], [2, 2], [1, 3]]),
  ]),
  HomeTirage('PVL', [
    HomePiece(2, [[0, 0], [1, 0], [0, 1], [1, 1], [1, 2]]),
    HomePiece(6, [[0, 2], [0, 3], [0, 4], [1, 4], [2, 4]]),
    HomePiece(8, [[2, 0], [2, 1], [2, 2], [1, 3], [2, 3]]),
  ]),
  HomeTirage('PVU', [
    HomePiece(2, [[1, 1], [2, 1], [1, 2], [2, 2], [1, 3]]),
    HomePiece(6, [[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]]),
    HomePiece(7, [[0, 3], [2, 3], [0, 4], [1, 4], [2, 4]]),
  ]),
  HomeTirage('PYU', [
    HomePiece(2, [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1]]),
    HomePiece(5, [[2, 1], [2, 2], [1, 3], [2, 3], [2, 4]]),
    HomePiece(7, [[0, 2], [1, 2], [0, 3], [0, 4], [1, 4]]),
  ]),
  HomeTirage('TYL', [
    HomePiece(3, [[0, 0], [1, 0], [2, 0], [1, 1], [1, 2]]),
    HomePiece(5, [[0, 1], [0, 2], [0, 3], [1, 3], [0, 4]]),
    HomePiece(8, [[2, 1], [2, 2], [2, 3], [1, 4], [2, 4]]),
  ]),
  HomeTirage('VLN', [
    HomePiece(6, [[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]]),
    HomePiece(8, [[2, 1], [2, 2], [2, 3], [1, 4], [2, 4]]),
    HomePiece(9, [[1, 1], [1, 2], [0, 3], [1, 3], [0, 4]]),
  ]),
];

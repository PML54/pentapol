// GÉNÉRÉ par tools/generate_home_tirages.dart — NE PAS MODIFIER À LA MAIN.
// Les 7 tirages du 3×5 (plateau d'accueil 5 large × 3 haut), une solution réelle
// chacun. Chaque pièce : id (1..12, couleur via getPieceColor) + ses 5 cellules (x,y).
// lib/pentoscope/home/home_tirages_data.dart

/// Un tirage de l'écran d'accueil : nom (lettres des pièces) + les 3 pièces posées.
class HomeTirage {
  final String name;
  final List<HomePiece> pieces;
  const HomeTirage(this.name, this.pieces);
}

/// Une pièce posée : id du pentomino et ses 5 cellules [x, y] sur le plateau 5×3.
class HomePiece {
  final int id;
  final List<List<int>> cells;
  const HomePiece(this.id, this.cells);
}

/// Plateau d'accueil : 5 cases de large × 3 de haut.
const int kHomeBoardWidth = 5;
const int kHomeBoardHeight = 3;

const List<HomeTirage> kHomeTirages = [
  HomeTirage('PFU', [
    HomePiece(2, [[0, 0], [0, 1], [1, 1], [0, 2], [1, 2]]),
    HomePiece(4, [[1, 0], [2, 0], [2, 1], [3, 1], [2, 2]]),
    HomePiece(7, [[3, 0], [4, 0], [4, 1], [3, 2], [4, 2]]),
  ]),
  HomeTirage('PUN', [
    HomePiece(2, [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1]]),
    HomePiece(7, [[3, 0], [4, 0], [4, 1], [3, 2], [4, 2]]),
    HomePiece(9, [[2, 1], [3, 1], [0, 2], [1, 2], [2, 2]]),
  ]),
  HomeTirage('PVL', [
    HomePiece(2, [[0, 0], [1, 0], [0, 1], [1, 1], [2, 1]]),
    HomePiece(6, [[2, 0], [3, 0], [4, 0], [4, 1], [4, 2]]),
    HomePiece(8, [[3, 1], [0, 2], [1, 2], [2, 2], [3, 2]]),
  ]),
  HomeTirage('PVU', [
    HomePiece(2, [[1, 0], [2, 0], [1, 1], [2, 1], [3, 1]]),
    HomePiece(6, [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]]),
    HomePiece(7, [[3, 0], [4, 0], [4, 1], [3, 2], [4, 2]]),
  ]),
  HomeTirage('PYU', [
    HomePiece(2, [[0, 0], [0, 1], [1, 1], [0, 2], [1, 2]]),
    HomePiece(5, [[1, 0], [2, 0], [3, 0], [4, 0], [3, 1]]),
    HomePiece(7, [[2, 1], [4, 1], [2, 2], [3, 2], [4, 2]]),
  ]),
  HomeTirage('TYL', [
    HomePiece(3, [[0, 0], [0, 1], [1, 1], [2, 1], [0, 2]]),
    HomePiece(5, [[1, 0], [2, 0], [3, 0], [4, 0], [3, 1]]),
    HomePiece(8, [[4, 1], [1, 2], [2, 2], [3, 2], [4, 2]]),
  ]),
  HomeTirage('VLN', [
    HomePiece(6, [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]]),
    HomePiece(8, [[1, 0], [2, 0], [3, 0], [4, 0], [4, 1]]),
    HomePiece(9, [[1, 1], [2, 1], [3, 1], [3, 2], [4, 2]]),
  ]),
];

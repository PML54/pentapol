// Généré automatiquement - Ne pas modifier manuellement
// Pentominos avec numéros de cases sur grille 5×5
// Numérotation: ligne 1 (bas) = cases 1-5, ligne 2 = cases 6-10, etc.

class Pento {
  final int id;
  final int size;
  final List<List<int>> positions;
  final int numPositions;
  final List<int> baseShape;
  final int bit6; // code binaire 6 bits unique pour la pièce (0..63)

  const Pento({
    required this.id,
    required this.size,
    required this.positions,
    required this.numPositions,
    required this.baseShape,
    required this.bit6,
  });
}

// ORDRE OPTIMAL: Trié par nombre de positions croissant (plus contraignant d'abord)
// Cet ordre fixe garantit:
// - Élagage précoce des branches impossibles
// - Recherche plus rapide
// - Solutions toujours trouvées dans le même ordre (reproductibilité)
final List<Pento> pentominos = [
  // Pièce 1 - 1 position (LA PLUS CONTRAIGNANTE)
  Pento(
    id: 1,
    size: 5,
    numPositions: 1,
    baseShape: [2, 6, 7, 8, 12],
    positions: [
      [2, 6, 7, 8, 12],
    ],
    bit6: 7, // 0b000111
  ),

  // Pièce 12 - 2 positions
  Pento(
    id: 12,
    size: 5,
    numPositions: 2,
    baseShape: [1, 6, 11, 16, 21],
    positions: [
      [1, 6, 11, 16, 21],
      [1, 2, 3, 4, 5],
    ],
    bit6: 22, // 0b010110
  ),

  // Pièce 3 - 4 positions
  Pento(
    id: 3,
    size: 5,
    numPositions: 4,
    baseShape: [3, 6, 7, 8, 13],
    positions: [
      [3, 6, 7, 8, 13],
      [2, 7, 11, 12, 13],
      [1, 6, 7, 8, 11],
      [1, 2, 3, 7, 12],
    ],
    bit6: 19, // 0b010011
  ),

  // Pièce 6 - 4 positions
  Pento(
    id: 6,
    size: 5,
    numPositions: 4,
    baseShape: [3, 8, 11, 12, 13],
    positions: [
      [3, 8, 11, 12, 13],
      [1, 6, 11, 12, 13],
      [1, 2, 3, 6, 11],
      [1, 2, 3, 8, 13],
    ],
    bit6: 21, // 0b010101
  ),

  // Pièce 7 - 4 positions
  Pento(
    id: 7,
    size: 5,
    numPositions: 4,
    baseShape: [1, 3, 6, 7, 8],
    positions: [
      [1, 3, 6, 7, 8],
      [1, 2, 6, 11, 12],
      [1, 2, 3, 6, 8],
      [1, 2, 7, 11, 12],
    ],
    bit6: 37, // 0b100101
  ),

  // Pièce 10 - 4 positions
  Pento(
    id: 10,
    size: 5,
    numPositions: 4,
    baseShape: [3, 6, 7, 8, 11],
    positions: [
      [3, 6, 7, 8, 11],
      [1, 2, 7, 12, 13],
      [1, 6, 7, 8, 13],
      [2, 3, 7, 11, 12],
    ],
    bit6: 49, // 0b110001
  ),

  // Pièce 11 - 4 positions
  Pento(
    id: 11,
    size: 5,
    numPositions: 4,
    baseShape: [3, 7, 8, 11, 12],
    positions: [
      [3, 7, 8, 11, 12],
      [1, 6, 7, 12, 13],
      [2, 3, 6, 7, 11],
      [1, 2, 7, 8, 13],
    ],
    bit6: 14, // 0b001110
  ),

  // Pièce 2 - 8 positions
  Pento(
    id: 2,
    size: 5,
    numPositions: 8,
    baseShape: [1, 2, 6, 7, 12],
    positions: [
      [1, 2, 6, 7, 12],
      [2, 3, 6, 7, 8],
      [1, 6, 7, 11, 12],
      [1, 2, 3, 6, 7],
      [1, 2, 6, 7, 11],
      [1, 2, 3, 7, 8],
      [2, 6, 7, 11, 12],
      [1, 2, 6, 7, 8],
    ],
    bit6: 11, // 0b001011
  ),

  // Pièce 4 - 8 positions
  Pento(
    id: 4,
    size: 5,
    numPositions: 8,
    baseShape: [2, 3, 6, 7, 12],
    positions: [
      [2, 3, 6, 7, 12],
      [2, 6, 7, 8, 13],
      [2, 7, 8, 11, 12],
      [1, 6, 7, 8, 12],
      [1, 2, 7, 8, 12],
      [3, 6, 7, 8, 12],
      [2, 6, 7, 12, 13],
      [2, 6, 7, 8, 11],
    ],
    bit6: 35, // 0b100011
  ),

  // Pièce 5 - 8 positions
  Pento(
    id: 5,
    size: 5,
    numPositions: 8,
    baseShape: [2, 7, 11, 12, 17],
    positions: [
      [2, 7, 11, 12, 17],
      [2, 6, 7, 8, 9],
      [1, 6, 7, 11, 16],
      [1, 2, 3, 4, 8],
      [1, 6, 11, 12, 16],
      [1, 2, 3, 4, 7],
      [2, 6, 7, 12, 17],
      [3, 6, 7, 8, 9],
    ],
    bit6: 13, // 0b001101
  ),

  // Pièce 8 - 8 positions
  Pento(
    id: 8,
    size: 5,
    numPositions: 8,
    baseShape: [4, 6, 7, 8, 9],
    positions: [
      [4, 6, 7, 8, 9],
      [1, 6, 11, 16, 17],
      [1, 2, 3, 4, 6],
      [1, 2, 7, 12, 17],
      [1, 6, 7, 8, 9],
      [1, 2, 6, 11, 16],
      [1, 2, 3, 4, 9],
      [2, 7, 12, 16, 17],
    ],
    bit6: 25, // 0b011001
  ),

  // Pièce 9 - 8 positions (LA MOINS CONTRAIGNANTE)
  Pento(
    id: 9,
    size: 5,
    numPositions: 8,
    baseShape: [3, 4, 6, 7, 8],
    positions: [
      [3, 4, 6, 7, 8],
      [1, 6, 11, 12, 17],
      [2, 3, 4, 6, 7],
      [1, 6, 7, 12, 17],
      [1, 2, 7, 8, 9],
      [2, 6, 7, 11, 16],
      [1, 2, 3, 8, 9],
      [2, 7, 11, 12, 16],
    ],
    bit6: 41, // 0b101001
  ),
];

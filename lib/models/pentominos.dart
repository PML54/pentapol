// Modified: 2025-11-18 (Correspondance géométrique des lettres)
// Généré automatiquement - Ne pas modifier manuellement les données
// Pentominos avec numéros de cases sur grille 5×5
// Numérotation: ligne 1 (bas) = cases 1-5, ligne 2 = cases 6-10, etc.
// Les positions préservent l'ordre géométrique des cellules pour le tracking

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

  /// Retourne la lettre (A-E) pour une case donnée dans baseShape
  /// La lettre est FIXE et basée sur l'ordre dans baseShape
  String getLetter(int cellNum) {
    const letters = ['A', 'B', 'C', 'D', 'E'];
    final index = baseShape.indexOf(cellNum);
    if (index == -1) return '?'; // Case non trouvée
    return letters[index];
  }

  /// Retourne la lettre (A-E) pour une case dans une position donnée
  /// Grâce à la préservation de l'ordre géométrique, l'index dans positions[positionIndex]
  /// correspond directement à l'index dans baseShape (donc à la même lettre)
  /// [positionIndex] : index de la position actuelle (0 à numPositions-1)
  /// [cellNum] : numéro de cellule dans cette position
  String getLetterForPosition(int positionIndex, int cellNum) {
    const letters = ['A', 'B', 'C', 'D', 'E'];
    
    // Trouver l'index de cellNum dans la position actuelle
    final position = positions[positionIndex];
    final indexInPosition = position.indexOf(cellNum);
    
    if (indexInPosition == -1) return '?';
    
    // L'index dans la position correspond à la même cellule géométrique
    // donc à la même lettre que dans baseShape
    return letters[indexInPosition];
  }

  /// Trouve l'index de la position qui correspond à une rotation de 90° anti-horaire
  /// depuis la position actuelle
  /// Retourne -1 si aucune rotation n'est trouvée (pièce symétrique)
  int findRotation90(int currentPositionIndex) {
    return _findTransformedPosition(currentPositionIndex, _rotate90Coords);
  }

  /// Trouve l'index de la position qui correspond à une symétrie horizontale
  /// depuis la position actuelle
  /// Retourne -1 si aucune symétrie n'est trouvée
  int findSymmetryH(int currentPositionIndex) {
    return _findTransformedPosition(currentPositionIndex, _flipHCoords);
  }

  /// Trouve l'index de la position qui correspond à une symétrie verticale
  /// depuis la position actuelle
  /// Retourne -1 si aucune symétrie n'est trouvée
  int findSymmetryV(int currentPositionIndex) {
    return _findTransformedPosition(currentPositionIndex, _flipVCoords);
  }

  /// Méthode générique pour trouver une position transformée
  int _findTransformedPosition(
    int currentPositionIndex,
    List<List<int>> Function(List<List<int>>) transform,
  ) {
    // Convertir la position actuelle en coordonnées
    final currentCoords = _positionToCoordsNormalized(currentPositionIndex);
    
    // Appliquer la transformation
    final transformedCoords = transform(currentCoords);
    
    // Chercher dans toutes les positions celle qui correspond
    for (int i = 0; i < positions.length; i++) {
      final candidateCoords = _positionToCoordsNormalized(i);
      if (_coordsEqual(transformedCoords, candidateCoords)) {
        return i;
      }
    }
    
    return -1; // Transformation non trouvée
  }

  /// Convertit une position en coordonnées normalisées
  List<List<int>> _positionToCoordsNormalized(int positionIndex) {
    final position = positions[positionIndex];
    final coords = position.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return [x, y];
    }).toList();
    
    // Normaliser : décaler pour que min(x)=0 et min(y)=0
    if (coords.isEmpty) return [];
    
    final minX = coords.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final minY = coords.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    
    final normalized = coords.map((c) => [c[0] - minX, c[1] - minY]).toList();
    // Trier pour comparaison
    normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    return normalized;
  }

  /// Rotation de 90° anti-horaire : (x,y) -> (-y, x)
  List<List<int>> _rotate90Coords(List<List<int>> coords) {
    final rotated = coords.map((c) => [-c[1], c[0]]).toList();
    
    // Normaliser
    if (rotated.isEmpty) return [];
    
    final minX = rotated.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final minY = rotated.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    
    final normalized = rotated.map((c) => [c[0] - minX, c[1] - minY]).toList();
    normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    return normalized;
  }

  /// Symétrie horizontale : (x,y) -> (-x, y)
  List<List<int>> _flipHCoords(List<List<int>> coords) {
    final flipped = coords.map((c) => [-c[0], c[1]]).toList();
    
    // Normaliser
    if (flipped.isEmpty) return [];
    
    final minX = flipped.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final minY = flipped.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    
    final normalized = flipped.map((c) => [c[0] - minX, c[1] - minY]).toList();
    normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    return normalized;
  }

  /// Symétrie verticale : (x,y) -> (x, -y)
  List<List<int>> _flipVCoords(List<List<int>> coords) {
    final flipped = coords.map((c) => [c[0], -c[1]]).toList();
    
    // Normaliser
    if (flipped.isEmpty) return [];
    
    final minX = flipped.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
    final minY = flipped.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
    
    final normalized = flipped.map((c) => [c[0] - minX, c[1] - minY]).toList();
    normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
    
    return normalized;
  }

  /// Compare deux listes de coordonnées
  bool _coordsEqual(List<List<int>> coords1, List<List<int>> coords2) {
    if (coords1.length != coords2.length) return false;
    
    for (int i = 0; i < coords1.length; i++) {
      if (coords1[i][0] != coords2[i][0] || coords1[i][1] != coords2[i][1]) {
        return false;
      }
    }
    
    return true;
  }
}

final List<Pento> pentominos = [
  // Pièce 1
  Pento(
    id: 1,
    size: 5,
    numPositions: 1,
    baseShape: [2, 6, 7, 8, 12],
    bit6: 7, // 0b000111
    positions: [
      [6, 2, 7, 12, 8],
    ],
  ),

  // Pièce 2
  Pento(
    id: 2,
    size: 5,
    numPositions: 8,
    baseShape: [1, 2, 6, 7, 12],
    bit6: 11, // 0b001011
    positions: [
      [1, 6, 2, 7, 12],
      [3, 2, 8, 7, 6],
      [12, 7, 11, 6, 1],
      [6, 7, 1, 2, 3],
      [2, 7, 1, 6, 11],
      [8, 7, 3, 2, 1],
      [11, 6, 12, 7, 2],
      [1, 2, 6, 7, 8],
    ],
  ),

  // Pièce 3
  Pento(
    id: 3,
    size: 5,
    numPositions: 4,
    baseShape: [3, 6, 7, 8, 13],
    bit6: 19, // 0b010011
    positions: [
      [6, 7, 3, 8, 13],
      [2, 7, 13, 12, 11],
      [8, 7, 11, 6, 1],
      [12, 7, 1, 2, 3],
    ],
  ),

  // Pièce 4
  Pento(
    id: 4,
    size: 5,
    numPositions: 8,
    baseShape: [2, 3, 6, 7, 12],
    bit6: 35, // 0b100011
    positions: [
      [6, 2, 7, 12, 3],
      [2, 8, 7, 6, 13],
      [8, 12, 7, 2, 11],
      [12, 6, 7, 8, 1],
      [8, 2, 7, 12, 1],
      [12, 8, 7, 6, 3],
      [6, 12, 7, 2, 13],
      [2, 6, 7, 8, 11],
    ],
  ),

  // Pièce 5
  Pento(
    id: 5,
    size: 5,
    numPositions: 8,
    baseShape: [2, 7, 11, 12, 17],
    bit6: 13, // 0b001101
    positions: [
      [11, 2, 7, 12, 17],
      [2, 9, 8, 7, 6],
      [7, 16, 11, 6, 1],
      [8, 1, 2, 3, 4],
      [12, 1, 6, 11, 16],
      [7, 4, 3, 2, 1],
      [6, 17, 12, 7, 2],
      [3, 6, 7, 8, 9],
    ],
  ),

  // Pièce 6
  Pento(
    id: 6,
    size: 5,
    numPositions: 4,
    baseShape: [3, 8, 11, 12, 13],
    bit6: 21, // 0b010101
    positions: [
      [11, 12, 3, 8, 13],
      [1, 6, 13, 12, 11],
      [3, 2, 11, 6, 1],
      [13, 8, 1, 2, 3],
    ],
  ),

  // Pièce 7
  Pento(
    id: 7,
    size: 5,
    numPositions: 4,
    baseShape: [1, 3, 6, 7, 8],
    bit6: 37, // 0b100101
    positions: [
      [1, 6, 7, 3, 8],
      [2, 1, 6, 12, 11],
      [8, 3, 2, 6, 1],
      [11, 12, 7, 1, 2],
    ],
  ),

  // Pièce 8
  Pento(
    id: 8,
    size: 5,
    numPositions: 8,
    baseShape: [4, 6, 7, 8, 9],
    bit6: 25, // 0b011001
    positions: [
      [6, 7, 8, 4, 9],
      [1, 6, 11, 17, 16],
      [4, 3, 2, 6, 1],
      [17, 12, 7, 1, 2],
      [9, 8, 7, 1, 6],
      [16, 11, 6, 2, 1],
      [1, 2, 3, 9, 4],
      [2, 7, 12, 16, 17],
    ],
  ),

  // Pièce 9
  Pento(
    id: 9,
    size: 5,
    numPositions: 8,
    baseShape: [3, 4, 6, 7, 8],
    bit6: 41, // 0b101001
    positions: [
      [6, 7, 3, 8, 4],
      [1, 6, 12, 11, 17],
      [4, 3, 7, 2, 6],
      [17, 12, 6, 7, 1],
      [9, 8, 2, 7, 1],
      [16, 11, 7, 6, 2],
      [1, 2, 8, 3, 9],
      [2, 7, 11, 12, 16],
    ],
  ),

  // Pièce 10
  Pento(
    id: 10,
    size: 5,
    numPositions: 4,
    baseShape: [3, 6, 7, 8, 11],
    bit6: 49, // 0b110001
    positions: [
      [6, 11, 7, 3, 8],
      [2, 1, 7, 13, 12],
      [8, 13, 7, 1, 6],
      [12, 11, 7, 3, 2],
    ],
  ),

  // Pièce 11
  Pento(
    id: 11,
    size: 5,
    numPositions: 4,
    baseShape: [3, 7, 8, 11, 12],
    bit6: 14, // 0b001110
    positions: [
      [11, 7, 12, 3, 8],
      [1, 7, 6, 13, 12],
      [3, 7, 2, 11, 6],
      [13, 7, 8, 1, 2],
    ],
  ),

  // Pièce 12
  Pento(
    id: 12,
    size: 5,
    numPositions: 2,
    baseShape: [1, 6, 11, 16, 21],
    bit6: 22, // 0b010110
    positions: [
      [1, 6, 11, 16, 21],
      [5, 4, 3, 2, 1],
    ],
  ),
];

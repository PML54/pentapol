/// Utilitaires pour le calcul des isométries dans Pentapol - Mode Duel Isométries
///
/// Le groupe diédral D₄ (symétries du carré) a 8 éléments représentés par:
/// - rotation: 0, 1, 2, 3 (multiples de 90° dans le sens horaire)
/// - flipped: true/false (symétrie horizontale appliquée)
///
/// Opérations disponibles (coût = 1 chacune):
/// - R: rotation 90° horaire
/// - L: rotation 90° anti-horaire
/// - H: symétrie horizontale (miroir axe Y)
/// - V: symétrie verticale (miroir axe X)
///
/// Distance maximale entre deux configurations = 3

/// Représente une configuration d'isométrie d'une pièce
class PieceConfiguration {
  /// Rotation: 0 = 0°, 1 = 90°, 2 = 180°, 3 = 270° (sens horaire)
  final int rotation;

  /// true si la pièce est retournée horizontalement
  final bool flipped;

  const PieceConfiguration(this.rotation, this.flipped)
      : assert(rotation >= 0 && rotation < 4);

  /// Configuration identité (pas de transformation)
  static const identity = PieceConfiguration(0, false);

  /// Applique une rotation R (90° horaire)
  PieceConfiguration rotateRight() {
    return PieceConfiguration((rotation + 1) % 4, flipped);
  }

  /// Applique une rotation L (90° anti-horaire)
  PieceConfiguration rotateLeft() {
    return PieceConfiguration((rotation + 3) % 4, flipped);
  }

  /// Applique une symétrie horizontale H
  /// Géométriquement: miroir par rapport à l'axe Y
  /// Effet sur la configuration: flip change, rotation s'inverse
  PieceConfiguration flipHorizontal() {
    // Après un flip H, la rotation "perçue" devient -rotation (mod 4)
    // Car on flip d'abord, puis on applique la rotation
    final newRotation = flipped ? rotation : (4 - rotation) % 4;
    return PieceConfiguration(newRotation, !flipped);
  }

  /// Applique une symétrie verticale V
  /// Géométriquement: miroir par rapport à l'axe X
  /// Équivalent à H puis rotation 180° (ou vice versa)
  PieceConfiguration flipVertical() {
    // V = H ∘ R² (flip horizontal puis rotation 180°)
    final newRotation = flipped ? (rotation + 2) % 4 : (6 - rotation) % 4;
    return PieceConfiguration(newRotation, !flipped);
  }

  /// Index unique de 0 à 7 pour cette configuration
  int get index => rotation + (flipped ? 4 : 0);

  /// Crée une configuration depuis un index (0-7)
  factory PieceConfiguration.fromIndex(int index) {
    assert(index >= 0 && index < 8);
    return PieceConfiguration(index % 4, index >= 4);
  }

  @override
  bool operator ==(Object other) =>
      other is PieceConfiguration &&
          other.rotation == rotation &&
          other.flipped == flipped;

  @override
  int get hashCode => rotation.hashCode ^ flipped.hashCode;

  @override
  String toString() => 'Config(r$rotation, ${flipped ? "flipped" : "normal"})';
}

/// Classe utilitaire pour les calculs d'isométries
class IsometryUtils {
  IsometryUtils._(); // Constructeur privé - classe statique

  /// Table de distances pré-calculée (8x8)
  /// _distanceTable[from.index][to.index] = nombre minimal d'isométries
  static final List<List<int>> _distanceTable = _buildDistanceTable();

  /// Construit la table de distances par BFS
  static List<List<int>> _buildDistanceTable() {
    final table = List.generate(8, (_) => List.filled(8, -1));

    for (int startIdx = 0; startIdx < 8; startIdx++) {
      // BFS depuis cette configuration
      final distances = List.filled(8, -1);
      distances[startIdx] = 0;

      final queue = <int>[startIdx];
      int head = 0;

      while (head < queue.length) {
        final currentIdx = queue[head++];
        final current = PieceConfiguration.fromIndex(currentIdx);
        final currentDist = distances[currentIdx];

        // Appliquer les 4 opérations possibles
        final neighbors = [
          current.rotateRight(),
          current.rotateLeft(),
          current.flipHorizontal(),
          current.flipVertical(),
        ];

        for (final neighbor in neighbors) {
          final neighborIdx = neighbor.index;
          if (distances[neighborIdx] == -1) {
            distances[neighborIdx] = currentDist + 1;
            queue.add(neighborIdx);
          }
        }
      }

      table[startIdx] = distances;
    }

    return table;
  }

  /// Calcule le nombre minimal d'isométries pour passer de [from] à [to]
  ///
  /// Retourne un entier entre 0 et 3 (distance maximale dans D₄ avec R,L,H,V)
  static int minIsometries(PieceConfiguration from, PieceConfiguration to) {
    return _distanceTable[from.index][to.index];
  }

  /// Version pratique avec rotation et flip séparés
  static int minIsometriesFromValues({
    required int fromRotation,
    required bool fromFlipped,
    required int toRotation,
    required bool toFlipped,
  }) {
    final from = PieceConfiguration(fromRotation, fromFlipped);
    final to = PieceConfiguration(toRotation, toFlipped);
    return minIsometries(from, to);
  }

  /// Calcule le score d'isométries optimal pour un ensemble de pièces
  ///
  /// [pieces] est une liste de paires (configInitiale, configCible)
  /// Retourne le nombre total minimal d'isométries nécessaires
  static int totalMinIsometries(
      List<(PieceConfiguration, PieceConfiguration)> pieces) {
    return pieces.fold(0, (sum, pair) => sum + minIsometries(pair.$1, pair.$2));
  }

  /// Calcule l'efficacité en pourcentage
  ///
  /// [optimalCount] = nombre minimal d'isométries théorique
  /// [playerCount] = nombre d'isométries utilisées par le joueur
  /// Retourne un pourcentage (100 = parfait, moins = moins efficace)
  static double efficiencyPercent(int optimalCount, int playerCount) {
    if (playerCount == 0) return optimalCount == 0 ? 100.0 : 0.0;
    if (optimalCount == 0) return 100.0;
    return (optimalCount / playerCount * 100).clamp(0.0, 100.0);
  }

  /// Retourne le chemin optimal (séquence d'opérations) entre deux configurations
  ///
  /// Utile pour le debug ou pour afficher la solution optimale
  /// Retourne une liste de chaînes: "R", "L", "H", "V"
  static List<String> optimalPath(
      PieceConfiguration from, PieceConfiguration to) {
    if (from == to) return [];

    // BFS avec reconstruction du chemin
    final parent = <int, int>{};
    final operation = <int, String>{};
    final visited = <int>{from.index};
    final queue = <int>[from.index];
    int head = 0;

    while (head < queue.length) {
      final currentIdx = queue[head++];
      final current = PieceConfiguration.fromIndex(currentIdx);

      final ops = <String, PieceConfiguration>{
        'R': current.rotateRight(),
        'L': current.rotateLeft(),
        'H': current.flipHorizontal(),
        'V': current.flipVertical(),
      };

      for (final entry in ops.entries) {
        final neighborIdx = entry.value.index;
        if (!visited.contains(neighborIdx)) {
          visited.add(neighborIdx);
          parent[neighborIdx] = currentIdx;
          operation[neighborIdx] = entry.key;
          queue.add(neighborIdx);

          if (neighborIdx == to.index) {
            // Reconstruire le chemin
            final path = <String>[];
            int idx = to.index;
            while (idx != from.index) {
              path.add(operation[idx]!);
              idx = parent[idx]!;
            }
            return path.reversed.toList();
          }
        }
      }
    }

    return []; // Ne devrait jamais arriver (graphe connexe)
  }

  /// Affiche la table de distances (pour debug)
  static void printDistanceTable() {
    print('    | r0n r1n r2n r3n r0f r1f r2f r3f');
    print('----+--------------------------------');
    for (int i = 0; i < 8; i++) {
      final config = PieceConfiguration.fromIndex(i);
      final label =
          'r${config.rotation}${config.flipped ? "f" : "n"}';
      final row = _distanceTable[i].map((d) => ' $d ').join(' ');
      print('$label |$row');
    }
  }
}

/// Extension pour faciliter l'utilisation avec les pièces du jeu
extension PieceIsometryExtension on PieceConfiguration {
  /// Distance vers une autre configuration
  int distanceTo(PieceConfiguration other) {
    return IsometryUtils.minIsometries(this, other);
  }

  /// Chemin optimal vers une autre configuration
  List<String> pathTo(PieceConfiguration other) {
    return IsometryUtils.optimalPath(this, other);
  }
}

/// Classe pour stocker les stats d'isométries d'un joueur pendant un round
class IsometryStats {
  int _totalOperations = 0;
  int _rotations = 0;
  int _flips = 0;

  int get totalOperations => _totalOperations;
  int get rotations => _rotations;
  int get flips => _flips;

  void recordRotation() {
    _rotations++;
    _totalOperations++;
  }

  void recordFlip() {
    _flips++;
    _totalOperations++;
  }

  void reset() {
    _totalOperations = 0;
    _rotations = 0;
    _flips = 0;
  }

  /// Calcule l'efficacité par rapport à l'optimal
  double efficiencyPercent(int optimalCount) {
    return IsometryUtils.efficiencyPercent(optimalCount, _totalOperations);
  }

  @override
  String toString() =>
      'IsometryStats(total: $_totalOperations, rotations: $_rotations, flips: $_flips)';
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  print('=== Test IsometryUtils ===\n');

  // Test 1: Distance identité
  final id = PieceConfiguration.identity;
  print('Distance id → id: ${IsometryUtils.minIsometries(id, id)}'); // 0

  // Test 2: Une rotation
  final r1 = PieceConfiguration(1, false);
  print('Distance r0 → r1: ${IsometryUtils.minIsometries(id, r1)}'); // 1
  print('Chemin: ${IsometryUtils.optimalPath(id, r1)}'); // [R]

  // Test 3: Rotation 180°
  final r2 = PieceConfiguration(2, false);
  print('Distance r0 → r2: ${IsometryUtils.minIsometries(id, r2)}'); // 2
  print('Chemin: ${IsometryUtils.optimalPath(id, r2)}'); // [R, R]

  // Test 4: Flip simple
  final f0 = PieceConfiguration(0, true);
  print('Distance r0n → r0f: ${IsometryUtils.minIsometries(id, f0)}'); // 1
  print('Chemin: ${IsometryUtils.optimalPath(id, f0)}'); // [H] ou [V]

  // Test 5: Flip + rotation (cas le plus éloigné)
  final f1 = PieceConfiguration(1, true);
  print('Distance r0n → r1f: ${IsometryUtils.minIsometries(id, f1)}'); // 2
  print('Chemin: ${IsometryUtils.optimalPath(id, f1)}'); // ex: [H, R] ou [V, L]

  // Test 6: Distance max
  final f3 = PieceConfiguration(3, true);
  print('Distance r0n → r3f: ${IsometryUtils.minIsometries(id, f3)}'); // 2
  print('Chemin: ${IsometryUtils.optimalPath(id, f3)}'); // ex: [H, L]

  // Test 7: Vérifier toutes les distances
  print('\n=== Table des distances ===');
  IsometryUtils.printDistanceTable();

  // Test 8: Calcul total pour un puzzle
  print('\n=== Test puzzle ===');
  final puzzlePieces = [
    (PieceConfiguration(0, false), PieceConfiguration(2, false)), // 2 rotations
    (PieceConfiguration(1, false), PieceConfiguration(1, true)), // 1 flip
    (PieceConfiguration(3, true), PieceConfiguration(0, false)), // 2 ops
  ];
  final optimal = IsometryUtils.totalMinIsometries(puzzlePieces);
  print('Optimal pour ce puzzle: $optimal isométries'); // 5

  // Si le joueur a fait 7 isométries
  final playerCount = 7;
  final efficiency = IsometryUtils.efficiencyPercent(optimal, playerCount);
  print('Joueur: $playerCount isométries');
  print('Efficacité: ${efficiency.toStringAsFixed(1)}%'); // 71.4%

  // Test 9: Stats de jeu
  print('\n=== Test IsometryStats ===');
  final stats = IsometryStats();
  stats.recordRotation(); // R
  stats.recordRotation(); // R
  stats.recordFlip(); // H
  stats.recordRotation(); // L
  print(stats); // total: 4, rotations: 3, flips: 1
  print('Efficacité vs optimal 3: ${stats.efficiencyPercent(3).toStringAsFixed(1)}%'); // 75%
}
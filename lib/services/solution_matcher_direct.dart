// lib/services/solution_matcher_direct.dart
// VERSION DIRECTE : Compare avec les 2339 formes canoniques SANS transformations
// Pour déboguer et vérifier que la comparaison fonctionne

import 'pentomino_canonical_forms_hexa.dart';

/// Décode une forme hexadécimale en grille de 60 entiers
List<int> decodeCanonicalForm(String hex) {
  assert(hex.length == 60, 'Format invalide: doit avoir 60 caractères');
  
  final grid = <int>[];
  for (int i = 0; i < 60; i++) {
    final char = hex[i];
    final value = int.parse(char, radix: 16); // '1'-'9', 'A'-'C' → 1-12
    grid.add(value);
  }
  
  return grid;
}

/// Gestionnaire de solutions SANS transformations (juste les 2339 formes canoniques)
class SolutionMatcherDirect {
  late final List<List<int>> _allSolutions;

  SolutionMatcherDirect() {
    print('[SOLUTION_MATCHER_DIRECT] Initialisation...');
    final startTime = DateTime.now();

    _allSolutions = _loadCanonicalForms();

    final duration = DateTime.now().difference(startTime);
    print('[SOLUTION_MATCHER_DIRECT] ✓ ${_allSolutions.length} formes canoniques chargées en ${duration.inMilliseconds}ms');
  }

  /// Charge les 2339 formes canoniques depuis le fichier hexa
  List<List<int>> _loadCanonicalForms() {
    final solutions = <List<int>>[];

    for (final formHex in canonicalForms) {
      final grid = decodeCanonicalForm(formHex);
      solutions.add(grid);
    }

    return solutions;
  }

  /// Compte les solutions compatibles avec un masque de plateau
  /// plateauMask: 60 entiers (0 = case libre, 1-12 = pièce placée)
  int countCompatible(List<int> plateauMask) {
    assert(plateauMask.length == 60, 'Le masque doit avoir 60 cellules');

    int count = 0;
    int debugCount = 0;

    print('[DIRECT] ═══════════════════════════════════');
    print('[DIRECT] Recherche de solutions compatibles...');
    
    // Afficher le masque
    final placedCells = plateauMask.where((v) => v > 0).length;
    final pieceIds = plateauMask.where((v) => v > 0).toSet();
    print('[DIRECT] Masque: $placedCells cellules, pièces $pieceIds');

    for (int i = 0; i < _allSolutions.length; i++) {
      final solution = _allSolutions[i];
      if (_isCompatible(plateauMask, solution)) {
        count++;
        
        // Debug: afficher les 5 premières solutions compatibles
        if (debugCount < 5) {
          print('[DIRECT] ✓ Solution #$i compatible:');
          for (int y = 0; y < 10; y++) {
            final row = <String>[];
            for (int x = 0; x < 6; x++) {
              final idx = y * 6 + x;
              final val = solution[idx];
              row.add(val.toString().padLeft(2));
            }
            print('[DIRECT]   ${row.join(' ')}');
          }
          debugCount++;
        }
      }
    }

    print('[DIRECT] ═══════════════════════════════════');
    print('[DIRECT] Résultat: $count formes canoniques compatibles');
    print('[DIRECT] (sans transformations)');
    print('[DIRECT] ═══════════════════════════════════');

    return count;
  }

  /// Vérifie si une solution est compatible avec le masque
  /// COMPARAISON SIMPLE : valeur par valeur
  bool _isCompatible(List<int> plateauMask, List<int> solution) {
    for (int cellIndex = 0; cellIndex < 60; cellIndex++) {
      final maskValue = plateauMask[cellIndex];
      
      // Si la case est libre (0), on ne vérifie pas
      if (maskValue == 0) continue;
      
      // Extraire la valeur dans la solution
      final solutionValue = solution[cellIndex];
      
      // Comparaison : doit être identique À LA MÊME POSITION
      if (maskValue != solutionValue) {
        return false; // Pas compatible
      }
    }
    
    return true; // Compatible !
  }

  /// Retourne la liste des solutions compatibles (pour débogage)
  List<List<int>> getCompatibleSolutions(List<int> plateauMask) {
    final compatible = <List<int>>[];

    for (final solution in _allSolutions) {
      if (_isCompatible(plateauMask, solution)) {
        compatible.add(solution);
      }
    }

    return compatible;
  }

  /// Nombre total de solutions chargées
  int get totalSolutions => _allSolutions.length;
}





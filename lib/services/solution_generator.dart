// lib/services/solution_generator.dart
// Génère un fichier texte avec toutes les 9356 solutions au démarrage

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'pentomino_canonical_forms_hexa.dart';

/// Génère toutes les solutions et les sauvegarde dans un fichier
Future<String> generateAllSolutionsFile() async {
  print('[SOLUTION_GENERATOR] Génération des 9356 solutions...');
  final startTime = DateTime.now();

  final solutions = <List<int>>[];

  // Générer les 4 transformations pour chaque forme canonique
  for (final formHex in canonicalForms) {
    final grid = decodeCanonicalForm(formHex);
    
    solutions.add(grid);                          // Original
    solutions.add(_rotate180(grid));              // Rotation 180°
    solutions.add(_mirrorHorizontal(grid));       // Miroir H
    solutions.add(_mirrorVertical(grid));         // Miroir V
  }

  final duration = DateTime.now().difference(startTime);
  print('[SOLUTION_GENERATOR] ${solutions.length} solutions générées en ${duration.inMilliseconds}ms');

  // Sauvegarder dans un fichier
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pentomino_solutions_9356.txt');
    
    final buffer = StringBuffer();
    buffer.writeln('# Pentomino Solutions - 9356 solutions');
    buffer.writeln('# Généré le: ${DateTime.now()}');
    buffer.writeln('# Format: 60 nombres par ligne (6x10 grid)');
    buffer.writeln('');

    for (int i = 0; i < solutions.length; i++) {
      buffer.write('Solution ${i + 1}: ');
      buffer.writeln(solutions[i].join(','));
    }

    await file.writeAsString(buffer.toString());
    print('[SOLUTION_GENERATOR] ✓ Fichier sauvegardé: ${file.path}');
    print('[SOLUTION_GENERATOR] Taille: ${(await file.length()) / 1024} KB');
    
    return file.path;
  } catch (e) {
    print('[SOLUTION_GENERATOR] ❌ Erreur sauvegarde: $e');
    return '';
  }
}

/// Rotation 180°
List<int> _rotate180(List<int> grid) {
  final rotated = <int>[];
  for (int i = 59; i >= 0; i--) {
    rotated.add(grid[i]);
  }
  return rotated;
}

/// Symétrie horizontale (miroir gauche-droite)
List<int> _mirrorHorizontal(List<int> grid) {
  final mirrored = <int>[];
  for (int y = 0; y < 10; y++) {
    for (int x = 5; x >= 0; x--) {
      mirrored.add(grid[y * 6 + x]);
    }
  }
  return mirrored;
}

/// Symétrie verticale (miroir haut-bas)
List<int> _mirrorVertical(List<int> grid) {
  final mirrored = <int>[];
  for (int y = 9; y >= 0; y--) {
    for (int x = 0; x < 6; x++) {
      mirrored.add(grid[y * 6 + x]);
    }
  }
  return mirrored;
}





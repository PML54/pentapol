// Modified: 2025-11-15 06:45:00
// lib/providers/plateau_editor_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'plateau_editor_state.dart';
import '../models/plateau.dart';
import '../models/pentominos.dart';
import '../services/pentomino_solver.dart';


class PlateauEditorNotifier extends Notifier<PlateauEditorState> {
  @override
  PlateauEditorState build() {
    return PlateauEditorState.initial();
  }

  void toggleCell(int x, int y) {
    final currentStatus = state.plateau.getCell(x, y);
    final newStatus = currentStatus == 0 ? -1 : 0;

    final newPlateau = state.plateau.copy();
    newPlateau.setCell(x, y, newStatus);

    // Créer un nouvel état pour forcer le reset des champs nullable
    state = PlateauEditorState(
      plateau: newPlateau,
      numPieces: state.numPieces,
      isSolving: false,
      hasSolution: null,
      errorMessage: null,
      solution: null,
      solver: null,
      selectedPieces: null,
      solutionIndex: 0,
    );
  }

  void setNumPieces(int n) {
    // Créer un nouvel état pour forcer le reset des champs nullable
    state = PlateauEditorState(
      plateau: state.plateau,
      numPieces: n,
      isSolving: false,
      hasSolution: null,
      errorMessage: null,
      solution: null,
      solver: null,
      selectedPieces: null,
      solutionIndex: 0,
    );
  }

  void reset() {
    // Reset efface seulement les résultats de validation,
    // pas le plateau modifié par l'utilisateur
    // Créer un nouvel état pour forcer le reset des champs nullable
    state = PlateauEditorState(
      plateau: state.plateau,
      numPieces: state.numPieces,
      isSolving: false,
      hasSolution: null,
      errorMessage: null,
      solution: null,
      solver: null,
      selectedPieces: null,
      solutionIndex: 0,
    );
  }
  
  void clearPlateau() {
    // Clear remet un plateau vide (toutes cases visibles)
    state = PlateauEditorState(
      plateau: Plateau.allVisible(6, 10),
      numPieces: state.numPieces,
      isSolving: false,
      hasSolution: null,
      errorMessage: null,
      solution: null,
      solver: null,
      selectedPieces: null,
      solutionIndex: 0,
    );
  }

  Future<void> validate() async {
    final numVisible = state.plateau.numVisibleCells;
    final required = state.numPieces * 5;

    if (numVisible < required) {
      state = state.copyWith(
        errorMessage: 'Pas assez de cases: $numVisible < $required',
        hasSolution: null,
      );
      return;
    }

    state = state.copyWith(
      isSolving: true,
      errorMessage: null,
      hasSolution: null,
      solution: null,
      solver: null,
      solutionIndex: 0,
    );

    try {
      // Générer toutes les combinaisons de numPieces parmi 12
      final allCombinations = _generateCombinations(pentominos, state.numPieces);
      print('[PROVIDER] Test de ${allCombinations.length} combinaisons de ${state.numPieces} pièces');

      List<Pento>? bestPieces;
      List<PlacementInfo>? bestSolution;
      PentominoSolver? bestSolver;
      int combinationsTested = 0;
      int combinationsWithSolution = 0;

      // Tester chaque combinaison
      for (final combination in allCombinations) {
        combinationsTested++;
        
        final solver = PentominoSolver(
          plateau: state.plateau,
          pieces: combination,
        );
        
        final solution = solver.solve();
        
        if (solution != null) {
          combinationsWithSolution++;
          print('[PROVIDER] ✓ Combinaison $combinationsTested/${allCombinations.length}: Solution trouvée avec pièces ${combination.map((p) => p.id).toList()}');
          
          // Garder la première solution trouvée
          if (bestSolution == null) {
            bestPieces = combination;
            bestSolution = solution;
            bestSolver = solver;
          }
        }
      }

      print('[PROVIDER] Résultat: $combinationsWithSolution/${allCombinations.length} combinaisons ont des solutions');

      if (bestSolution != null) {
        state = state.copyWith(
          isSolving: false,
          hasSolution: true,
          solution: bestSolution,
          solver: bestSolver,
          selectedPieces: bestPieces,
          solutionIndex: 1,
          errorMessage: '$combinationsWithSolution/${allCombinations.length} combinaisons OK',
        );
      } else {
        state = state.copyWith(
          isSolving: false,
          hasSolution: false,
          errorMessage: 'Aucune des ${allCombinations.length} combinaisons n\'a de solution',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSolving: false,
        errorMessage: 'Erreur: $e',
        hasSolution: null,
        solution: null,
        solver: null,
        solutionIndex: 0,
      );
    }
  }

  /// Génère toutes les combinaisons de k éléments parmi une liste
  List<List<Pento>> _generateCombinations(List<Pento> items, int k) {
    if (k == 0) return [[]];
    if (items.isEmpty) return [];
    
    final result = <List<Pento>>[];
    
    void combine(int start, List<Pento> current) {
      if (current.length == k) {
        result.add(List.from(current));
        return;
      }
      
      for (int i = start; i < items.length; i++) {
        current.add(items[i]);
        combine(i + 1, current);
        current.removeLast();
      }
    }
    
    combine(0, []);
    return result;
  }

  Future<void> findNextSolution() async {
    if (state.solver == null) return;

    state = state.copyWith(isSolving: true);

    try {
      final nextSolution = state.solver!.findNext();

      if (nextSolution != null) {
        final newIndex = state.solutionIndex + 1;
        print('[PROVIDER] Solution trouvée avec ${nextSolution.length} placements');
        print('[PROVIDER] Premier placement: piece ${nextSolution[0].pieceIndex}, cells: ${nextSolution[0].occupiedCells}');
        print('[PROVIDER] Ancien solutionIndex: ${state.solutionIndex}, nouveau: $newIndex');
        
        // Créer un NOUVEL état pour forcer le rebuild
        state = PlateauEditorState(
          plateau: state.plateau,
          numPieces: state.numPieces,
          isSolving: false,
          hasSolution: true,
          errorMessage: null,
          solution: nextSolution,
          solver: state.solver,
          selectedPieces: state.selectedPieces,
          solutionIndex: newIndex,
        );
        print('[PROVIDER] État mis à jour: solutionIndex=${state.solutionIndex}');
      } else {
        state = state.copyWith(
          isSolving: false,
          errorMessage: 'Aucune autre solution trouvée',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSolving: false,
        errorMessage: 'Erreur: $e',
      );
    }
  }
  
  /// Lance le comptage exhaustif de toutes les solutions
  Future<void> startCountingAll() async {
    final numVisible = state.plateau.numVisibleCells;
    final required = state.numPieces * 5;

    if (numVisible < required) {
      state = state.copyWith(
        errorMessage: 'Pas assez de cases: $numVisible < $required',
      );
      return;
}

    // Initialiser l'état de comptage
    state = PlateauEditorState(
      plateau: state.plateau,
      numPieces: state.numPieces,
      isSolving: false,
      hasSolution: null,
      errorMessage: null,
      solution: null,
      solver: null,
      selectedPieces: null,
      solutionIndex: 0,
      isCountingAll: true,
      totalSolutionsFound: 0,
      countingElapsedSeconds: 0,
    );

    try {
      // Utiliser l'ordre fixe défini dans pentominos.dart (du plus au moins contraignant)
      final selectedPieces = pentominos.take(state.numPieces).toList();

      // Créer le solver
      final solver = PentominoSolver(
        plateau: state.plateau,
        pieces: selectedPieces,
      );
      
      // Stocker le solver dans l'état pour pouvoir l'interrompre
      state = state.copyWith(
        solver: solver,
        selectedPieces: selectedPieces,
      );

      // Lancer le comptage avec callback pour mise à jour temps réel
      final totalCount = await solver.countAllSolutions(
        onProgress: (count, elapsedSeconds) {
          // Mettre à jour l'état directement (le solver yield périodiquement)
          if (state.isCountingAll) {
            state = state.copyWith(
              totalSolutionsFound: count,
              countingElapsedSeconds: elapsedSeconds,
            );
          }
        },
      );

      // Comptage terminé (ou interrompu)
      if (state.isCountingAll) {
        state = state.copyWith(
          isCountingAll: false,
          totalSolutionsFound: totalCount,
        );
      }
      
      print('[PROVIDER] Comptage terminé: $totalCount solutions');
    } catch (e) {
      state = state.copyWith(
        isCountingAll: false,
        errorMessage: 'Erreur comptage: $e',
      );
    }
  }
  
  /// Interrompt le comptage en cours
  void cancelCounting() {
    if (state.isCountingAll && state.solver != null) {
      print('[PROVIDER] Interruption du comptage demandée');
      state.solver!.stopCounting();
      
      // L'état sera mis à jour par le callback onProgress
      // puis par la fin de countAllSolutions()
    }
  }
}

final plateauEditorProvider = NotifierProvider<PlateauEditorNotifier, PlateauEditorState>(
      () => PlateauEditorNotifier(),
);
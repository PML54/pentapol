// DEPRECATED - 2025-11-18
// State désactivé temporairement - Associé à plateau_editor_screen.dart
// 
// Modified: 2025-11-15 06:45:00
// lib/providers/plateau_editor_state.dart

import 'package:flutter/foundation.dart';
import '../models/plateau.dart';
import '../models/pentominos.dart';
import '../services/pentomino_solver.dart';

@immutable
class PlateauEditorState {
  final Plateau plateau;
  final int numPieces;
  final bool isSolving;
  final bool? hasSolution;
  final String? errorMessage;
  final List<PlacementInfo>? solution;
  final PentominoSolver? solver;
  final List<Pento>? selectedPieces;
  final int solutionIndex;
  
  // Comptage exhaustif de toutes les solutions
  final bool isCountingAll;
  final int totalSolutionsFound;
  final int countingElapsedSeconds;
  
  final int _timestamp; // Pour forcer les rebuilds

  PlateauEditorState({
    required this.plateau,
    this.numPieces = 6,
    this.isSolving = false,
    this.hasSolution,
    this.errorMessage,
    this.solution,
    this.solver,
    this.selectedPieces,
    this.solutionIndex = 0,
    this.isCountingAll = false,
    this.totalSolutionsFound = 0,
    this.countingElapsedSeconds = 0,
  }) : _timestamp = DateTime.now().microsecondsSinceEpoch;

  factory PlateauEditorState.initial() => PlateauEditorState(
    plateau: Plateau.allVisible(6, 10),
  );

  PlateauEditorState copyWith({
    Plateau? plateau,
    int? numPieces,
    bool? isSolving,
    bool? hasSolution,
    String? errorMessage,
    List<PlacementInfo>? solution,
    PentominoSolver? solver,
    List<Pento>? selectedPieces,
    int? solutionIndex,
    bool? isCountingAll,
    int? totalSolutionsFound,
    int? countingElapsedSeconds,
  }) {
    // Créer un nouvel état force toujours le rebuild via _timestamp
    return PlateauEditorState(
      plateau: plateau ?? this.plateau,
      numPieces: numPieces ?? this.numPieces,
      isSolving: isSolving ?? this.isSolving,
      hasSolution: hasSolution ?? this.hasSolution,
      errorMessage: errorMessage ?? this.errorMessage,
      solution: solution ?? this.solution,
      solver: solver ?? this.solver,
      selectedPieces: selectedPieces ?? this.selectedPieces,
      solutionIndex: solutionIndex ?? this.solutionIndex,
      isCountingAll: isCountingAll ?? this.isCountingAll,
      totalSolutionsFound: totalSolutionsFound ?? this.totalSolutionsFound,
      countingElapsedSeconds: countingElapsedSeconds ?? this.countingElapsedSeconds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlateauEditorState &&
              runtimeType == other.runtimeType &&
              _timestamp == other._timestamp;

  @override
  int get hashCode => _timestamp.hashCode;
}
// Modified: 2025-11-15 07:16:29
// lib/providers/pentomino_game_provider.dart
// Provider pour gérer l'état du jeu de pentominos

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pentomino_game_state.dart';
import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';
import '../services/plateau_solution_counter.dart' show PlateauSolutionCounter;

class PentominoGameNotifier extends Notifier<PentominoGameState> {
  @override
  PentominoGameState build() {
    return PentominoGameState.initial();
  }

  /// Réinitialise le jeu
  void reset() {
    state = PentominoGameState.initial();
  }

  /// Sélectionne une pièce du slider (commence le drag)
  void selectPiece(Pento piece) {
    // Récupérer l'index de position sauvegardé pour cette pièce
    final savedIndex = state.getPiecePositionIndex(piece.id);
    // Si une pièce du plateau est déjà sélectionnée, la replacer d'abord
    if (state.selectedPlacedPiece != null) {
      final placedPiece = state.selectedPlacedPiece!;

      // Reconstruire le plateau avec la pièce replacée
      final newPlateau = Plateau.allVisible(6, 10);

      // Replacer toutes les pièces déjà placées
      for (final placed in state.placedPieces) {
        final position = placed.piece.positions[placed.positionIndex];

        for (final cellNum in position) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          newPlateau.setCell(x, y, placed.piece.id);
        }
      }

      // Replacer la pièce qui était sélectionnée
      final position = placedPiece.piece.positions[state.selectedPositionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placedPiece.gridX + localX;
        final y = placedPiece.gridY + localY;
        if (x >= 0 && x < 6 && y >= 0 && y < 10) {
          newPlateau.setCell(x, y, placedPiece.piece.id);
        }
      }

      // Remettre la pièce dans les placées
      final newPlaced = List<PlacedPiece>.from(state.placedPieces)
        ..add(placedPiece.copyWith(positionIndex: state.selectedPositionIndex));

      state = state.copyWith(
        plateau: newPlateau,
        placedPieces: newPlaced,
      );
    }

    // Définir une case de référence par défaut (première case de la pièce)
    final position = piece.positions[savedIndex];
    Point? defaultCell;
    if (position.isNotEmpty) {
      final firstCellNum = position[0];
      defaultCell = Point((firstCellNum - 1) % 5, (firstCellNum - 1) ~/ 5);
    }

    state = state.copyWith(
      selectedPiece: piece,
      selectedPositionIndex: savedIndex, // Utilise l'index sauvegardé
      clearSelectedPlacedPiece: true,
      selectedCellInPiece: defaultCell,
    );
  }

  /// Change la position de la pièce sélectionnée (tap pour rotation)
  void cyclePosition() {
    if (state.selectedPiece == null) return;

    final piece = state.selectedPiece!;
    final numPositions = piece.positions.length;
    final nextIndex = (state.selectedPositionIndex + 1) % numPositions;

    // Sauvegarder le nouvel index dans le Map
    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = nextIndex;

    // Si c'est une pièce placée, mettre à jour sa référence aussi
    PlacedPiece? updatedPlacedPiece;
    if (state.selectedPlacedPiece != null) {
      updatedPlacedPiece = state.selectedPlacedPiece!.copyWith(
        positionIndex: nextIndex,
      );
    }

    state = state.copyWith(
      selectedPositionIndex: nextIndex,
      selectedPlacedPiece: updatedPlacedPiece,
      piecePositionIndices: newIndices,
    );

    print('[GAME] Position changée: $nextIndex / $numPositions (sauvegardé pour pièce ${piece.id})');
  }

  /// Tente de placer la pièce sélectionnée sur le plateau
  /// [gridX] et [gridY] sont les coordonnées où on lâche la pièce (position du doigt)
  bool tryPlacePiece(int gridX, int gridY) {
    if (state.selectedPiece == null) return false;

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;

    // Calculer la position d'ancrage en utilisant la case de référence
    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      // Translation : la case de référence doit être placée à (gridX, gridY)
      // Donc la position d'ancrage = position de lâcher - position locale de la case de référence
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;

      print('[GAME] Translation: lâcher à ($gridX, $gridY), case ref locale (${state.selectedCellInPiece!.x}, ${state.selectedCellInPiece!.y}), anchor ($anchorX, $anchorY)');
    }

    // Vérifier si la pièce peut être placée
    if (!state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      print('[GAME] ❌ Placement impossible à ($anchorX, $anchorY)');
      return false;
    }

    // Créer une copie du plateau et placer la pièce
    final newGrid = List.generate(
      state.plateau.height,
          (y) => List.generate(
        state.plateau.width,
            (x) => state.plateau.getCell(x, y),
      ),
    );

    final newPlateau = Plateau(
      width: state.plateau.width,
      height: state.plateau.height,
      grid: newGrid,
    );

    // Placer la nouvelle pièce
    final position = piece.positions[positionIndex];

    for (final cellNum in position) {
      // Convertir cellNum (1-25 sur grille 5×5) en coordonnées (x, y)
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;

      // Position absolue sur le plateau (utiliser anchorX/anchorY)
      final x = anchorX + localX;
      final y = anchorY + localY;

      newPlateau.setCell(x, y, piece.id);
    }

    // Créer l'objet PlacedPiece
    final placedPiece = PlacedPiece(
      piece: piece,
      positionIndex: positionIndex,
      gridX: anchorX,
      gridY: anchorY,
    );

    // Retirer la pièce des disponibles
    final newAvailable = List<Pento>.from(state.availablePieces)
      ..removeWhere((p) => p.id == piece.id);

    // Ajouter aux pièces placées
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)
      ..add(placedPiece);

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlateau.countPossibleSolutions();

    // Mettre à jour l'état
    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      solutionsCount: solutionsCount,
    );

    print('[GAME] ✅ Pièce ${piece.id} placée à ($anchorX, $anchorY)');
    print('[GAME] Pièces restantes: ${newAvailable.length}');
    print('[GAME] 🎯 Solutions possibles: $solutionsCount');

    return true;
  }

  /// Annule la sélection en cours
  void cancelSelection() {
    if (state.selectedPiece == null) return;

    // Si c'est une pièce placée, la replacer sur le plateau
    if (state.selectedPlacedPiece != null) {
      final placedPiece = state.selectedPlacedPiece!;

      // Reconstruire le plateau avec toutes les pièces placées + celle qui était sélectionnée
      final newPlateau = Plateau.allVisible(6, 10);

      // Replacer toutes les pièces déjà placées
      for (final placed in state.placedPieces) {
        final position = placed.piece.positions[placed.positionIndex];

        for (final cellNum in position) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          newPlateau.setCell(x, y, placed.piece.id);
        }
      }

      // Replacer la pièce qui était sélectionnée à sa position d'origine
      final position = placedPiece.piece.positions[state.selectedPositionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placedPiece.gridX + localX;
        final y = placedPiece.gridY + localY;
        if (x >= 0 && x < 6 && y >= 0 && y < 10) {
          newPlateau.setCell(x, y, placedPiece.piece.id);
        }
      }

      // Remettre la pièce dans les placées avec sa nouvelle position si elle a été modifiée
      final updatedPlacedPiece = placedPiece.copyWith(positionIndex: state.selectedPositionIndex);
      final newPlaced = List<PlacedPiece>.from(state.placedPieces)
        ..add(updatedPlacedPiece);

      state = state.copyWith(
        plateau: newPlateau,
        placedPieces: newPlaced,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
      );

      print('[GAME] ❌ Sélection annulée, pièce replacée sur le plateau');
    } else {
      // C'est une pièce du slider, juste annuler la sélection
      state = state.copyWith(
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
      );
      print('[GAME] ❌ Sélection annulée');
    }
  }

  /// Sélectionne une pièce déjà placée pour la déplacer
  /// [cellX] et [cellY] sont les coordonnées de la case touchée sur le plateau
  void selectPlacedPiece(PlacedPiece placedPiece, int cellX, int cellY) {
    // Si une autre pièce du plateau est déjà sélectionnée, la replacer d'abord
    if (state.selectedPlacedPiece != null && state.selectedPlacedPiece != placedPiece) {
      final oldPiece = state.selectedPlacedPiece!;
      
      // Reconstruire le plateau avec l'ancienne pièce replacée
      final tempPlateau = Plateau.allVisible(6, 10);
      
      // Replacer toutes les pièces déjà placées
      for (final placed in state.placedPieces) {
        final pos = placed.piece.positions[placed.positionIndex];
        for (final cellNum in pos) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          tempPlateau.setCell(x, y, placed.piece.id);
        }
      }
      
      // Replacer l'ancienne pièce sélectionnée
      final oldPosition = oldPiece.piece.positions[state.selectedPositionIndex];
      for (final cellNum in oldPosition) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = oldPiece.gridX + localX;
        final y = oldPiece.gridY + localY;
        if (x >= 0 && x < 6 && y >= 0 && y < 10) {
          tempPlateau.setCell(x, y, oldPiece.piece.id);
        }
      }
      
      // Remettre l'ancienne pièce dans la liste des placées
      final tempPlaced = List<PlacedPiece>.from(state.placedPieces)
        ..add(oldPiece.copyWith(positionIndex: state.selectedPositionIndex));
      
      // Mettre à jour l'état avec le plateau et la liste mis à jour
      state = state.copyWith(
        plateau: tempPlateau,
        placedPieces: tempPlaced,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
      );
    }
    
    // Trouver quelle case de la pièce correspond à (cellX, cellY)
    final position = placedPiece.piece.positions[placedPiece.positionIndex];
    Point? selectedCell;

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = placedPiece.gridX + localX;
      final y = placedPiece.gridY + localY;

      if (x == cellX && y == cellY) {
        // C'est cette case qui a été touchée
        selectedCell = Point(localX, localY);
        break;
      }
    }

    // Si aucune case trouvée, utiliser la première case de la pièce
    if (selectedCell == null && position.isNotEmpty) {
      final firstCellNum = position[0];
      selectedCell = Point((firstCellNum - 1) % 5, (firstCellNum - 1) ~/ 5);
    }

    // Retirer la pièce du plateau
    final newPlateau = Plateau.allVisible(6, 10);

    // Replacer toutes les pièces SAUF celle sélectionnée
    for (final placed in state.placedPieces) {
      if (placed != placedPiece) {
        final pos = placed.piece.positions[placed.positionIndex];

        for (final cellNum in pos) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          newPlateau.setCell(x, y, placed.piece.id);
        }
      }
    }

    // Retirer la pièce de la liste des placées
    final newPlaced = state.placedPieces.where((p) => p != placedPiece).toList();

    // Sélectionner la pièce avec sa position actuelle et la case de référence
    state = state.copyWith(
      plateau: newPlateau,
      placedPieces: newPlaced,
      selectedPiece: placedPiece.piece,
      selectedPositionIndex: placedPiece.positionIndex,
      selectedPlacedPiece: placedPiece,
      selectedCellInPiece: selectedCell,
    );

    print('[GAME] 🔄 Pièce ${placedPiece.piece.id} sélectionnée pour déplacement (case ref: $selectedCell)');
  }

  /// Trouve la pièce placée à une position donnée
  PlacedPiece? getPlacedPieceAt(int gridX, int gridY) {
    for (final placed in state.placedPieces) {
      final position = placed.piece.positions[placed.positionIndex];

      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placed.gridX + localX;
        final y = placed.gridY + localY;

        if (x == gridX && y == gridY) {
          return placed;
        }
      }
    }
    return null;
  }

  /// Retire la dernière pièce placée (undo)
  void undoLastPlacement() {
    if (state.placedPieces.isEmpty) return;

    final lastPlaced = state.placedPieces.last;

    // Recréer le plateau sans cette pièce
    final newPlateau = Plateau.allVisible(6, 10);

    // Replacer toutes les pièces sauf la dernière
    for (int i = 0; i < state.placedPieces.length - 1; i++) {
      final placed = state.placedPieces[i];
      final position = placed.piece.positions[placed.positionIndex];

      for (final cellNum in position) {
        // Convertir cellNum (1-25 sur grille 5×5) en coordonnées (x, y)
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;

        // Position absolue sur le plateau
        final x = placed.gridX + localX;
        final y = placed.gridY + localY;

        newPlateau.setCell(x, y, placed.piece.id);
      }
    }

    // Remettre la pièce dans les disponibles
    final newAvailable = List<Pento>.from(state.availablePieces)
      ..add(lastPlaced.piece);

    // Retrier par ID pour garder l'ordre
    newAvailable.sort((a, b) => a.id.compareTo(b.id));

    // Retirer de la liste des placées
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)
      ..removeLast();

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlaced.isEmpty ? null : newPlateau.countPossibleSolutions();

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      solutionsCount: solutionsCount,
    );

    print('[GAME] ↩️ Undo: Pièce ${lastPlaced.piece.id} retirée');
    if (solutionsCount != null) {
      print('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }
  }

  /// Met à jour la prévisualisation du placement pendant le drag
  void updatePreview(int gridX, int gridY) {
    if (state.selectedPiece == null) {
      // Effacer la preview si aucune pièce sélectionnée
      if (state.previewX != null || state.previewY != null) {
        state = state.copyWith(clearPreview: true);
      }
      return;
    }

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;

    // Calculer la position d'ancrage avec la case de référence
    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;
    }

    // Vérifier si le placement est valide
    final isValid = state.canPlacePiece(piece, positionIndex, anchorX, anchorY);

    // Mettre à jour la preview seulement si changement
    if (state.previewX != anchorX || state.previewY != anchorY || state.isPreviewValid != isValid) {
      state = state.copyWith(
        previewX: anchorX,
        previewY: anchorY,
        isPreviewValid: isValid,
      );
    }
  }

  /// Efface la prévisualisation
  void clearPreview() {
    if (state.previewX != null || state.previewY != null) {
      state = state.copyWith(clearPreview: true);
    }
  }

  /// Retire une pièce placée du plateau
  void removePlacedPiece(PlacedPiece placedPiece) {
    // Reconstruire le plateau sans cette pièce
    final newPlateau = Plateau.allVisible(6, 10);

    // Replacer toutes les pièces sauf celle à retirer
    for (final placed in state.placedPieces) {
      if (placed != placedPiece) {
        final position = placed.piece.positions[placed.positionIndex];

        for (final cellNum in position) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          newPlateau.setCell(x, y, placed.piece.id);
        }
      }
    }

    // Remettre la pièce dans les disponibles
    final newAvailable = List<Pento>.from(state.availablePieces)
      ..add(placedPiece.piece);

    // Retrier par ID pour garder l'ordre
    newAvailable.sort((a, b) => a.id.compareTo(b.id));

    // Retirer de la liste des placées
    final newPlaced = state.placedPieces.where((p) => p != placedPiece).toList();

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlaced.isEmpty ? null : newPlateau.countPossibleSolutions();

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      solutionsCount: solutionsCount,
    );

    print('[GAME] 🗑️ Pièce ${placedPiece.piece.id} retirée du plateau');
    if (solutionsCount != null) {
      print('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }
  }
}

final pentominoGameProvider = NotifierProvider<PentominoGameNotifier, PentominoGameState>(
      () => PentominoGameNotifier(),
);
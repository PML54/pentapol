// Modified: 2025-11-20 (Transformations géométriques)
// lib/providers/pentomino_game_provider.dart
// Provider pour gérer l'état du jeu de pentominos

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pentomino_game_state.dart';
import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';
import '../services/plateau_solution_counter.dart' show PlateauSolutionCounter;
import '../services/isometry_transforms.dart';
import '../services/shape_recognizer.dart';

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

  /// Entre en mode isométries (sauvegarde l'état actuel)
  void enterIsometriesMode() {
    if (state.isIsometriesMode) return; // Déjà en mode isométries

    print('[GAME] 🎓 Entrée en mode isométries');

    // Sauvegarder l'état actuel (sans le savedGameState pour éviter la récursion)
    final savedState = PentominoGameState(
      plateau: state.plateau,
      availablePieces: List.from(state.availablePieces),
      placedPieces: List.from(state.placedPieces),
      selectedPiece: state.selectedPiece,
      selectedPositionIndex: state.selectedPositionIndex,
      selectedPlacedPiece: state.selectedPlacedPiece,
      piecePositionIndices: Map.from(state.piecePositionIndices),
      selectedCellInPiece: state.selectedCellInPiece,
      previewX: state.previewX,
      previewY: state.previewY,
      isPreviewValid: state.isPreviewValid,
      solutionsCount: state.solutionsCount,
    );

    // Passer en mode isométries
    state = state.copyWith(
      isIsometriesMode: true,
      savedGameState: savedState,
    );
  }

  /// Sort du mode isométries (restaure l'état sauvegardé)
  void exitIsometriesMode() {
    if (!state.isIsometriesMode) return; // Pas en mode isométries
    if (state.savedGameState == null) {
      print('[GAME] ⚠️ Impossible de sortir du mode isométries : pas d\'état sauvegardé');
      return;
    }

    print('[GAME] 🎓 Sortie du mode isométries');

    // Restaurer l'état sauvegardé
    state = state.savedGameState!;
  }

  /// Extrait les coordonnées absolues d'une pièce placée
  List<List<int>> _extractAbsoluteCoords(PlacedPiece piece) {
    final position = piece.piece.positions[piece.positionIndex];
    return position.map((cellNum) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      return [piece.gridX + localX, piece.gridY + localY];
    }).toList();
  }

  /// Vérifie si une pièce peut être placée à une position donnée
  /// Utilisé après une transformation géométrique
  bool _canPlacePieceAt(ShapeMatch match, PlacedPiece? excludePiece) {
    final position = match.piece.positions[match.positionIndex];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final absX = match.gridX + localX;
      final absY = match.gridY + localY;

      // Vérifier les limites
      if (!state.plateau.isInBounds(absX, absY)) {
        return false;
      }

      // Vérifier si la cellule est libre (ou occupée par la pièce qu'on transforme)
      final cell = state.plateau.getCell(absX, absY);
      if (cell != 0 && (excludePiece == null || cell != excludePiece.piece.id)) {
        return false;
      }
    }

    return true;
  }

  /// Efface une pièce du plateau (utilisé pendant les transformations)
  void _clearPieceFromPlateau(PlacedPiece piece) {
    final position = piece.piece.positions[piece.positionIndex];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = piece.gridX + localX;
      final y = piece.gridY + localY;

      if (state.plateau.isInBounds(x, y)) {
        state.plateau.setCell(x, y, 0);
      }
    }
  }

  /// Place une pièce sur le plateau selon un ShapeMatch
  void _placePieceOnPlateau(ShapeMatch match) {
    final position = match.piece.positions[match.positionIndex];

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = match.gridX + localX;
      final y = match.gridY + localY;

      if (state.plateau.isInBounds(x, y)) {
        state.plateau.setCell(x, y, match.piece.id);
      }
    }
  }

  /// Calcule la nouvelle position locale de la master case après une transformation
  /// [centerX], [centerY] : coordonnées absolues de la master case (fixe)
  /// [newGridX], [newGridY] : nouvelle ancre de la pièce transformée
  Point _calculateNewMasterCell(int centerX, int centerY, int newGridX, int newGridY) {
    final newLocalX = centerX - newGridX;
    final newLocalY = centerY - newGridY;
    return Point(newLocalX, newLocalY);
  }

  /// Applique une rotation 90° anti-horaire à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// En mode isométries : rotation géométrique autour du point de référence (cellule rouge)
  void applyIsometryRotation() {
    // En mode isométries : transformer une pièce placée avec rotation géométrique
    if (state.isIsometriesMode && state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;

      // 1. Extraire les coordonnées absolues actuelles
      final currentCoords = _extractAbsoluteCoords(selectedPiece);

      // 2. Déterminer le centre de rotation P0
      // Si une cellule de référence est définie, utiliser celle-ci
      // Sinon, utiliser le coin bas-gauche de la pièce (0,0) local
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();

      final centerX = selectedPiece.gridX + refX;
      final centerY = selectedPiece.gridY + refY;

      print('[GAME] 🔄 Rotation 90° autour de ($centerX, $centerY)');
      print('[GAME] 📍 Coordonnées avant rotation : $currentCoords');

      // 3. Appliquer la rotation autour de P0
      final rotatedCoords = rotateAroundPoint(
        currentCoords,
        centerX,
        centerY,
        1, // 90° anti-horaire
      );

      print('[GAME] 📍 Coordonnées après rotation : $rotatedCoords');

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(rotatedCoords);

      if (match == null) {
        print('[GAME] ❌ Transformation invalide (forme non reconnue)');
        print('[GAME] 🔍 Impossible de trouver une correspondance dans pentominos.dart');

        // Debug : afficher les coordonnées normalisées
        final minX = rotatedCoords.map((c) => c[0]).reduce((a, b) => a < b ? a : b);
        final minY = rotatedCoords.map((c) => c[1]).reduce((a, b) => a < b ? a : b);
        final normalized = rotatedCoords.map((c) => [c[0] - minX, c[1] - minY]).toList();
        normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
        print('[GAME] 🔍 Forme normalisée recherchée : $normalized');

        return;
      }

      // 5. Vérifier si la nouvelle position est valide sur le plateau
      if (!_canPlacePieceAt(match, selectedPiece)) {
        print('[GAME] ❌ La pièce sort du plateau ou chevauche une autre pièce');
        return;
      }

      print('[GAME] ✅ Rotation réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})');

      // 6. Créer une copie du plateau
      final newPlateau = state.plateau.copy();

      // 7. Effacer l'ancienne pièce du plateau temporaire
      final position = selectedPiece.piece.positions[selectedPiece.positionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = selectedPiece.gridX + localX;
        final y = selectedPiece.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, 0);
        }
      }

      // 8. Placer la nouvelle pièce
      final newPosition = match.piece.positions[match.positionIndex];
      for (final cellNum in newPosition) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = match.gridX + localX;
        final y = match.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, match.piece.id);
        }
      }

      // 9. Créer la nouvelle pièce placée
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 10. Calculer la nouvelle position locale de la master case
      final newSelectedCell = _calculateNewMasterCell(centerX, centerY, match.gridX, match.gridY);
      print('[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local');

      // 11. Mettre à jour la liste des pièces placées
      final updatedPieces = state.placedPieces.map((placed) {
        return placed == selectedPiece ? transformedPiece : placed;
      }).toList();

      // 12. Mettre à jour l'état avec la nouvelle master case
      state = state.copyWith(
        placedPieces: updatedPieces,
        plateau: newPlateau,
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
      );

      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Trouver la position correspondant à une rotation de 90°
      final nextIndex = piece.findRotation90(currentIndex);

      // Si aucune rotation trouvée (pièce symétrique), ne rien faire
      if (nextIndex == -1) {
        print('[GAME] ⚠️ Aucune rotation disponible pour cette pièce (symétrique)');
        return;
      }

      print('[GAME] 🔄 Rotation 90° anti-horaire de la pièce sélectionnée');

      // Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = nextIndex;

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: nextIndex,
        piecePositionIndices: newIndices,
      );
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la rotation');
  }

  /// Applique une symétrie horizontale à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// En mode isométries : symétrie géométrique par rapport à y = y0
  void applyIsometrySymmetryH() {
    // En mode isométries : transformer une pièce placée avec symétrie géométrique
    if (state.isIsometriesMode && state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;

      // 1. Extraire les coordonnées absolues actuelles
      final currentCoords = _extractAbsoluteCoords(selectedPiece);

      // 2. Déterminer l'axe de symétrie y = y0
      // Si une cellule de référence est définie, utiliser celle-ci
      // Sinon, utiliser le coin bas-gauche de la pièce (0,0) local
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();
      final axisY = selectedPiece.gridY + refY;

      print('[GAME] ↔️ Symétrie horizontale par rapport à y = $axisY');

      // 3. Appliquer la symétrie horizontale
      final flippedCoords = flipHorizontal(currentCoords, axisY);

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(flippedCoords);

      if (match == null) {
        print('[GAME] ❌ Transformation invalide (forme non reconnue)');
        return;
      }

      // 5. Vérifier si la nouvelle position est valide sur le plateau
      if (!_canPlacePieceAt(match, selectedPiece)) {
        print('[GAME] ❌ La pièce sort du plateau ou chevauche une autre pièce');
        return;
      }

      print('[GAME] ✅ Symétrie horizontale réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})');

      // 6. Créer une copie du plateau
      final newPlateau = state.plateau.copy();

      // 7. Effacer l'ancienne pièce
      final position = selectedPiece.piece.positions[selectedPiece.positionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = selectedPiece.gridX + localX;
        final y = selectedPiece.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, 0);
        }
      }

      // 8. Placer la nouvelle pièce
      final newPosition = match.piece.positions[match.positionIndex];
      for (final cellNum in newPosition) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = match.gridX + localX;
        final y = match.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, match.piece.id);
        }
      }

      // 9. Créer la nouvelle pièce placée
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 10. Calculer la nouvelle position locale de la master case
      // Pour la symétrie horizontale, centerX reste fixe, centerY = axisY
      final centerX = selectedPiece.gridX + refX;
      final centerY = axisY;
      final newSelectedCell = _calculateNewMasterCell(centerX, centerY, match.gridX, match.gridY);
      print('[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local');

      // 11. Mettre à jour la liste des pièces placées
      final updatedPieces = state.placedPieces.map((placed) {
        return placed == selectedPiece ? transformedPiece : placed;
      }).toList();

      // 12. Mettre à jour l'état avec la nouvelle master case
      state = state.copyWith(
        placedPieces: updatedPieces,
        plateau: newPlateau,
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
      );

      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Trouver la position correspondant à une symétrie horizontale
      final nextIndex = piece.findSymmetryH(currentIndex);

      // Si aucune symétrie trouvée, ne rien faire
      if (nextIndex == -1) {
        print('[GAME] ⚠️ Aucune symétrie horizontale disponible pour cette pièce');
        return;
      }

      print('[GAME] ↔️ Symétrie horizontale de la pièce sélectionnée');

      // Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = nextIndex;

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: nextIndex,
        piecePositionIndices: newIndices,
      );
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la symétrie');
  }

  /// Applique une symétrie verticale à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// En mode isométries : symétrie géométrique par rapport à x = x0
  void applyIsometrySymmetryV() {
    // En mode isométries : transformer une pièce placée avec symétrie géométrique
    if (state.isIsometriesMode && state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;

      // 1. Extraire les coordonnées absolues actuelles
      final currentCoords = _extractAbsoluteCoords(selectedPiece);

      // 2. Déterminer l'axe de symétrie x = x0
      // Si une cellule de référence est définie, utiliser celle-ci
      // Sinon, utiliser le coin bas-gauche de la pièce (0,0) local
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();
      final axisX = selectedPiece.gridX + refX;

      print('[GAME] ↕️ Symétrie verticale par rapport à x = $axisX');

      // 3. Appliquer la symétrie verticale
      final flippedCoords = flipVertical(currentCoords, axisX);

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(flippedCoords);

      if (match == null) {
        print('[GAME] ❌ Transformation invalide (forme non reconnue)');
        return;
      }

      // 5. Vérifier si la nouvelle position est valide sur le plateau
      if (!_canPlacePieceAt(match, selectedPiece)) {
        print('[GAME] ❌ La pièce sort du plateau ou chevauche une autre pièce');
        return;
      }

      print('[GAME] ✅ Symétrie verticale réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})');

      // 6. Créer une copie du plateau
      final newPlateau = state.plateau.copy();

      // 7. Effacer l'ancienne pièce
      final position = selectedPiece.piece.positions[selectedPiece.positionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = selectedPiece.gridX + localX;
        final y = selectedPiece.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, 0);
        }
      }

      // 8. Placer la nouvelle pièce
      final newPosition = match.piece.positions[match.positionIndex];
      for (final cellNum in newPosition) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = match.gridX + localX;
        final y = match.gridY + localY;
        if (newPlateau.isInBounds(x, y)) {
          newPlateau.setCell(x, y, match.piece.id);
        }
      }

      // 9. Créer la nouvelle pièce placée
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 10. Calculer la nouvelle position locale de la master case
      // Pour la symétrie verticale, centerX = axisX, centerY reste fixe
      final centerX = axisX;
      final centerY = selectedPiece.gridY + refY;
      final newSelectedCell = _calculateNewMasterCell(centerX, centerY, match.gridX, match.gridY);
      print('[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local');

      // 11. Mettre à jour la liste des pièces placées
      final updatedPieces = state.placedPieces.map((placed) {
        return placed == selectedPiece ? transformedPiece : placed;
      }).toList();

      // 12. Mettre à jour l'état avec la nouvelle master case
      state = state.copyWith(
        placedPieces: updatedPieces,
        plateau: newPlateau,
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
      );

      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Trouver la position correspondant à une symétrie verticale
      final nextIndex = piece.findSymmetryV(currentIndex);

      // Si aucune symétrie trouvée, ne rien faire
      if (nextIndex == -1) {
        print('[GAME] ⚠️ Aucune symétrie verticale disponible pour cette pièce');
        return;
      }

      print('[GAME] ↕️ Symétrie verticale de la pièce sélectionnée');

      // Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = nextIndex;

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: nextIndex,
        piecePositionIndices: newIndices,
      );
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la symétrie');
  }

  /// Méthode helper pour appliquer une transformation (OBSOLÈTE - conservée pour compatibilité)
  /// Les nouvelles transformations géométriques sont gérées directement dans
  /// applyIsometryRotation, applyIsometrySymmetryH, applyIsometrySymmetryV
  void _applyTransformation(int nextIndex) {
    if (state.selectedPlacedPiece == null) return;

    final selectedPiece = state.selectedPlacedPiece!;

    // Créer la pièce transformée
    final transformedPiece = selectedPiece.copyWith(positionIndex: nextIndex);

    // Mettre à jour la liste des pièces placées
    final updatedPieces = state.placedPieces.map((placed) {
      return placed == selectedPiece ? transformedPiece : placed;
    }).toList();

    // Reconstruire le plateau
    final newPlateau = Plateau.allVisible(6, 10);

    for (final placed in updatedPieces) {
      final position = placed.piece.positions[placed.positionIndex];

      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placed.gridX + localX;
        final y = placed.gridY + localY;

        if (x >= 0 && x < 6 && y >= 0 && y < 10) {
          newPlateau.setCell(x, y, placed.piece.id);
        }
      }
    }

    // Mettre à jour l'état (la pièce reste sélectionnée avec sa nouvelle orientation)
    state = state.copyWith(
      placedPieces: updatedPieces,
      plateau: newPlateau,
      selectedPlacedPiece: transformedPiece,
      selectedPositionIndex: nextIndex,
    );
  }
}

final pentominoGameProvider = NotifierProvider<PentominoGameNotifier, PentominoGameState>(
      () => PentominoGameNotifier(),
);
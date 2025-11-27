// Modified: 2025-11-25 (Ajout support tutoriel)
// lib/providers/pentomino_game_provider.dart
// Provider pour gérer l'état du jeu de pentominos

import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pentominos.dart';
import '../models/plateau.dart';
import '../models/point.dart';
import '../services/isometry_transforms.dart';
import '../services/plateau_solution_counter.dart' show PlateauSolutionCounter;
import '../services/shape_recognizer.dart';
import 'pentomino_game_state.dart';

final pentominoGameProvider =
NotifierProvider<PentominoGameNotifier, PentominoGameState>(
      () => PentominoGameNotifier(),
);

class PentominoGameNotifier extends Notifier<PentominoGameState> {
  /// Applique une rotation 90° anti-horaire à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// Rotation géométrique autour du point de référence (cellule rouge / mastercase)
  void applyIsometryRotation() {
    // Transformer une pièce placée avec rotation géométrique (mode game ET isométries)
    if (state.selectedPlacedPiece != null) {
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



      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(rotatedCoords);

      if (match == null) {
        print('[GAME] ❌ Transformation invalide (forme non reconnue)');
        print(
          '[GAME] 🔍 Impossible de trouver une correspondance dans pentominos.dart',
        );

        // Debug : afficher les coordonnées normalisées
        final minX = rotatedCoords
            .map((c) => c[0])
            .reduce((a, b) => a < b ? a : b);
        final minY = rotatedCoords
            .map((c) => c[1])
            .reduce((a, b) => a < b ? a : b);
        final normalized = rotatedCoords
            .map((c) => [c[0] - minX, c[1] - minY])
            .toList();
        normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
        print('[GAME] 🔍 Forme normalisée recherchée : $normalized');

        return;
      }

      // 5. Vérifier si la nouvelle position est valide sur le plateau
      if (!_canPlacePieceAt(match, selectedPiece)) {
        print('[GAME] ❌ La pièce sort du plateau ou chevauche une autre pièce');
        return;
      }

      print(
        '[GAME] ✅ Rotation réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})',
      );

      // 6. Créer la nouvelle pièce placée (transformée)
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 7. Calculer la nouvelle position locale de la master case
      final newSelectedCell = _calculateNewMasterCell(
        centerX,
        centerY,
        match.gridX,
        match.gridY,
      );
      print(
        '[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local',
      );

      // 8. NE PAS modifier placedPieces ni le plateau
      // La pièce reste hors du plateau (elle a été retirée lors de la sélection)
      // et sera replacée quand l'utilisateur cliquera ailleurs

      // 9. Recalculer les solutions possibles avec la nouvelle configuration
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      print(
        '[GAME] 🎯 Solutions possibles après rotation anti-horaire : $solutionsCount',
      );

      // 10. Mettre à jour l'état avec la nouvelle pièce transformée (toujours sélectionnée)
      state = state.copyWith(
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Utiliser les transformations géométriques comme en mode isométries
      // 1. Extraire les coordonnées de la position actuelle (normalisées)
      final currentCoords = piece.cartesianCoords[currentIndex];

      // 2. Déterminer le centre de rotation (centre de la pièce locale)
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();

      // 3. Appliquer la rotation autour du centre local
      final rotatedCoords = rotateAroundPoint(currentCoords, refX, refY, 1);

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(rotatedCoords);

      if (match == null || match.piece.id != piece.id) {
        print(
          '[GAME] ⚠️ Aucune rotation disponible pour cette pièce (symétrique)',
        );
        return;
      }

      print(
        '[GAME] 🔄 Rotation 90° anti-horaire de la pièce sélectionnée (position $currentIndex → ${match.positionIndex})',
      );

      // 5. Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = match.positionIndex;

      // 6. Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: match.positionIndex,
        piecePositionIndices: newIndices,
      );
      _recomputeBoardValidity();
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la rotation');
  }

  /// Applique une rotation 90° horaire à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// Rotation géométrique autour du point de référence (cellule rouge / mastercase)
  void applyIsometryRotationCW() {
    // Transformer une pièce placée avec rotation géométrique (mode game ET isométries)
    print('[DEBUG] 🔥 applyIsometryRotationCW appelée !');


    if (state.selectedPlacedPiece != null) {
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

      print('[GAME] 🔃 Rotation 90° horaire autour de ($centerX, $centerY)');
      print('[GAME] 📍 Coordonnées avant rotation : $currentCoords');

      // 3. Appliquer la rotation autour de P0
      final rotatedCoords = rotateAroundPoint(
        currentCoords,
        centerX,
        centerY,
        3, // 90° horaire (= 270° anti-horaire)
      );

      print('[GAME] 📍 Coordonnées après rotation : $rotatedCoords');

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(rotatedCoords);

      if (match == null) {
        print('[GAME] ❌ Transformation invalide (forme non reconnue)');
        print(
          '[GAME] 🔍 Impossible de trouver une correspondance dans pentominos.dart',
        );

        // Debug : afficher les coordonnées normalisées
        final minX = rotatedCoords
            .map((c) => c[0])
            .reduce((a, b) => a < b ? a : b);
        final minY = rotatedCoords
            .map((c) => c[1])
            .reduce((a, b) => a < b ? a : b);
        final normalized = rotatedCoords
            .map((c) => [c[0] - minX, c[1] - minY])
            .toList();
        normalized.sort((a, b) => a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);
        print('[GAME] 🔍 Forme normalisée recherchée : $normalized');

        return;
      }

      // 5. Vérifier si la nouvelle position est valide sur le plateau
      if (!_canPlacePieceAt(match, selectedPiece)) {
        print('[GAME] ❌ La pièce sort du plateau ou chevauche une autre pièce');
        return;
      }

      print(
        '[GAME] ✅ Rotation horaire réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})',
      );

      // 6. Créer la nouvelle pièce placée (transformée)
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 7. Calculer la nouvelle position locale de la master case
      final newSelectedCell = _calculateNewMasterCell(
        centerX,
        centerY,
        match.gridX,
        match.gridY,
      );
      print(
        '[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local',
      );

      // 8. NE PAS modifier placedPieces ni le plateau
      // La pièce reste hors du plateau (elle a été retirée lors de la sélection)
      // et sera replacée quand l'utilisateur cliquera ailleurs

      // 9. Recalculer les solutions possibles avec la nouvelle configuration
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      print(
        '[GAME] 🎯 Solutions possibles après rotation horaire : $solutionsCount',
      );

      // 10. Mettre à jour l'état avec la nouvelle pièce transformée (toujours sélectionnée)
      state = state.copyWith(
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Utiliser les transformations géométriques comme en mode isométries
      // 1. Extraire les coordonnées de la position actuelle (normalisées)
      final currentCoords = piece.cartesianCoords[currentIndex];

      // 2. Déterminer le centre de rotation (centre de la pièce locale)
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();

      // 3. Appliquer la rotation autour du centre local
      final rotatedCoords = rotateAroundPoint(
        currentCoords,
        refX,
        refY,
        3,
      ); // 90° horaire

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(rotatedCoords);

      if (match == null || match.piece.id != piece.id) {
        print(
          '[GAME] ⚠️ Aucune rotation disponible pour cette pièce (symétrique)',
        );
        return;
      }

      print(
        '[GAME] 🔃 Rotation 90° horaire de la pièce sélectionnée (position $currentIndex → ${match.positionIndex})',
      );

      // 5. Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = match.positionIndex;

      // 6. Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: match.positionIndex,
        piecePositionIndices: newIndices,
      );
      _recomputeBoardValidity();
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la rotation horaire');
  }

  /// Applique une symétrie horizontale à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// Symétrie géométrique par rapport à x = x0 (axe vertical à travers la mastercase)
  void applyIsometrySymmetryH() {
    // Transformer une pièce placée avec symétrie géométrique (mode game ET isométries)
    if (state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;

      // 1. Extraire les coordonnées absolues actuelles
      final currentCoords = _extractAbsoluteCoords(selectedPiece);

      // 2. Déterminer l'axe de symétrie x = x0 (pour inverser gauche/droite)
      // Si une cellule de référence est définie, utiliser celle-ci
      // Sinon, utiliser le coin bas-gauche de la pièce (0,0) local
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();
      final axisX = selectedPiece.gridX + refX;

      print('[GAME] ↔️ Symétrie horizontale par rapport à x = $axisX');

      // 3. Appliquer la symétrie horizontale (flip vertical pour être plus intuitif)
      // En termes visuels, une "symétrie horizontale" inverse gauche/droite
      final flippedCoords = flipVertical(
        currentCoords,
        selectedPiece.gridX + refX,
      );

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

      print(
        '[GAME] ✅ Symétrie horizontale réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})',
      );

      // 6. Créer la nouvelle pièce placée (transformée)
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 7. Calculer la nouvelle position locale de la master case
      // Pour la symétrie horizontale (↔️), on inverse gauche/droite autour de x = axisX
      final centerX = axisX;
      final centerY = selectedPiece.gridY + refY;
      final newSelectedCell = _calculateNewMasterCell(
        centerX,
        centerY,
        match.gridX,
        match.gridY,
      );
      print(
        '[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local',
      );

      // 8. NE PAS modifier placedPieces ni le plateau
      // La pièce reste hors du plateau et sera replacée quand l'utilisateur cliquera ailleurs

      // 9. Recalculer les solutions possibles avec la nouvelle configuration
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      print(
        '[GAME] 🎯 Solutions possibles après symétrie horizontale : $solutionsCount',
      );

      // 10. Mettre à jour l'état avec la nouvelle pièce transformée (toujours sélectionnée)
      state = state.copyWith(
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Utiliser les transformations géométriques comme en mode isométries
      // 1. Extraire les coordonnées de la position actuelle (normalisées)
      final currentCoords = piece.cartesianCoords[currentIndex];

      // 2. Déterminer l'axe de symétrie (axe vertical x = refX pour inverser gauche/droite)
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();

      // 3. Appliquer la symétrie verticale (inverse gauche/droite)
      final flippedCoords = flipVertical(currentCoords, refX);

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(flippedCoords);

      if (match == null || match.piece.id != piece.id) {
        print(
          '[GAME] ⚠️ Aucune symétrie horizontale disponible pour cette pièce',
        );
        return;
      }

      print(
        '[GAME] ↔️ Symétrie horizontale de la pièce sélectionnée (position $currentIndex → ${match.positionIndex})',
      );

      // 5. Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = match.positionIndex;

      // 6. Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: match.positionIndex,
        piecePositionIndices: newIndices,
      );
      _recomputeBoardValidity();
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la symétrie');
  }

  /// Applique une symétrie verticale à la pièce sélectionnée
  /// Fonctionne en mode jeu normal ET en mode isométries
  /// Symétrie géométrique par rapport à y = y0 (axe horizontal à travers la mastercase)
  void applyIsometrySymmetryV() {
    // Transformer une pièce placée avec symétrie géométrique (mode game ET isométries)
    if (state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;

      // 1. Extraire les coordonnées absolues actuelles
      final currentCoords = _extractAbsoluteCoords(selectedPiece);

      // 2. Déterminer l'axe de symétrie y = y0 (pour inverser haut/bas)
      // Si une cellule de référence est définie, utiliser celle-ci
      // Sinon, utiliser le coin bas-gauche de la pièce (0,0) local
      final refX = (state.selectedCellInPiece?.x ?? 0).toInt();
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();
      final axisY = selectedPiece.gridY + refY;

      print('[GAME] ↕️ Symétrie verticale par rapport à y = $axisY');

      // 3. Appliquer la symétrie verticale (flip horizontal pour être plus intuitif)
      // En termes visuels, une "symétrie verticale" inverse haut/bas
      final flippedCoords = flipHorizontal(
        currentCoords,
        selectedPiece.gridY + refY,
      );

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

      print(
        '[GAME] ✅ Symétrie verticale réussie : pièce ${match.piece.id}, position ${match.positionIndex}, nouvelle ancre (${match.gridX}, ${match.gridY})',
      );

      // 6. Créer la nouvelle pièce placée (transformée)
      final transformedPiece = PlacedPiece(
        piece: match.piece,
        positionIndex: match.positionIndex,
        gridX: match.gridX,
        gridY: match.gridY,
      );

      // 7. Calculer la nouvelle position locale de la master case
      // Pour la symétrie verticale (↕️), on inverse haut/bas autour de y = axisY
      final centerX = selectedPiece.gridX + refX;
      final centerY = axisY;
      final newSelectedCell = _calculateNewMasterCell(
        centerX,
        centerY,
        match.gridX,
        match.gridY,
      );
      print(
        '[GAME] 🎯 Master case conservée : ($centerX, $centerY) absolu → (${newSelectedCell.x}, ${newSelectedCell.y}) local',
      );

      // 8. NE PAS modifier placedPieces ni le plateau
      // La pièce reste hors du plateau et sera replacée quand l'utilisateur cliquera ailleurs

      // 9. Recalculer les solutions possibles avec la nouvelle configuration
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      print(
        '[GAME] 🎯 Solutions possibles après symétrie verticale : $solutionsCount',
      );

      // 10. Mettre à jour l'état avec la nouvelle pièce transformée (toujours sélectionnée)
      state = state.copyWith(
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: match.positionIndex,
        selectedCellInPiece: newSelectedCell,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    // En mode jeu normal : transformer la pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;

      // Utiliser les transformations géométriques comme en mode isométries
      // 1. Extraire les coordonnées de la position actuelle (normalisées)
      final currentCoords = piece.cartesianCoords[currentIndex];

      // 2. Déterminer l'axe de symétrie (axe horizontal y = refY pour inverser haut/bas)
      final refY = (state.selectedCellInPiece?.y ?? 0).toInt();

      // 3. Appliquer la symétrie horizontale (inverse haut/bas)
      final flippedCoords = flipHorizontal(currentCoords, refY);

      // 4. Reconnaître la nouvelle forme
      final match = recognizeShape(flippedCoords);

      if (match == null || match.piece.id != piece.id) {
        print(
          '[GAME] ⚠️ Aucune symétrie verticale disponible pour cette pièce',
        );
        return;
      }

      print(
        '[GAME] ↕️ Symétrie verticale de la pièce sélectionnée (position $currentIndex → ${match.positionIndex})',
      );

      // 5. Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = match.positionIndex;

      // 6. Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: match.positionIndex,
        piecePositionIndices: newIndices,
      );
      _recomputeBoardValidity();
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour la symétrie');
  }

  @override
  PentominoGameState build() {
    return PentominoGameState.initial();
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
      final updatedPlacedPiece = placedPiece.copyWith(
        positionIndex: state.selectedPositionIndex,
      );
      final newPlaced = List<PlacedPiece>.from(state.placedPieces)
        ..add(updatedPlacedPiece);

      state = state.copyWith(
        plateau: newPlateau,
        placedPieces: newPlaced,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
      );
      _recomputeBoardValidity();
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

  /// Annule le tutoriel (toujours restaurer)
  void cancelTutorial() {
    exitTutorialMode(restore: true);
  }

  /// Efface la surbrillance du plateau
  void clearBoardHighlight() {
    state = state.copyWith(clearHighlightedBoardPiece: true);
    print('[TUTORIAL] Surbrillance plateau effacée');
  }

  /// Efface toutes les surbrillances de cases
  void clearCellHighlights() {
    state = state.copyWith(clearCellHighlights: true);
    print('[TUTORIAL] Toutes les surbrillances de cases effacées');
  }

  /// Efface la surbrillance de la mastercase
  void clearMastercaseHighlight() {
    state = state.copyWith(clearHighlightedMastercase: true);
    print('[TUTORIAL] Surbrillance mastercase effacée');
  }

  /// Efface la prévisualisation
  void clearPreview() {
    if (state.previewX != null || state.previewY != null) {
      state = state.copyWith(clearPreview: true);
    }
  }

  /// Efface la surbrillance du slider
  void clearSliderHighlight() {
    state = state.copyWith(clearHighlightedSliderPiece: true);
    print('[TUTORIAL] Surbrillance slider effacée');
  }

  /// 🆕 Surligne une icône d'isométrie (pour tutoriel)
  /// iconName: 'rotation', 'rotation_cw', 'symmetry_h', 'symmetry_v'
  void highlightIsometryIcon(String iconName) {
    final validIcons = ['rotation', 'rotation_cw', 'symmetry_h', 'symmetry_v'];
    if (!validIcons.contains(iconName)) {
      print('[TUTORIAL] ⚠️ Icône invalide: $iconName (attendu: ${validIcons.join(", ")})');
      return;
    }
    state = state.copyWith(highlightedIsometryIcon: iconName);
    print('[TUTORIAL] 🔆 Icône d\'isométrie surlignée: $iconName');
  }

  /// 🆕 Efface la surbrillance des icônes d'isométrie
  void clearIsometryIconHighlight() {
    state = state.copyWith(clearHighlightedIsometryIcon: true);
    print('[TUTORIAL] Surbrillance icône isométrie effacée');
  }

  /// Cycle vers l'orientation suivante de la pièce sélectionnée
  /// Passe simplement à l'index suivant dans piece.positions (boucle)
  void cycleToNextOrientation() {
    // Pour une pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;
      final nextIndex = (currentIndex + 1) % piece.numPositions;

      print(
        '[GAME] 🔄 Cycle orientation : $currentIndex → $nextIndex (sur ${piece.numPositions} positions)',
      );

      // Sauvegarder le nouvel index dans le Map
      final newIndices = Map<int, int>.from(state.piecePositionIndices);
      newIndices[piece.id] = nextIndex;

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPositionIndex: nextIndex,
        piecePositionIndices: newIndices,
      );
      _recomputeBoardValidity();
      return;
    }

    // Pour une pièce placée
    if (state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;
      final currentIndex = selectedPiece.positionIndex;
      final nextIndex = (currentIndex + 1) % selectedPiece.piece.numPositions;

      print(
        '[GAME] 🔄 Cycle orientation pièce placée : $currentIndex → $nextIndex (sur ${selectedPiece.piece.numPositions} positions)',
      );

      // Créer la pièce avec la nouvelle orientation
      final transformedPiece = selectedPiece.copyWith(positionIndex: nextIndex);

      // Recalculer les solutions possibles
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      print('[GAME] 🎯 Solutions possibles après cycle : $solutionsCount');

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPlacedPiece: transformedPiece,
        selectedPositionIndex: nextIndex,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    print('[GAME] ⚠️ Aucune pièce sélectionnée pour le cycle');
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
    state = state.copyWith(isIsometriesMode: true, savedGameState: savedState);
  }

  /// Entre en mode tutoriel : sauvegarde l'état actuel et reset le jeu
  void enterTutorialMode() {
    if (state.isInTutorial) {
      throw StateError('Déjà en mode tutoriel');
    }

    if (state.isIsometriesMode) {
      throw StateError(
        'Impossible d\'entrer en tutoriel depuis le mode isométries',
      );
    }

    // Sauvegarder l'état complet actuel
    final savedState = state.copyWith();

    // Reset le jeu pour un plateau vierge
    reset();

    // Marquer comme mode tutoriel avec sauvegarde
    state = state.copyWith(savedGameState: savedState, isInTutorial: true);

    print('[TUTORIAL] Mode tutoriel activé, état sauvegardé');
  }

  /// Sort du mode isométries (restaure l'état sauvegardé)
  void exitIsometriesMode() {
    if (!state.isIsometriesMode) return; // Pas en mode isométries
    if (state.savedGameState == null) {
      print(
        '[GAME] ⚠️ Impossible de sortir du mode isométries : pas d\'état sauvegardé',
      );
      return;
    }

    print('[GAME] 🎓 Sortie du mode isométries');

    // Restaurer l'état sauvegardé
    state = state.savedGameState!;
  }

  /// Sort du mode tutoriel et restaure l'état sauvegardé
  void exitTutorialMode({bool restore = true}) {
    if (!state.isInTutorial) {
      throw StateError('Pas en mode tutoriel');
    }

    if (state.savedGameState == null) {
      throw StateError('Pas de sauvegarde disponible');
    }

    if (restore) {
      // Restaurer l'état complet
      state = state.savedGameState!.copyWith(
        savedGameState: null,
        isInTutorial: false,
        clearHighlightedSliderPiece: true,
        clearHighlightedBoardPiece: true,
        clearHighlightedMastercase: true,
        clearCellHighlights: true,
        sliderOffset: 0,
      );
      print('[TUTORIAL] Mode tutoriel quitté, état restauré');
    } else {
      // Garder le plateau actuel, juste enlever le flag tutoriel
      state = state.copyWith(
        savedGameState: null,
        isInTutorial: false,
        clearHighlightedSliderPiece: true,
        clearHighlightedBoardPiece: true,
        clearHighlightedMastercase: true,
        clearCellHighlights: true,
        sliderOffset: 0,
      );
      print('[TUTORIAL] Mode tutoriel quitté, plateau conservé');
    }
  }

  /// 🆕 Restaure un état sauvegardé (utilisé par TutorialProvider au quit)
  void restoreState(PentominoGameState savedState) {
    print(
      '[GAME] ♻️ Restauration de l\'état : ${savedState.placedPieces.length} pièces placées',
    );
    state = savedState;
  }

  /// Trouve une pièce placée à une position donnée
  PlacedPiece? findPlacedPieceAt(int x, int y) {
    for (final placedPiece in state.placedPieces) {
      final cells = placedPiece.absoluteCells;
      if (cells.any((cell) => cell.x == x && cell.y == y)) {
        return placedPiece;
      }
    }
    return null;
  }

  /// Trouve une pièce placée par son ID
  PlacedPiece? findPlacedPieceById(int pieceNumber) {
    try {
      return state.placedPieces.firstWhere((p) => p.piece.id == pieceNumber);
    } catch (e) {
      return null;
    }
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

  /// Surligne une case individuelle avec une couleur
  void highlightCell(int x, int y, Color color) {
    if (x < 0 || x >= 6 || y < 0 || y >= 10) {
      throw ArgumentError('Position hors limites: ($x, $y)');
    }

    final newHighlights = Map<Point, Color>.from(state.cellHighlights);
    newHighlights[Point(x, y)] = color;

    state = state.copyWith(cellHighlights: newHighlights);
    print('[TUTORIAL] Case ($x, $y) surlignée');
  }

  /// Surligne plusieurs cases avec la même couleur
  void highlightCells(List<Point> cells, Color color) {
    final newHighlights = Map<Point, Color>.from(state.cellHighlights);

    for (final cell in cells) {
      if (cell.x >= 0 && cell.x < 6 && cell.y >= 0 && cell.y < 10) {
        newHighlights[cell] = color;
      }
    }

    state = state.copyWith(cellHighlights: newHighlights);
    print('[TUTORIAL] ${cells.length} cases surlignées');
  }

  /// Surligne la mastercase d'une pièce
  void highlightMastercase(Point position) {
    state = state.copyWith(highlightedMastercase: position);
    print('[TUTORIAL] Mastercase surlignée en (${position.x}, ${position.y})');
  }

  // ============================================================
  // 🆕 MÉTHODES TUTORIEL - Ajoutées pour le système Scratch-Pentapol
  // ============================================================

  /// Surligne une pièce dans le slider (sans la sélectionner)
  void highlightPieceInSlider(int pieceNumber) {
    if (pieceNumber < 1 || pieceNumber > 12) {
      throw ArgumentError('pieceNumber doit être entre 1 et 12');
    }

    state = state.copyWith(highlightedSliderPiece: pieceNumber);
    print('[TUTORIAL] Pièce $pieceNumber surlignée dans le slider');
  }

  /// Surligne une pièce posée sur le plateau (sans la sélectionner)
  void highlightPieceOnBoard(int pieceNumber) {
    if (pieceNumber < 1 || pieceNumber > 12) {
      throw ArgumentError('pieceNumber doit être entre 1 et 12');
    }

    // Vérifier que la pièce existe sur le plateau
    final exists = state.placedPieces.any((p) => p.piece.id == pieceNumber);
    if (!exists) {
      throw StateError('La pièce $pieceNumber n\'est pas sur le plateau');
    }

    state = state.copyWith(highlightedBoardPiece: pieceNumber);
    print('[TUTORIAL] Pièce $pieceNumber surlignée sur le plateau');
  }

  /// Surligne toutes les positions valides pour la pièce sélectionnée
  void highlightValidPositions(Pento piece, int positionIndex, Color color) {
    final validCells = <Point>[];

    // Tester toutes les positions du plateau
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 6; x++) {
        if (state.canPlacePiece(piece, positionIndex, x, y)) {
          // Ajouter toutes les cases que la pièce occuperait
          final position = piece.positions[positionIndex];
          for (final cellNum in position) {
            final localX = (cellNum - 1) % 5;
            final localY = (cellNum - 1) ~/ 5;
            final absX = x + localX;
            final absY = y + localY;

            if (absX >= 0 && absX < 6 && absY >= 0 && absY < 10) {
              validCells.add(Point(absX, absY));
            }
          }
        }
      }
    }

    highlightCells(validCells, color);
    print('[TUTORIAL] ${validCells.length} positions valides surlignées');
  }

  // ============================================================
  // HIGHLIGHTS SLIDER
  // ============================================================

  /// Place la pièce sélectionnée à la position indiquée (pour tutoriel)
  /// Place la pièce sélectionnée à la position indiquée (pour tutoriel)
  /// gridX/gridY = position de la MASTERCASE (pas du coin haut-gauche)
  void placeSelectedPieceForTutorial(int gridX, int gridY) {
    if (state.selectedPiece == null) {
      print('[TUTORIAL] ⚠️ Aucune pièce sélectionnée');
      return;
    }

    final piece = state.selectedPiece!;
    final positionIndex = 0; // Position par défaut

    // IMPORTANT : Calculer l'offset de la mastercase
    // La première cellule de position[0] est la mastercase
    final position = piece.positions[positionIndex];
    final mastercellNum = position.first;
    final masterLocalX = (mastercellNum - 1) % 5;
    final masterLocalY = (mastercellNum - 1) ~/ 5;

    // Convertir : position mastercase → position coin haut-gauche
    final anchorX = gridX - masterLocalX;
    final anchorY = gridY - masterLocalY;

    print('[TUTORIAL] 🔍 Conversion mastercase→ancre:');
    print('[TUTORIAL]   Mastercase souhaitée: ($gridX, $gridY)');
    print('[TUTORIAL]   Mastercase locale: ($masterLocalX, $masterLocalY)');
    print('[TUTORIAL]   Ancre calculée: ($anchorX, $anchorY)');

    // Vérifier que la position est valide
    if (!state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      print('[TUTORIAL] ⚠️ Position invalide pour placer la pièce');
      return;
    }

    // Créer le plateau avec toutes les pièces existantes
    final newPlateau = Plateau.allVisible(6, 10);
    for (final placed in state.placedPieces) {
      final pos = placed.piece.positions[placed.positionIndex];
      for (final cellNum in pos) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placed.gridX + localX;
        final y = placed.gridY + localY;
        newPlateau.setCell(x, y, 1);
      }
    }

    // Ajouter la nouvelle pièce au plateau
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      newPlateau.setCell(anchorX + localX, anchorY + localY, 1);
    }

    // Créer l'objet PlacedPiece (avec l'ancre, pas la mastercase)
    final placedPiece = PlacedPiece(
      piece: piece,
      positionIndex: positionIndex,
      gridX: anchorX,  // ← Ancre, pas mastercase
      gridY: anchorY,  // ← Ancre, pas mastercase
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
      placedPieces: newPlaced,
      availablePieces: newAvailable,
      selectedPiece: null,
      solutionsCount: solutionsCount,
    );

    print('[TUTORIAL] 🔍 PlacedPiece absoluteCells: ${placedPiece.absoluteCells.toList()}');
    print('[TUTORIAL] ✅ Pièce ${piece.id} placée avec mastercase en ($gridX, $gridY)');
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
    final newPlaced = state.placedPieces
        .where((p) => p != placedPiece)
        .toList();

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlaced.isEmpty
        ? null
        : newPlateau.countPossibleSolutions();

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      solutionsCount: solutionsCount,
    );
    _recomputeBoardValidity();

    print('[GAME] 🗑️ Pièce ${placedPiece.piece.id} retirée du plateau');
    if (solutionsCount != null) {
      print('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }
  }

  // ============================================================
  // HIGHLIGHTS PLATEAU
  // ============================================================

  /// Réinitialise le jeu
  void reset() {
    state = PentominoGameState.initial();
  }

  /// Remet le slider à sa position initiale
  void resetSliderPosition() {
    state = state.copyWith(sliderOffset: 0);
    print('[TUTORIAL] Slider remis à la position initiale');
  }

  /// Fait défiler le slider de N positions
  /// positions > 0 : vers la droite
  /// positions < 0 : vers la gauche
  void scrollSlider(int positions) {
    final newOffset = (state.sliderOffset + positions) % 12;
    state = state.copyWith(sliderOffset: newOffset);
    print(
      '[TUTORIAL] Slider décalé de $positions positions (offset: $newOffset)',
    );
  }

  /// Fait défiler le slider pour centrer sur une pièce
  void scrollSliderToPiece(int pieceNumber) {
    if (pieceNumber < 1 || pieceNumber > 12) {
      throw ArgumentError('pieceNumber doit être entre 1 et 12');
    }

    // Calculer l'offset pour centrer cette pièce
    // (dépend de l'implémentation exacte du slider)
    final targetOffset = (pieceNumber - 1) % 12;
    state = state.copyWith(sliderOffset: targetOffset);
    print('[TUTORIAL] Slider centré sur pièce $pieceNumber');
  }

  // ============================================================
  // HIGHLIGHTS DE CASES
  // ============================================================

  /// Sélectionne une pièce du slider (commence le drag)
  void selectPiece(Pento piece) {
    // Récupérer l'index de position sauvegardé pour cette pièce
    final savedIndex = state.getPiecePositionIndex(piece.id);
    // Si une pièce du plateau est déjà sélectionnée, la replacer d'abord
    print('[DEBUG PAYSAGE] 🔍 selectPiece(${piece.id})');
    print(
      '[DEBUG PAYSAGE] 📋 piecePositionIndices: ${state.piecePositionIndices}',
    );
    print('[DEBUG PAYSAGE] 📌 savedIndex pour pièce ${piece.id}: $savedIndex');
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

      state = state.copyWith(plateau: newPlateau, placedPieces: newPlaced);
      _recomputeBoardValidity();
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
    _recomputeBoardValidity();
  }

  /// Sélectionne une pièce du slider avec mastercase explicite
  /// (pour compatibilité Scratch SELECT_PIECE_FROM_SLIDER)
  void selectPieceFromSliderForTutorial(int pieceNumber) {
    if (pieceNumber < 1 || pieceNumber > 12) {
      throw ArgumentError('pieceNumber doit être entre 1 et 12');
    }

    final piece = pentominos.firstWhere((p) => p.id == pieceNumber);
    selectPiece(piece);

    print('[TUTORIAL] Pièce $pieceNumber sélectionnée depuis le slider');
  }

  /// Sélectionne une pièce déjà placée pour la déplacer
  /// [cellX] et [cellY] sont les coordonnées de la case touchée sur le plateau

  /// Sélectionne une pièce déjà placée pour la déplacer
  /// [cellX] et [cellY] sont les coordonnées de la case touchée sur le plateau
  void selectPlacedPiece(PlacedPiece placedPiece, int cellX, int cellY) {
    // Si une autre pièce du plateau est déjà sélectionnée, la replacer d'abord
    if (state.selectedPlacedPiece != null &&
        state.selectedPlacedPiece != placedPiece) {
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
    final newPlaced = state.placedPieces
        .where((p) => p != placedPiece)
        .toList();

    // ✅ AJOUT : Calculer les solutions en incluant la pièce sélectionnée
    final solutionsCount = _computeSolutionsWithTransformedPiece(placedPiece);

    // Sélectionner la pièce avec sa position actuelle et la case de référence
    state = state.copyWith(
      plateau: newPlateau,
      placedPieces: newPlaced,
      selectedPiece: placedPiece.piece,
      selectedPositionIndex: placedPiece.positionIndex,
      selectedPlacedPiece: placedPiece,
      selectedCellInPiece: selectedCell,
      solutionsCount: solutionsCount, // ✅ AJOUT
    );

    print(
      '[GAME] 🔄 Pièce ${placedPiece.piece.id} sélectionnée pour déplacement (case ref: $selectedCell)',
    );
  }

  /// Sélectionne une pièce sur le plateau à une position donnée
  /// (pour compatibilité Scratch SELECT_PIECE_ON_BOARD_AT)
  void selectPlacedPieceAtForTutorial(int x, int y) {
    final placedPiece = findPlacedPieceAt(x, y);

    if (placedPiece == null) {
      throw StateError('Aucune pièce à la position ($x, $y)');
    }

    // La case cliquée devient la mastercase
    selectPlacedPiece(placedPiece, x, y);

    print('[TUTORIAL] Pièce ${placedPiece.piece.id} sélectionnée en ($x, $y)');
  }

  // ============================================================
  // CONTRÔLE DU SLIDER
  // ============================================================

  /// Sélectionne une pièce avec une mastercase explicite
  /// (pour compatibilité Scratch SELECT_PIECE_ON_BOARD_WITH_MASTERCASE)
  void selectPlacedPieceWithMastercaseForTutorial(
      int pieceNumber,
      int mastercaseX,
      int mastercaseY,
      ) {
    final placedPiece = findPlacedPieceById(pieceNumber);

    if (placedPiece == null) {
      throw StateError('La pièce $pieceNumber n\'est pas sur le plateau');
    }

    // Vérifier que la mastercase est bien dans la pièce
    final isInPiece = placedPiece.absoluteCells.any(
          (cell) => cell.x == mastercaseX && cell.y == mastercaseY,
    );

    if (!isInPiece) {
      throw ArgumentError(
        'La position ($mastercaseX, $mastercaseY) n\'est pas dans la pièce $pieceNumber',
      );
    }

    selectPlacedPiece(placedPiece, mastercaseX, mastercaseY);

    print(
      '[TUTORIAL] Pièce $pieceNumber sélectionnée avec mastercase ($mastercaseX, $mastercaseY)',
    );
  }

  /// Tente de placer la pièce sélectionnée sur le plateau
  /// [gridX] et [gridY] sont les coordonnées où on lâche la pièce (position du doigt)
  /// Tente de placer la pièce sélectionnée sur le plateau
  /// [gridX] et [gridY] sont les coordonnées où on lâche la pièce (position du doigt)
  bool tryPlacePiece(int gridX, int gridY) {
    if (state.selectedPiece == null) return false;

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;
    print(
      '[DEBUG PLACEMENT] 🎯 tryPlacePiece: piece=${piece.id}, positionIndex=$positionIndex',
    );
    print(
      '[DEBUG PLACEMENT] 📋 piecePositionIndices=${state.piecePositionIndices}',
    );
    final wasPlacedPiece =
        state.selectedPlacedPiece !=
            null; // ✅ Mémoriser si c'était une pièce placée
    final savedCellInPiece =
        state.selectedCellInPiece; // ✅ Garder la master cell

    // Calculer la position d'ancrage en utilisant la case de référence
    int anchorX = gridX;
    int anchorY = gridY;

    if (state.selectedCellInPiece != null) {
      // Translation : la case de référence doit être placée à (gridX, gridY)
      // Donc la position d'ancrage = position de lâcher - position locale de la case de référence
      anchorX = gridX - state.selectedCellInPiece!.x;
      anchorY = gridY - state.selectedCellInPiece!.y;

      print(
        '[GAME] Translation: lâcher à ($gridX, $gridY), case ref locale (${state.selectedCellInPiece!.x}, ${state.selectedCellInPiece!.y}), anchor ($anchorX, $anchorY)',
      );
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

    // Retirer la pièce des disponibles (si elle y était)
    final newAvailable = List<Pento>.from(state.availablePieces)
      ..removeWhere((p) => p.id == piece.id);

    // Ajouter aux pièces placées
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)
      ..add(placedPiece);

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlateau.countPossibleSolutions();

    // ✅ Si c'était une pièce placée, on la garde sélectionnée (comme pour rotation/symétrie)
    if (wasPlacedPiece) {
      // Retirer la pièce du plateau pour qu'elle reste "flottante" (sélectionnée)
      final plateauSansPiece = Plateau.allVisible(6, 10);
      for (final placed in state.placedPieces) {
        final pos = placed.piece.positions[placed.positionIndex];
        for (final cellNum in pos) {
          final localX = (cellNum - 1) % 5;
          final localY = (cellNum - 1) ~/ 5;
          final x = placed.gridX + localX;
          final y = placed.gridY + localY;
          if (x >= 0 && x < 6 && y >= 0 && y < 10) {
            plateauSansPiece.setCell(x, y, placed.piece.id);
          }
        }
      }

      state = state.copyWith(
        plateau: plateauSansPiece,
        availablePieces: newAvailable,
        placedPieces:
        state.placedPieces, // ✅ Ne pas ajouter la pièce aux placées
        selectedPiece: piece,
        selectedPositionIndex: positionIndex,
        selectedPlacedPiece:
        placedPiece, // ✅ Garder la référence à la nouvelle position
        selectedCellInPiece: savedCellInPiece, // ✅ Garder la master cell
        solutionsCount: solutionsCount,
        clearPreview: true,
      );
      _recomputeBoardValidity();

      print(
        '[GAME] ✅ Pièce ${piece.id} déplacée à ($anchorX, $anchorY) - reste sélectionnée',
      );
      print('[GAME] 🎯 Solutions possibles: $solutionsCount');
    } else {
      // C'était une pièce du slider → comportement normal (désélectionner)
      state = state.copyWith(
        plateau: newPlateau,
        availablePieces: newAvailable,
        placedPieces: newPlaced,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        solutionsCount: solutionsCount,
        clearPreview: true,
      );
      _recomputeBoardValidity();

      print('[GAME] ✅ Pièce ${piece.id} placée à ($anchorX, $anchorY)');
      print('[GAME] Pièces restantes: ${newAvailable.length}');
      print('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }

    return true;
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
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)..removeLast();

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlaced.isEmpty
        ? null
        : newPlateau.countPossibleSolutions();

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

  // ============================================================
  // UTILITAIRES TUTORIEL
  // ============================================================

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
    if (state.previewX != anchorX ||
        state.previewY != anchorY ||
        state.isPreviewValid != isValid) {
      state = state.copyWith(
        previewX: anchorX,
        previewY: anchorY,
        isPreviewValid: isValid,
      );
    }
  }

  /// Calcule la nouvelle position locale de la master case après une transformation
  /// [centerX], [centerY] : coordonnées absolues de la master case (fixe)
  /// [newGridX], [newGridY] : nouvelle ancre de la pièce transformée
  Point _calculateNewMasterCell(
      int centerX,
      int centerY,
      int newGridX,
      int newGridY,
      ) {
    final newLocalX = centerX - newGridX;
    final newLocalY = centerY - newGridY;
    return Point(newLocalX, newLocalY);
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
      if (cell != 0 &&
          (excludePiece == null || cell != excludePiece.piece.id)) {
        return false;
      }
    }

    return true;
  }

  /// Calcule le nombre de solutions possibles avec une pièce transformée
  /// Crée temporairement un plateau avec toutes les pièces incluant la transformée
  int? _computeSolutionsWithTransformedPiece(PlacedPiece transformedPiece) {
    // Créer un plateau temporaire
    final tempPlateau = Plateau.allVisible(6, 10);

    // Placer toutes les pièces déjà placées (sauf celle en transformation)
    for (final placed in state.placedPieces) {
      final position = placed.piece.positions[placed.positionIndex];
      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        final x = placed.gridX + localX;
        final y = placed.gridY + localY;
        if (x >= 0 && x < 6 && y >= 0 && y < 10) {
          tempPlateau.setCell(x, y, placed.piece.id);
        }
      }
    }

    // Placer la pièce transformée
    final position =
    transformedPiece.piece.positions[transformedPiece.positionIndex];
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      final x = transformedPiece.gridX + localX;
      final y = transformedPiece.gridY + localY;
      if (x >= 0 && x < 6 && y >= 0 && y < 10) {
        tempPlateau.setCell(x, y, transformedPiece.piece.id);
      }
    }

    // Calculer les solutions possibles
    return tempPlateau.countPossibleSolutions();
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

  // ============================================================
  // TUTORIEL - PLACEMENT
  // ============================================================
  /// Méthode helper pour appliquer une transformation (OBSOLÈTE - conservée pour compatibilité)
  /// Les nouvelles transformations géométriques sont gérées directement dans
  /// applyIsometryRotation, applyIsometrySymmetryH, applyIsometrySymmetryV
  /*  void _applyTransformation(int nextIndex) {
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
    _recomputeBoardValidity();
  }*/
  /// Recalcule la validité du plateau et les cellules problématiques
  void _recomputeBoardValidity() {
    final overlapping = <Point>{};
    final offBoard = <Point>{};
    final cellCounts = <Point, int>{};

    for (final placed in state.placedPieces) {
      // 🔁 On utilise directement les cases absolues de la pièce
      for (final p in placed.absoluteCells) {
        final x = p.x;
        final y = p.y;

        // Hors plateau ?
        if (x < 0 ||
            x >= state.plateau.width ||
            y < 0 ||
            y >= state.plateau.height) {
          offBoard.add(p);
          continue;
        }

        final count = (cellCounts[p] ?? 0) + 1;
        cellCounts[p] = count;
        if (count > 1) {
          overlapping.add(p);
        }
      }
    }

    final isValid = overlapping.isEmpty && offBoard.isEmpty;

    state = state.copyWith(
      boardIsValid: isValid,
      overlappingCells: overlapping,
      offBoardCells: offBoard,
    );
  }
}
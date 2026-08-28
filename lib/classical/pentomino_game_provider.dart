// Modified: 2026-08-28 20:48 — suppression de la démonstration (couches C+D) : retrait des
//           12 méthodes de surbrillance, des méthodes de mode (isométries, démonstration)
//           et de la restauration d'état, toutes publiques sans appelant. Étiquettes de
//           section et traces console correspondantes nettoyées.
// lib/classical/pentomino_game_provider.dart
// Historique: 2026-08-28 20:30 — retrait des 4 méthodes de l'API de démonstration du provider.
//             2026-08-28 20:24 — dettes 1 et 2 : solutionsCount recalculé, isComplete
//             redonne un chemin de retour vers true.
//             2026-08-28 10:19 — temps 2 : bascule stay + mask (3 lifts, 2 restitutions,
//             tryPlacePiece map/add, isComplete).
//             2026-08-28 09:22 — temps 1 : helper unique _rebuildPlateau, 10 méthodes.
//             2026-08-27 21:03 — (1) applyIsometry* renvoient TransformationResult ;
//             (2) retrait de 3 méthodes orphelines + import shape_recognizer ;
//             (3) magnétisme _snapRadius 2 → 10.
//             2604221200 — Refactor: absoluteCells remplace boucles cellNum
//             manuelles, print→debugPrint, ref.onDispose()

import 'dart:async';

import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/classical/pentomino_game_state.dart';

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/transformation_result.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/common/game_timer_mixin.dart';
import 'package:pentapol/common/piece_interaction_mixin.dart';
import 'package:pentapol/common/pentomino_game_mixin.dart';
import 'package:pentapol/common/pentomino_symmetry_api.dart';
import 'package:pentapol/services/plateau_solution_counter.dart' show PlateauSolutionCounter;
import 'package:pentapol/services/solution_matcher.dart' show SolutionInfo;
import 'package:pentapol/providers/settings_provider.dart' show settingsDatabaseProvider;
import 'dart:math';
import 'package:pentapol/services/solution_matcher.dart' show solutionMatcher;
import 'package:collection/collection.dart';

final pentominoGameProvider =
NotifierProvider<PentominoGameNotifier, PentominoGameState>(
      () => PentominoGameNotifier(),
);

class PentominoGameNotifier extends Notifier<PentominoGameState> 
    with PentominoGameMixin, GameTimerMixin<PentominoGameState>, PieceInteractionMixin<PentominoGameState> {
  @override
  PentominoGameState stateWithDragging(bool isDragging) =>
      state.copyWith(isDragging: isDragging);

  @override
  PentominoGameState stateWithPreviewCleared() =>
      state.copyWith(clearPreview: true);

  @override
  PentominoGameState stateWithElapsedSeconds(int elapsedSeconds) =>
      state.copyWith(elapsedSeconds: elapsedSeconds);

  /// Rayon de recherche du magnétisme, en cases.
  ///
  /// Le plateau classique fait 6×10 : un rayon de 10 couvre l'intégralité du plateau
  /// depuis n'importe quelle ancre. Le magnétisme est donc **illimité en pratique** —
  /// lâcher une pièce n'importe où l'accroche à la position valide la plus proche,
  /// jamais de preview rouge tant qu'un placement existe.
  ///
  /// Valait 2 jusqu'au 2026-08-27 : il fallait viser à deux cases près, sinon la
  /// preview passait au rouge. Élargi sur décision de jeu, pour aligner le mode
  /// classique sur le comportement plus assistant de Pentoscope.
  ///
  /// Coût : 440 positions testées par mouvement du doigt au lieu de 24. Négligeable
  /// à l'échelle d'un geste, mais c'est le poste à regarder en premier si le drag
  /// devenait saccadé sur un appareil lent.
  static const int _snapRadius = 10;
  
  // ============================================================================
  // IMPLÉMENTATION DES MÉTHODES ABSTRAITES DU MIXIN
  // ============================================================================
  
  @override
  Plateau get currentPlateau => state.plateau;
  
  @override
  Pento? get selectedPiece => state.selectedPiece;
  
  @override
  int get selectedPositionIndex => state.selectedPositionIndex;
  
  @override
  Point? get selectedCellInPiece => state.selectedCellInPiece;
  
  @override
  bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
    return state.canPlacePiece(piece, positionIndex, gridX, gridY);
  }

  /// Méthode publique pour obtenir les coordonnées brutes de la mastercase.
  /// En mode classical, selectedCellInPiece est déjà en coordonnées brutes (5x5).
  Point? getRawMastercaseCoordsPublic() {
    return state.selectedCellInPiece;
  }







  /// Applique une rotation 90° horaire
  TransformationResult applyIsometryRotationCW() {
    debugPrint(
      "ISO: RotCW (view=${state.viewOrientation}) idx=${state.selectedPositionIndex} piece=${state.selectedPiece?.id} placed=${state.selectedPlacedPiece?.piece.id}",
    );

    // Pour les pièces placées, appliquer une rotation spécifique
    if (state.selectedPlacedPiece != null) {
      _applyRotationToPlacedPiece(isClockwise: true);
      return TransformationResult.success;
    }

    // Pour les pièces du slider, rotation normale
    _applyIsoUsingLookup((p, idx) => p.rotationCW(idx));
    return TransformationResult.success;
  }

  /// Applique une rotation 90° anti-horaire
  TransformationResult applyIsometryRotationTW() {
    debugPrint(
      "ISO: RotTW (view=${state.viewOrientation}) idx=${state.selectedPositionIndex} piece=${state.selectedPiece?.id} placed=${state.selectedPlacedPiece?.piece.id}",
    );

    // Pour les pièces placées, appliquer une rotation spécifique
    if (state.selectedPlacedPiece != null) {
      _applyRotationToPlacedPiece(isClockwise: false);
      return TransformationResult.success;
    }

    // Pour les pièces du slider, rotation normale
    _applyIsoUsingLookup((p, idx) => p.rotationTW(idx));
    return TransformationResult.success;
  }

  /// Applique une symétrie (H/V swap en paysage)
  TransformationResult applyIsometrySymmetryH() {
    debugPrint(
      "ISO: SymH (view=${state.viewOrientation}) idx=${state.selectedPositionIndex} piece=${state.selectedPiece?.id} placed=${state.selectedPlacedPiece?.piece.id}",
    );

    // Pour les pièces placées, appliquer la symétrie relative à la mastercase si définie
    if (state.selectedPlacedPiece != null) {
      if (state.selectedCellInPiece != null) {
        final useHorizontal =
            state.viewOrientation == ViewOrientation.landscape ? false : true;
        _applySymmetryWithMastercase(isHorizontal: useHorizontal);
      } else {
        // Comportement classique si pas de mastercase
        _applySymmetryToPlacedPiece(isHorizontal: true);
      }
      return TransformationResult.success;
    }

    // Pour les pièces du slider, comportement classique
    if (state.viewOrientation == ViewOrientation.landscape) {
      _applyIsoUsingLookup((p, idx) => p.symmetryV(idx));
    } else {
      _applyIsoUsingLookup((p, idx) => p.symmetryH(idx));
    }
    return TransformationResult.success;
  }

  /// Applique une symétrie verticale (V/H swap en paysage)
  TransformationResult applyIsometrySymmetryV() {
    debugPrint(
      "ISO: SymV (view=${state.viewOrientation}) idx=${state.selectedPositionIndex} piece=${state.selectedPiece?.id} placed=${state.selectedPlacedPiece?.piece.id}",
    );

    // Pour les pièces placées, appliquer la symétrie relative à la mastercase si définie
    if (state.selectedPlacedPiece != null) {
      if (state.selectedCellInPiece != null) {
        final useHorizontal =
            state.viewOrientation == ViewOrientation.landscape ? true : false;
        _applySymmetryWithMastercase(isHorizontal: useHorizontal);
      } else {
        // Comportement classique si pas de mastercase
        _applySymmetryToPlacedPiece(isHorizontal: false);
      }
      return TransformationResult.success;
    }

    // Pour les pièces du slider, comportement classique
    if (state.viewOrientation == ViewOrientation.landscape) {
      _applyIsoUsingLookup((p, idx) => p.symmetryH(idx));
    } else {
      _applyIsoUsingLookup((p, idx) => p.symmetryV(idx));
    }
    return TransformationResult.success;
  }
  // ========================================================================
  // 🆕 GESTION ORIENTATION + ISOMÉTRIES LOOKUP (Pentoscope approach)
  // ========================================================================

  @override
  PentominoGameState build() {
    ref.onDispose(() {
      stopTimer();
    });
    final initialState = PentominoGameState.initial();
    // Calculer le total de solutions au démarrage (plateau vide = 9356)
    final totalSolutions = Plateau.allVisible(6, 10).countPossibleSolutions();
    return initialState.copyWith(solutionsCount: totalSolutions);
  }

  int calculateScore(int elapsedSeconds) {
    // Score basé sur rapidité : 100 - (secondes / 2)
    // Max 100 (< 10 sec), Min 0 (> 200 sec)
    int score = 100 - (elapsedSeconds ~/ 2);
    return score.clamp(0, 100);
  }

  /// Annule la sélection en cours
  void cancelSelection() {
    if (state.selectedPiece == null) return;

    // Stay + mask : une pièce posée sélectionnée n'a jamais quitté placedPieces.
    // Annuler revient à la démasquer (reconstruire le plateau) et à vider la
    // sélection. Pour une pièce du slider, il n'y a rien à démasquer.
    final wasPlaced = state.selectedPlacedPiece != null;
    final newPlateau = wasPlaced ? _rebuildPlateau() : state.plateau;

    // Dette 1 : la rotation abandonnée laissait solutionsCount périmé (calculé
    // pour une orientation qui n'est plus posée) — on recalcule depuis le plateau
    // reconstruit. Dette 2 : isComplete n'avait pas de chemin de retour vers true
    // (reprendre puis reposer une pièce sur un plateau plein le laissait à false).
    state = state.copyWith(
      plateau: newPlateau,
      solutionsCount: wasPlaced
          ? newPlateau.countPossibleSolutions()
          : state.solutionsCount,
      isComplete: wasPlaced && state.placedPieces.length == 12 && state.boardIsValid,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
    );

    if (wasPlaced) _recomputeBoardValidity();
  }


// ========================================================================
// 💡 HINT SYSTEM - Appliquer un indice basé sur une solution aléatoire
// ========================================================================

  /// Applique un indice en choisissant une solution compatible aléatoire
  /// et en plaçant une pièce du slider qui n'est pas encore posée
  void applyHint() {
    // 1️⃣ Récupérer les indices des solutions compatibles
    final compatibleIndices = state.plateau.getCompatibleSolutionIndices();

    if (compatibleIndices.isEmpty) {
      debugPrint('❌ HINT: Aucune solution compatible');
      return;
    }

    // 2️⃣ Choisir une solution au hasard
    final random = Random();
    final randomSolutionIndex = compatibleIndices[random.nextInt(compatibleIndices.length)];

    debugPrint(
      '💡 HINT: Solution sélectionnée #$randomSolutionIndex sur ${compatibleIndices.length} compatibles',
    );

    // 3️⃣ Décoder la solution BigInt en PlacedPiece
    final allSolutionPieces = solutionMatcher.getPlacedPiecesByIndex(randomSolutionIndex);

    if (allSolutionPieces == null || allSolutionPieces.isEmpty) {
      debugPrint('❌ HINT: Impossible de décoder la solution');
      return;
    }

    // 4️⃣ Trouver une pièce NON encore placée (du slider)
    final placedPieceIds = state.placedPieces.map((p) => p.piece.id).toSet();
    final PlacedPiece? hintPiece = allSolutionPieces.firstWhereOrNull(
          (p) => !placedPieceIds.contains(p.piece.id),
    );

    if (hintPiece == null) {
      debugPrint('❌ HINT: Aucune pièce nouvelle trouvée dans cette solution');
      return;
    }

    // 5️⃣ Ajouter cette pièce au plateau
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)..add(hintPiece);

    // 6️⃣ Reconstruire le plateau avec la nouvelle pièce
    final newPlateau = _rebuildPlateau(pieces: newPlaced);

    // 7️⃣ Retirer la pièce du slider
    final newAvailable = state.availablePieces
        .where((p) => p.id != hintPiece.piece.id)
        .toList();

    // 8️⃣ Recalculer le nombre de solutions compatibles
    final solutionsCount = newPlateau.countPossibleSolutions();

    // 9️⃣ Mettre à jour l'état
    // L'indice peut poser le 12e pentomino (dernier trou) : c'est un second
    // chemin de complétion, en plus de tryPlacePiece. On y pose isComplete pour
    // que la victoire se déclenche comme avant (l'ancien code lisait length == 12).
    state = state.copyWith(
      plateau: newPlateau,
      placedPieces: newPlaced,
      availablePieces: newAvailable,
      solutionsCount: solutionsCount,
      isComplete: newPlaced.length == 12,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      clearPreview: true,
    );

    _recomputeBoardValidity();

    debugPrint(
      '✅ HINT: Pièce ${hintPiece.piece.id} placée à (${hintPiece.gridX}, ${hintPiece.gridY}) position ${hintPiece.positionIndex}',
    );
    debugPrint('🎯 Solutions restantes: $solutionsCount');
  }

  // ✨ AJOUT: Appelé quand le puzzle est complété (12 pièces placées)
  Future<void> onPuzzleCompleted() async {
    stopTimer(); // fin de partie : l'origine est conservée

    final elapsedSeconds = state.elapsedSeconds;
    final isometriesCount = state.isometriesCount;
    final solutionsViewCount = state.solutionsViewCount;

    debugPrint('✅ PUZZLE COMPLÉTÉ!');
    debugPrint('   Pièces placées: ${state.placedPieces.length}');
    debugPrint('   Temps écoulé: ${elapsedSeconds}s');
    debugPrint('   Isométries utilisées: $isometriesCount');
    debugPrint('   Solutions consultées: $solutionsViewCount');

    // Utiliser le numéro de solution identifié (+1 pour affichage human-friendly 1-9356)
    final solutionNumber = state.solvedSolutionIndex != null 
        ? state.solvedSolutionIndex! + 1 
        : -1;

    // Score à 0 pour l'instant (à définir plus tard)
    const score = 0;

    // Sauvegarder la session via le provider de base de données
    try {
      final database = ref.read(settingsDatabaseProvider);
      await database.saveGameSession(
        solutionNumber: solutionNumber,
        elapsedSeconds: elapsedSeconds,
        score: score,
        piecesPlaced: 12,
        numUndos: 0,  // À calculer si tu tracks les annulations
        isometriesCount: isometriesCount,
        solutionsViewCount: solutionsViewCount,
      );

      debugPrint('✅ Session sauvegardée');
      debugPrint('   Solution #$solutionNumber');

    } catch (e) {
      debugPrint('❌ Erreur sauvegarde: $e');
    }
  }

  /// 🆕 Incrémente le compteur de consultation des solutions
  void incrementSolutionsViewCount() {
    state = state.copyWith(solutionsViewCount: state.solutionsViewCount + 1);
    debugPrint('[GAME] 👁️ Solutions consultées: ${state.solutionsViewCount} fois');
  }




  /// Cycle vers l'orientation suivante de la pièce sélectionnée
  /// Passe simplement à l'index suivant dans piece.orientations (boucle)
  void cycleToNextOrientation() {
    // Pour une pièce sélectionnée (pas encore placée)
    if (state.selectedPiece != null) {
      final piece = state.selectedPiece!;
      final currentIndex = state.selectedPositionIndex;
      final nextIndex = (currentIndex + 1) % piece.numOrientations;


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
      final nextIndex = (currentIndex + 1) % selectedPiece.piece.numOrientations;


      // Créer la pièce avec la nouvelle orientation
      final transformedPiece = selectedPiece.copyWith(positionIndex: nextIndex);

      // Recalculer les solutions possibles
      final solutionsCount = _computeSolutionsWithTransformedPiece(
        transformedPiece,
      );
      debugPrint('[GAME] 🎯 Solutions possibles après cycle : $solutionsCount');

      // Mettre à jour l'état
      state = state.copyWith(
        selectedPlacedPiece: _keepOnBoard(transformedPiece),
        selectedPositionIndex: nextIndex,
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

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
      final position = placed.piece.orientations[placed.positionIndex];

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


  /// Retire une pièce placée du plateau
  void removePlacedPiece(PlacedPiece placedPiece) {
    // Reconstruire le plateau sans cette pièce
    final newPlateau = _rebuildPlateau(exclude: placedPiece);

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
    final solutionsCount = newPlateau.countPossibleSolutions();

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      solutionsCount: solutionsCount,
      isComplete: false,
    );
    _recomputeBoardValidity();

    debugPrint('[GAME] 🗑️ Pièce ${placedPiece.piece.id} retirée du plateau');
    if (solutionsCount != null) {
      debugPrint('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }
  }

  /// Réinitialise le jeu
  void reset() {
    resetTimer(); // nouvelle partie : le chrono repart de zéro
    final initialState = PentominoGameState.initial();
    final totalSolutions = Plateau.allVisible(6, 10).countPossibleSolutions();
    state = initialState.copyWith(solutionsCount: totalSolutions);
  }

  /// Remet le slider à sa position initiale
  void resetSliderPosition() {
    state = state.copyWith(sliderOffset: 0);
    debugPrint('[SLIDER] Slider remis à la position initiale');
  }

  // ============================================================
  // DÉFILEMENT DU SLIDER
  // ============================================================

  /// Fait défiler le slider de N positions
  /// positions > 0 : vers la droite
  /// positions < 0 : vers la gauche
  void scrollSlider(int positions) {
    final newOffset = (state.sliderOffset + positions) % 12;
    state = state.copyWith(sliderOffset: newOffset);
    debugPrint(
      '[SLIDER] Slider décalé de $positions positions (offset: $newOffset)',
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
    debugPrint('[SLIDER] Slider centré sur pièce $pieceNumber');
  }

  // ============================================================
  // SÉLECTION DEPUIS LE SLIDER
  // ============================================================

  /// Sélectionne une pièce du slider (commence le drag)
  void selectPiece(Pento piece) {
    // Récupérer l'index de position sauvegardé pour cette pièce
    final savedIndex = state.getPiecePositionIndex(piece.id);
    // Si une pièce du plateau est déjà sélectionnée, la replacer d'abord
    debugPrint('[DEBUG PAYSAGE] 🔍 selectPiece(${piece.id})');
    debugPrint(
      '[DEBUG PAYSAGE] 📋 piecePositionIndices: ${state.piecePositionIndices}',
    );
    debugPrint('[DEBUG PAYSAGE] 📌 savedIndex pour pièce ${piece.id}: $savedIndex');

    // Stay + mask : une éventuelle pièce posée sélectionnée n'a jamais quitté
    // placedPieces ; sélectionner une pièce du slider la démasque simplement en
    // reconstruisant le plateau complet (rien n'est masqué pour une pièce du slider).

    // Définir une case de référence par défaut (première case de la pièce)
    final position = piece.orientations[savedIndex];
    Point? defaultCell;
    if (position.isNotEmpty) {
      final firstCellNum = position[0];
      defaultCell = Point((firstCellNum - 1) % 5, (firstCellNum - 1) ~/ 5);
    }

    // Dette 1 : si une pièce posée était sélectionnée, sa rotation est abandonnée
    // ici ; on recalcule solutionsCount depuis le plateau reconstruit (une seule
    // reconstruction, réutilisée) plutôt que de laisser un compteur périmé.
    final newPlateau = _rebuildPlateau();
    state = state.copyWith(
      plateau: newPlateau,
      solutionsCount: newPlateau.countPossibleSolutions(),
      selectedPiece: piece,
      selectedPositionIndex: savedIndex, // Utilise l'index sauvegardé
      clearSelectedPlacedPiece: true,
      selectedCellInPiece: defaultCell,
    );
    _recomputeBoardValidity();
  }

  // ============================================================
  // SÉLECTION SUR LE PLATEAU
  // ============================================================

  /// Sélectionne une pièce déjà placée pour la déplacer
  /// [cellX] et [cellY] sont les coordonnées de la case touchée sur le plateau

  /// Sélectionne une pièce déjà placée pour la déplacer
  /// [cellX] et [cellY] sont les coordonnées de la case touchée sur le plateau
  void selectPlacedPiece(PlacedPiece placedPiece, int cellX, int cellY) {
    // Stay + mask : la pièce sélectionnée reste dans placedPieces ; seule la
    // reconstruction du plateau l'ignore (exclude:). Une éventuelle autre pièce
    // déjà sélectionnée est démasquée d'elle-même par cette reconstruction.

    // Trouver quelle case de la pièce correspond à (cellX, cellY)
    final position = placedPiece.piece.orientations[placedPiece.positionIndex];
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

    // Masquer la pièce sélectionnée du plateau (elle reste dans placedPieces)
    final newPlateau = _rebuildPlateau(exclude: placedPiece);

    // Calculer les solutions en incluant la pièce sélectionnée
    final solutionsCount = _computeSolutionsWithTransformedPiece(placedPiece);

    // Sélectionner la pièce avec sa position actuelle et la case de référence
    state = state.copyWith(
      plateau: newPlateau,
      selectedPiece: placedPiece.piece,
      selectedPositionIndex: placedPiece.positionIndex,
      selectedPlacedPiece: placedPiece,
      selectedCellInPiece: selectedCell,
      solutionsCount: solutionsCount,
    );

    debugPrint(
      '[GAME] 🔄 Pièce ${placedPiece.piece.id} sélectionnée pour déplacement (case ref: $selectedCell)',
    );
  }

  /// Enregistre l'orientation de la vue (portrait/landscape)
  void setViewOrientation(bool isLandscape) {
    final orientation =
    isLandscape ? ViewOrientation.landscape : ViewOrientation.portrait;
    state = state.copyWith(viewOrientation: orientation);
  }

  // ============================================================
  // PLACEMENT
  // ============================================================



  /// Tente de placer la pièce sélectionnée sur le plateau
  /// [gridX] et [gridY] sont les coordonnées où on lâche la pièce (position du doigt)
  /// Tente de placer la pièce sélectionnée sur le plateau
  /// [gridX] et [gridY] sont les coordonnées où on lâche la pièce (position du doigt)
  bool tryPlacePiece(int gridX, int gridY) {
    if (state.selectedPiece == null) return false;

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;
    debugPrint(
      '[DEBUG PLACEMENT] 🎯 tryPlacePiece: piece=${piece.id}, positionIndex=$positionIndex',
    );
    debugPrint(
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

      debugPrint(
        '[GAME] Translation: lâcher à ($gridX, $gridY), case ref locale (${state.selectedCellInPiece!.x}, ${state.selectedCellInPiece!.y}), anchor ($anchorX, $anchorY)',
      );
    }
// Vérifier position exacte
    bool canPlace = state.canPlacePiece(piece, positionIndex, anchorX, anchorY);

    // Si pas valide, essayer le snap
    if (!canPlace) {
      final snapped = _findNearestValidPosition(piece, positionIndex, anchorX, anchorY);
      if (snapped != null) {
        anchorX = snapped.x;
        anchorY = snapped.y;
        canPlace = true;
        debugPrint('[GAME] 🧲 Snap appliqué: nouvelle position ($anchorX, $anchorY)');
      }
    }

    if (!canPlace) {
      debugPrint('[GAME] ❌ Placement impossible à ($anchorX, $anchorY)');
      return false;
    }

    // Vérifier si la pièce peut être placée
    if (!state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      debugPrint('[GAME] ❌ Placement impossible à ($anchorX, $anchorY)');
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
    final position = piece.orientations[positionIndex];

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

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlateau.countPossibleSolutions();

    // ✅ Si c'était une pièce placée, on la garde sélectionnée (comme pour rotation/symétrie)
    if (wasPlacedPiece) {
      // Déplacement : sous stay + mask la pièce n'a jamais quitté placedPieces.
      // On remplace son entrée par sa nouvelle position (map par id, jamais add :
      // un ajout créerait un doublon). Elle reste sélectionnée, donc masquée du
      // plateau ; availablePieces est inchangé (une pièce posée n'y était pas).
      final newPlacedPieces = state.placedPieces
          .map((p) => p.piece.id == piece.id ? placedPiece : p)
          .toList();
      final plateauSansPiece = _rebuildPlateau(exclude: placedPiece);

      state = state.copyWith(
        plateau: plateauSansPiece,
        availablePieces: state.availablePieces,
        placedPieces: newPlacedPieces,
        selectedPiece: piece,
        selectedPositionIndex: positionIndex,
        selectedPlacedPiece:
        placedPiece, // ✅ Garder la référence à la nouvelle position
        selectedCellInPiece: savedCellInPiece, // ✅ Garder la master cell
        solutionsCount: solutionsCount,
        isComplete: false, // pièce encore tenue : plateau incomplet
        clearPreview: true,
      );
      _recomputeBoardValidity();

      debugPrint(
        '[GAME] ✅ Pièce ${piece.id} déplacée à ($anchorX, $anchorY) - reste sélectionnée',
      );
      debugPrint('[GAME] 🎯 Solutions possibles: $solutionsCount');
    } else {
      // C'était une pièce du slider → nouvelle pièce ajoutée, puis désélection.
      final newPlacedPieces = [...state.placedPieces, placedPiece];
      final newAvailable = state.availablePieces
          .where((p) => p.id != piece.id)
          .toList();
      final isComplete = newPlacedPieces.length == 12;

      state = state.copyWith(
        plateau: newPlateau,
        availablePieces: newAvailable,
        placedPieces: newPlacedPieces,
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        solutionsCount: solutionsCount,
        isComplete: isComplete,
        clearPreview: true,
      );
      _recomputeBoardValidity();

      debugPrint('[GAME] ✅ Pièce ${piece.id} placée à ($anchorX, $anchorY)');
      debugPrint('[GAME] Pièces restantes: ${newAvailable.length}');
      debugPrint('[GAME] 🎯 Solutions possibles: $solutionsCount');

      // ✨ Si puzzle complet, identifier la solution et arrêter le timer
      if (newAvailable.isEmpty) {
        stopTimer();
        final solutionIndex = newPlateau.findExactSolutionIndex();
        if (solutionIndex >= 0) {
          final info = SolutionInfo(solutionIndex);
          state = state.copyWith(solvedSolutionIndex: solutionIndex);
          debugPrint('[GAME] 🎉 Puzzle complété! Solution #${info.index}');
          debugPrint('[GAME]    (canonique ${info.canonicalIndex}, ${info.variantName})');
          debugPrint('[GAME]    Temps: ${getElapsedSeconds()} secondes');
        } else {
          debugPrint('[GAME] 🎉 Puzzle complété! Temps: ${getElapsedSeconds()} secondes');
          debugPrint('[GAME] ⚠️  Solution non identifiée dans la base');
        }
      }
    }

    return true;
  }

  /// Retire la dernière pièce placée (undo)
  void undoLastPlacement() {
    if (state.placedPieces.isEmpty) return;

    final lastPlaced = state.placedPieces.last;

    // Recréer le plateau sans la dernière pièce
    final newPlateau = _rebuildPlateau(exclude: lastPlaced);

    // Remettre la pièce dans les disponibles
    final newAvailable = List<Pento>.from(state.availablePieces)
      ..add(lastPlaced.piece);

    // Retrier par ID pour garder l'ordre
    newAvailable.sort((a, b) => a.id.compareTo(b.id));

    // Retirer de la liste des placées
    final newPlaced = List<PlacedPiece>.from(state.placedPieces)..removeLast();

    // Calculer le nombre de solutions possibles
    final solutionsCount = newPlateau.countPossibleSolutions();

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlaced,
      solutionsCount: solutionsCount,
      isComplete: false,
      clearSolvedSolutionIndex: true, // 🆕 Réinitialiser si on retire une pièce
    );

    debugPrint('[GAME] ↩️ Undo: Pièce ${lastPlaced.piece.id} retirée');
    if (solutionsCount != null) {
      debugPrint('[GAME] 🎯 Solutions possibles: $solutionsCount');
    }
  }

  // ============================================================
  // CONTRÔLE DU SLIDER
  // ============================================================

  /// Met à jour la prévisualisation du placement pendant le drag
  /// AVEC SNAP INTELLIGENT
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

    // 1. Vérifier la position exacte d'abord
    if (state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      _updatePreviewState(anchorX, anchorY, isValid: true, isSnapped: false);
      return;
    }

    // 2. Chercher la position valide la plus proche (snap)
    final snapped = _findNearestValidPosition(piece, positionIndex, anchorX, anchorY);

    if (snapped != null) {
      _updatePreviewState(snapped.x, snapped.y, isValid: true, isSnapped: true);
    } else {
      // Aucune position valide proche → preview rouge à la position du curseur
      _updatePreviewState(anchorX, anchorY, isValid: false, isSnapped: false);
    }
  }


  /// Ramène une pièce posée à l'intérieur du plateau après une isométrie.
  ///
  /// Une rotation ou une symétrie change l'empreinte de la pièce sans déplacer son
  /// ancre : une pièce collée à un bord peut donc se retrouver partiellement hors
  /// plateau, et s'afficher tronquée. Aucune des quatre méthodes d'isométrie ne
  /// vérifiait les bornes — c'est la raison pour laquelle elles renvoyaient toujours
  /// [TransformationResult.success].
  ///
  /// Le décalage appliqué est **minimal** : juste ce qu'il faut pour que toutes les
  /// cellules rentrent. Le comportement s'aligne sur celui de Pentoscope, qui
  /// recentre déjà (voir son `neededRecentering`).
  ///
  /// Ne vérifie **que les bornes**, pas les chevauchements avec d'autres pièces :
  /// c'est le défaut signalé, et l'état `boardIsValid` continue de signaler le reste.
  PlacedPiece _keepOnBoard(PlacedPiece piece) {
    final cells = piece.absoluteCells.toList();
    if (cells.isEmpty) return piece;

    final w = state.plateau.width;
    final h = state.plateau.height;
    final minX = cells.map((c) => c.x).reduce(min);
    final maxX = cells.map((c) => c.x).reduce(max);
    final minY = cells.map((c) => c.y).reduce(min);
    final maxY = cells.map((c) => c.y).reduce(max);

    var dx = 0;
    if (minX < 0) {
      dx = -minX;
    } else if (maxX >= w) {
      dx = w - 1 - maxX;
    }

    var dy = 0;
    if (minY < 0) {
      dy = -minY;
    } else if (maxY >= h) {
      dy = h - 1 - maxY;
    }

    if (dx == 0 && dy == 0) return piece;

    debugPrint('🧲 Recentrage après isométrie : décalage ($dx, $dy)');
    return piece.copyWith(gridX: piece.gridX + dx, gridY: piece.gridY + dy);
  }

  /// Applique une transformation isométrique via lookup
  void _applyIsoUsingLookup(int Function(Pento p, int idx) f) {
    final piece = state.selectedPiece;
    if (piece == null) return;
    final oldIdx = state.selectedPositionIndex;
    final newIdx = f(piece, oldIdx);

    // 🆕 Incrémenter le compteur d'isométries
    state = state.copyWith(
      selectedPositionIndex: newIdx,
      selectedCellInPiece: _remapSelectedCell(
        piece: piece,
        oldIndex: oldIdx,
        newIndex: newIdx,
        oldCell: state.selectedCellInPiece,
      ),
      clearPreview: true,
      isometriesCount: state.isometriesCount + 1,
    );

    final sp = state.selectedPlacedPiece;
    if (sp != null) {
      state = state.copyWith(
        selectedPlacedPiece: _keepOnBoard(sp.copyWith(positionIndex: newIdx)),
      );
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================


  /// Reconstruit le plateau depuis une liste de pièces posées.
  ///
  /// [pieces]  : liste source (défaut : state.placedPieces)
  /// [exclude] : pièce à ignorer, par son id
  Plateau _rebuildPlateau({
    List<PlacedPiece>? pieces,
    PlacedPiece? exclude,
  }) {
    final src = pieces ?? state.placedPieces;
    final p = Plateau.allVisible(state.plateau.width, state.plateau.height);
    for (final placed in src) {
      if (exclude != null && placed.piece.id == exclude.piece.id) continue;
      for (final cell in placed.absoluteCells) {
        p.setCell(cell.x, cell.y, placed.piece.id);
      }
    }
    return p;
  }

  /// Calcule le nombre de solutions possibles avec une pièce transformée
  /// Crée temporairement un plateau avec toutes les pièces incluant la transformée
  int? _computeSolutionsWithTransformedPiece(PlacedPiece transformedPiece) {
    // Stay + mask : la pièce transformée est déjà dans placedPieces à son
    // ancienne orientation. On remplace son entrée (map par id), sinon elle
    // figurerait deux fois et l'ancienne empreinte subsisterait sous la nouvelle.
    final tempPlateau = _rebuildPlateau(
      pieces: state.placedPieces
          .map((p) => p.piece.id == transformedPiece.piece.id ? transformedPiece : p)
          .toList(),
    );

    // Calculer les solutions possibles
    return tempPlateau.countPossibleSolutions();
  }

  /// Cherche la position valide la plus proche dans un rayon donné
  /// 
  /// ✅ Utilise maintenant la méthode du mixin
  Point? _findNearestValidPosition(Pento piece, int positionIndex, int anchorX, int anchorY) {
    return findNearestValidPosition(
      piece: piece,
      positionIndex: positionIndex,
      anchorX: anchorX,
      anchorY: anchorY,
      snapRadius: _snapRadius,
    );
  }

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

  /// Remapping de la cellule de référence lors d'une isométrie
  /// 
  /// ✅ Utilise maintenant la méthode du mixin (version robuste)
  Point? _remapSelectedCell({
    required Pento piece,
    required int oldIndex,
    required int newIndex,
    required Point? oldCell,
  }) {
    return remapSelectedCell(
      piece: piece,
      oldIndex: oldIndex,
      newIndex: newIndex,
      oldCell: oldCell,
    );
  }


  /// Applique une symétrie relative à la mastercase pour une pièce placée
  void _applySymmetryWithMastercase({required bool isHorizontal}) {
    final placedPiece = state.selectedPlacedPiece;
    if (placedPiece == null || state.selectedCellInPiece == null) return;

    final piece = placedPiece.piece;
    final currentIndex = placedPiece.positionIndex;
    final mastercase = state.selectedCellInPiece!;

    final masterAbs = Point(
      placedPiece.gridX + mastercase.x,
      placedPiece.gridY + mastercase.y,
    );

    final position = piece.orientations[currentIndex];
    final cellsAbs = position.map((cellNum) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      return Point(placedPiece.gridX + localX, placedPiece.gridY + localY);
    }).toList();

    final symAbs = applySymmetryAbs(
      cellsAbs: cellsAbs,
      masterAbs: masterAbs,
      type: isHorizontal ? SymmetryType.horizontal : SymmetryType.vertical,
    );

    final normalized = normalizeCoords(symAbs);
    final newIndex = findOrientationIndexFromNormalized(
      piece: piece,
      normalizedCoords: normalized,
    );

    if (newIndex == null || newIndex == currentIndex) return;

    final newPosition = piece.orientations[newIndex];
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in newPosition) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    final minAbsX = symAbs.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minAbsY = symAbs.map((p) => p.y).reduce((a, b) => a < b ? a : b);

    final newGridX = minAbsX - minLocalX;
    final newGridY = minAbsY - minLocalY;

    final transformedPiece = placedPiece.copyWith(
      positionIndex: newIndex,
      gridX: newGridX,
      gridY: newGridY,
    );

    // Recalculer les solutions possibles
    final solutionsCount = _computeSolutionsWithTransformedPiece(transformedPiece);
    debugPrint('[GAME] 🎯 Solutions possibles après symétrie ${isHorizontal ? 'horizontale' : 'verticale'} (mastercase) : $solutionsCount');

    // Mettre à jour l'état
    state = state.copyWith(
      selectedPlacedPiece: _keepOnBoard(transformedPiece),
      selectedPositionIndex: newIndex,
      selectedCellInPiece: _computeMastercaseForAbs(
        piece: piece,
        positionIndex: newIndex,
        gridX: newGridX,
        gridY: newGridY,
        masterAbs: masterAbs,
      ),
      solutionsCount: solutionsCount,
    );
    _recomputeBoardValidity();
  }

  /// Applique une symétrie classique à une pièce placée (sans mastercase)
  void _applySymmetryToPlacedPiece({required bool isHorizontal}) {
    final placedPiece = state.selectedPlacedPiece;
    if (placedPiece == null) return;

    final piece = placedPiece.piece;
    final currentIndex = placedPiece.positionIndex;

    // Appliquer la symétrie classique
    final newIndex = isHorizontal ? piece.symmetryH(currentIndex) : piece.symmetryV(currentIndex);

    if (newIndex == currentIndex) return; // Pas de changement

    // Créer la pièce avec la nouvelle orientation
    final transformedPiece = placedPiece.copyWith(positionIndex: newIndex);

    // Recalculer les solutions possibles
    final solutionsCount = _computeSolutionsWithTransformedPiece(transformedPiece);
    debugPrint('[GAME] 🎯 Solutions possibles après symétrie ${isHorizontal ? 'horizontale' : 'verticale'} : $solutionsCount');

    // Mettre à jour l'état
    state = state.copyWith(
      selectedPlacedPiece: _keepOnBoard(transformedPiece),
      selectedPositionIndex: newIndex,
      solutionsCount: solutionsCount,
    );
    _recomputeBoardValidity();
  }

  /// Applique une rotation spécifique à une pièce placée en maintenant la mastercase fixe
  void _applyRotationToPlacedPiece({required bool isClockwise}) {
    final placedPiece = state.selectedPlacedPiece;
    if (placedPiece == null) return;

    final piece = placedPiece.piece;
    final currentIndex = placedPiece.positionIndex;
    final mastercase = state.selectedCellInPiece;

    if (mastercase != null) {
      final masterAbs = Point(
        placedPiece.gridX + mastercase.x,
        placedPiece.gridY + mastercase.y,
      );

      final position = piece.orientations[currentIndex];
      final cellsAbs = position.map((cellNum) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        return Point(placedPiece.gridX + localX, placedPiece.gridY + localY);
      }).toList();

      final rotAbs = applyRotationAbs(
        cellsAbs: cellsAbs,
        masterAbs: masterAbs,
        clockwise: isClockwise,
      );

      final normalized = normalizeCoords(rotAbs);
      final newIndex = findOrientationIndexFromNormalized(
        piece: piece,
        normalizedCoords: normalized,
      );

      if (newIndex == null || newIndex == currentIndex) return;

      final newPosition = piece.orientations[newIndex];
      int minLocalX = 5, minLocalY = 5;
      for (final cellNum in newPosition) {
        final localX = (cellNum - 1) % 5;
        final localY = (cellNum - 1) ~/ 5;
        if (localX < minLocalX) minLocalX = localX;
        if (localY < minLocalY) minLocalY = localY;
      }

      final minAbsX = rotAbs.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final minAbsY = rotAbs.map((p) => p.y).reduce((a, b) => a < b ? a : b);

      final newGridX = minAbsX - minLocalX;
      final newGridY = minAbsY - minLocalY;

      final transformedPiece = placedPiece.copyWith(
        positionIndex: newIndex,
        gridX: newGridX,
        gridY: newGridY,
      );

      final solutionsCount =
          _computeSolutionsWithTransformedPiece(transformedPiece);
      debugPrint(
        '[GAME] 🎯 Solutions possibles après rotation ${isClockwise ? 'horaire' : 'anti-horaire'} : $solutionsCount',
      );

      state = state.copyWith(
        selectedPlacedPiece: _keepOnBoard(transformedPiece),
        selectedPositionIndex: newIndex,
        selectedCellInPiece: _computeMastercaseForAbs(
          piece: piece,
          positionIndex: newIndex,
          gridX: newGridX,
          gridY: newGridY,
          masterAbs: masterAbs,
        ),
        solutionsCount: solutionsCount,
      );
      _recomputeBoardValidity();
      return;
    }

    // Appliquer la rotation spécifique
    final newIndex = isClockwise ? piece.rotationCW(currentIndex) : piece.rotationTW(currentIndex);

    if (newIndex == currentIndex) return; // Pas de changement

    // Créer la pièce avec la nouvelle orientation
    final transformedPiece = placedPiece.copyWith(positionIndex: newIndex);

    // Recalculer les solutions possibles
    final solutionsCount = _computeSolutionsWithTransformedPiece(transformedPiece);
    debugPrint('[GAME] 🎯 Solutions possibles après rotation ${isClockwise ? 'horaire' : 'anti-horaire'} : $solutionsCount');

    // Mettre à jour l'état
    state = state.copyWith(
      selectedPlacedPiece: _keepOnBoard(transformedPiece),
      selectedPositionIndex: newIndex,
      solutionsCount: solutionsCount,
    );
    _recomputeBoardValidity();
  }

  Point? _computeMastercaseForAbs({
    required Pento piece,
    required int positionIndex,
    required int gridX,
    required int gridY,
    required Point masterAbs,
  }) {
    final position = piece.orientations[positionIndex];
    final expectedRaw = Point(masterAbs.x - gridX, masterAbs.y - gridY);

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX == expectedRaw.x && localY == expectedRaw.y) {
        return expectedRaw;
      }
    }

    return null;
  }

  /// Met à jour l'état de la preview (évite les rebuilds inutiles)
  void _updatePreviewState(int x, int y, {required bool isValid, required bool isSnapped}) {
    if (state.previewX != x ||
        state.previewY != y ||
        state.isPreviewValid != isValid ||
        state.isSnapped != isSnapped) {
      state = state.copyWith(
        previewX: x,
        previewY: y,
        isPreviewValid: isValid,
        isSnapped: isSnapped,
      );
    }
  }

}
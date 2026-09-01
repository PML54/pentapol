// Modified: 2026-09-01 07:54 — correctif 4 (PLAN_DEPLACEMENT_PIECE §4) : plafond d'aimantation ~1,5
//           case dans _findClosestValidPlacement (défaut 3.1) ; au-delà, aperçu rouge à l'ancre
//           désirée dans updatePreview. Dépend des correctifs 1 et 2 (§7).
// Historique: 2026-09-01 07:54 — correctif 3 : tryPlaceAtAnchor + dépôt à previewX/previewY (défaut 3.3).
// Historique: 2026-09-01 07:54 — correctif 2 : setDragMastercase ancre le glissé sur la case saisie (b).
// Historique: 2026-08-31 17:00 — suppression de la difficulté : enum PentoscopeDifficulty retiré,
//             startPuzzle n'appelle plus que generate(size) (plus de switch easy/hard/random).
//             solutionCount de PentoscopePuzzle devient int? (aucun compte honnête hors 6×10).
// Historique: 2026-08-30 11:40 — PLAN_PERSISTANCE §7 étape 3 : records. _saveCompletedLevel (qui
//             écrivait dans les préférences clé/valeur une donnée jamais relue) remplacé par
//             _saveCompletionRecord qui écrit dans SolvedSolutions/PuzzleStats via solutionIndexOf.
// lib/pentoscope/pentoscope_provider.dart
// Historique: 2026-08-30 06:58 — PLAN_BILAN §5 : le chrono ne s'arrêtait pas en fin de partie.
//             (A) garde de tryPlacePiece exclut isComplete ; (B) resetTimer() aux 3 démarrages.
// Historique: 2026-08-30 06:04 — PLAN_BILAN §3 : retrait du champ de score théorique (min.
//             d'isométries) et de ses deux boucles de calcul (startPuzzle, startPuzzleFromSeed).
// Historique: 2026-08-29 20:22 — §8 étape 3 : retrait de changeBoardSize, sans appelant depuis
//             que le dialogue « Nouvelle partie » appelle startPuzzle directement.
// Historique: 2026-08-29 13:43 — suppression du mode classique (§3.1) : méthode publique
//             compatibleSolutions() pour le navigateur branché dans Pentoscope.
// Historique: 2026-08-29 10:05 — 6×10 temps 2 étape 5 : champ solutionsCount, helper
//             _solutionStatus (remplace _checkHasPossibleSolutionWith).
// Historique: 2026-08-29 09:26 — temps 2 étapes 4/6 : champ _solutions (SolutionSource) posé
//             par _makeSolutionSource ; hasPossibleSolution et applyHint via _solutions.
// Historique: 2026-08-29 07:46 — temps 1 : garde de court-circuit dans
//             _checkHasPossibleSolutionWith.
//             2026-08-28 20:30 — suppression démo : retrait du bloc de 7 méthodes de
//             démonstration, publiques sans appelant.
//             2026-08-28 04:48 — étape 3 : extraction de GameTimerMixin et PieceInteractionMixin.
//             startTimer/stopTimer/getElapsedSeconds, clearPreview et setDragging retirés du
//             provider ; fournis par les mixins via stateWith* (elapsedSeconds/preview/isDragging).
//             Le garde du timer passe de _gameTimer==null à !isTimerRunning.
// Modified: 2026-08-27 20:29 — étape 1 du plan d'unification : PentoscopeState implémente le
//           contrat commun PieceManipulationState ; ViewOrientation déplacé dans
//           common/ et ré-exporté d'ici. Aucun champ ni site d'appel modifié.
// Modified: 2026-08-27 19:57 — fusion de PentoscopePlacedPiece dans common/PlacedPiece :
//           classe locale supprimée, 19 références renommées. Aucun changement
//           de comportement (aucune comparaison objet à objet dans ce fichier).
// lib/pentoscope/pentoscope_provider.dart
// Modified: 2605030800
// Pentoscope: translation mastercase / snap
// CHANGEMENTS: (1) selectedMasterAbs et _calculateDesiredAnchorFromDrag, (2) snap sur ancre désirée + synchro masterAbs après isométries
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/common/transformation_result.dart';
export 'package:pentapol/common/transformation_result.dart';
import 'package:pentapol/common/view_orientation.dart';
import 'package:pentapol/common/piece_manipulation_state.dart';
export 'package:pentapol/common/view_orientation.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/game_timer_mixin.dart';
import 'package:pentapol/common/piece_interaction_mixin.dart';
import 'package:pentapol/common/pentomino_game_mixin.dart';
import 'package:pentapol/common/pentomino_symmetry_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/solution_source.dart';
import 'package:pentapol/pentoscope/pentoscope_solutions_provider.dart';
import 'package:pentapol/pentoscope/corpus_provider.dart';

// ============================================================================
// ÉTAT
// ============================================================================

final pentoscopeProvider =
    NotifierProvider<PentoscopeNotifier, PentoscopeState>(
      PentoscopeNotifier.new,
    );

// ============================================================================
// PROVIDER
// ============================================================================

// TransformationResult vit désormais dans common/transformation_result.dart,
// ré-exporté ci-dessus pour que les imports existants continuent de fonctionner.

class PentoscopeNotifier extends Notifier<PentoscopeState> 
    with PentominoGameMixin, GameTimerMixin<PentoscopeState>, PieceInteractionMixin<PentoscopeState> {
  @override
  PentoscopeState stateWithDragging(bool isDragging) =>
      state.copyWith(isDragging: isDragging);

  @override
  PentoscopeState stateWithPreviewCleared() =>
      state.copyWith(clearPreview: true);

  @override
  PentoscopeState stateWithElapsedSeconds(int elapsedSeconds) =>
      state.copyWith(elapsedSeconds: elapsedSeconds);

  late final PentoscopeGenerator _generator;

  /// D'où viennent les réponses « solution » du puzzle courant. Posé à chaque
  /// création de puzzle par _makeSolutionSource. Défaut : source de corpus vide,
  /// tant qu'aucun puzzle n'est démarré (aucune requête ne l'atteint avant).
  late SolutionSource _solutions;

  /// Le puzzle courant vient-il d'une partie multijoueur (startPuzzleFromSeed) ?
  /// La persistance (CurrentGame, records) est **solo uniquement** : le multijoueur
  /// partage ce provider mais ne doit ni sauvegarder ni enregistrer de record.
  bool _isMultiplayer = false;

  // ⏱️ Timer
  
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

  TransformationResult applyIsometryRotationCW() {
    return _applyIsoUsingLookup((p, idx) => p.rotationCW(idx));
  }

  TransformationResult applyIsometryRotationTW() {
    return _applyIsoUsingLookup((p, idx) => p.rotationTW(idx));
  }

  TransformationResult applyIsometrySymmetryH() {
    if (state.viewOrientation == ViewOrientation.landscape) {
      if (state.selectedPlacedPiece != null && state.selectedCellInPiece != null) {
        return _applySymmetryAbs(SymmetryType.vertical);
      }
      return _applyIsoUsingLookup((p, idx) => p.symmetryV(idx));
    } else {
      if (state.selectedPlacedPiece != null && state.selectedCellInPiece != null) {
        return _applySymmetryAbs(SymmetryType.horizontal);
      }
      return _applyIsoUsingLookup((p, idx) => p.symmetryH(idx));
    }
  }

  TransformationResult applyIsometrySymmetryV() {
    if (state.viewOrientation == ViewOrientation.landscape) {
      if (state.selectedPlacedPiece != null && state.selectedCellInPiece != null) {
        return _applySymmetryAbs(SymmetryType.horizontal);
      }
      return _applyIsoUsingLookup((p, idx) => p.symmetryH(idx));
    } else {
      if (state.selectedPlacedPiece != null && state.selectedCellInPiece != null) {
        return _applySymmetryAbs(SymmetryType.vertical);
      }
      return _applyIsoUsingLookup((p, idx) => p.symmetryV(idx));
    }
  }

  @override
  PentoscopeState build() {
    ref.onDispose(() {
      stopTimer();
    });
    _generator = PentoscopeGenerator();
    _solutions = CorpusSolutionSource.empty();
    return PentoscopeState.initial();
  }

  /// Choisit la source de solutions du puzzle, **toujours adossée à une table**
  /// pré-calculée (§8 B) : le 6×10 via son [SolutionMatcher] (BigInt, navigateur),
  /// toute autre taille via le corpus découpé au masque du tirage. Plus de solveur
  /// à la volée sur le chemin chaud. **Seul site lisant `size.table`** (§4.2).
  Future<SolutionSource> _makeSolutionSource(
    PentoscopeSize size,
    List<int> pieceIds,
  ) async {
    final table = size.table;
    if (table != null) {
      final matcher = await ref.read(pentoscopeSolutionsProvider(table).future);
      return TableSolutionSource(matcher, table);
    }
    final corpus = await ref.read(tirageCorpusProvider.future);
    return CorpusSolutionSource(
      corpus.solutionsFor(_maskOf(pieceIds)),
      width: size.width,
      height: size.height,
    );
  }

  /// Masque 12 bits d'un tirage : bit (id − 1) par pièce présente.
  int _maskOf(List<int> pieceIds) {
    var m = 0;
    for (final id in pieceIds) {
      m |= 1 << (id - 1);
    }
    return m;
  }

  /// Solutions complètes compatibles avec le plateau courant (pour le navigateur
  /// de solutions). Le plateau reconstruit inclut la pièce sélectionnée (elle n'a
  /// jamais quitté placedPieces sous stay + mask), donc pas d'`exclude:`. Vide pour
  /// les tailles à la volée.
  List<BigInt> compatibleSolutions() =>
      _solutions.compatibleSolutions(_rebuildPlateau());

  // ==========================================================================
  // ⏱️ TIMER
  // ==========================================================================




  // ==========================================================================
  // 📊 NOTE / SCORE
  // ==========================================================================

  /// Calcule la note de "non-triche" (0-20)
  /// - 0 hints → 20/20
  /// - ≥ nbPieces - 1 hints → 0/20
  /// - Entre les deux → linéaire
  int calculateNote() {
    final nbPieces = state.puzzle?.size.numPieces ?? 1;
    final nbHints = state.hintCount;
    
    // Si 0 hint → 20/20
    if (nbHints == 0) return 20;
    
    // Si ≥ nbPieces - 1 hints → 0/20
    final maxHints = nbPieces - 1;
    if (nbHints >= maxHints) return 0;
    
    // Linéaire entre les deux
    // note = 20 - (nbHints * 20 / maxHints)
    final note = 20 - (nbHints * 20 ~/ maxHints);
    return note.clamp(0, 20);
  }

  // ==========================================================================
  // 💡 HINT SYSTEM - Vérifier et appliquer un indice
  // ==========================================================================

  /// Applique un indice en plaçant une pièce du slider selon une solution possible
  void applyHint() {
    if (state.puzzle == null) return;
    if (state.availablePieces.isEmpty) return;
    if (!state.hasPossibleSolution) return;

    // Source du puzzle : table pré-calculée (solution compatible aléatoire,
    // décision §4.6) ou solveur à la volée. hintFrom renvoie les placements d'une
    // solution ; on y choisit une pièce non encore posée.
    final board = _rebuildPlateau();
    final solution = _solutions.hintFrom(board, state.availablePieces);
    if (solution == null || solution.isEmpty) {
      debugPrint('❌ HINT: Aucune solution trouvée');
      return;
    }

    final placedIds = state.placedPieces.map((p) => p.piece.id).toSet();
    PlacedPiece? hint;
    for (final pp in solution) {
      if (!placedIds.contains(pp.piece.id)) {
        hint = pp;
        break;
      }
    }
    if (hint == null) {
      debugPrint('❌ HINT: Aucune pièce nouvelle dans la solution proposée');
      return;
    }
    final hintPiece = hint.piece;

    debugPrint('💡 HINT: Placer pièce ${hintPiece.id} à (${hint.gridX}, ${hint.gridY}) pos=${hint.positionIndex}');

    // Créer le nouveau plateau et y poser la pièce indiquée
    final newPlateau = _rebuildPlateau();
    final newPlaced = hint;

    for (final cell in newPlaced.absoluteCells) {
      newPlateau.setCell(cell.x, cell.y, hintPiece.id);
    }

    // Mettre à jour les listes
    final newPlacedPieces = [...state.placedPieces, newPlaced];
    final newAvailable = state.availablePieces
        .where((p) => p.id != hintPiece.id)
        .toList();

    final isComplete = newPlacedPieces.length == state.puzzle!.size.numPieces;

    // ⏱️ Arrêter le timer si puzzle complet
    if (isComplete) {
      stopTimer();
    }

    // Vérifier s'il reste des solutions possibles + le compte
    final (hasPossibleSolution, solutionsCount) =
        _solutionStatus(newPlacedPieces, newAvailable);

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlacedPieces,
      isComplete: isComplete,
      hasPossibleSolution: hasPossibleSolution,
      solutionsCount: solutionsCount,
      hintCount: state.hintCount + 1, // 💡 Incrémenter le compteur de hints
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearPreview: true,
      validPlacements: [],
    );

    // 💾 Un indice peut compléter le puzzle : même traitement que pour un placement.
    if (isComplete) {
      _saveCompletionRecord();
      if (!_isMultiplayer) _clearCurrentGame();
    } else {
      _saveCurrentGame();
    }
  }

  /// `(hasPossibleSolution, solutionsCount)` pour un plateau donné par ses pièces.
  ///
  /// Temps 2 : un seul rebuild + un seul passage par la source du puzzle courant.
  /// La table sait compter (count non-null, `has` = count > 0) — le compteur peut
  /// donc passer au rouge, contrairement au court-circuit du temps 1 ; le solveur
  /// à la volée ne compte pas (count null, `has` via canSolveFrom).
  (bool, int?) _solutionStatus(
    List<PlacedPiece> placedPieces,
    List<Pento> availablePieces,
  ) {
    if (state.puzzle == null) return (false, null);
    final board = _rebuildPlateau(pieces: placedPieces);
    final count = _solutions.countFrom(board);
    final bool has;
    if (availablePieces.isEmpty) {
      has = false;
    } else if (count != null) {
      has = count > 0;
    } else {
      has = _solutions.hasSolutionFrom(board, availablePieces);
    }
    return (has, count);
  }

  // ==========================================================================
  // ✨ NOUVELLE FONCTION: Générer tous les placements valides
  // ==========================================================================

  // ==========================================================================
  // CORRECTION 1: cancelSelection - reconstruire le plateau
  // ==========================================================================

  void cancelSelection() {
    // Si on avait une pièce placée sélectionnée, il faut la remettre sur le plateau
    if (state.selectedPlacedPiece != null) {
      state = state.copyWith(
        plateau: _rebuildPlateau(),
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        clearSelectedMasterAbs: true,
        clearPreview: true,
        validPlacements: [], // ✨ NOUVEAU
      );
    } else {
      state = state.copyWith(
        clearSelectedPiece: true,
        clearSelectedPlacedPiece: true,
        clearSelectedCellInPiece: true,
        clearSelectedMasterAbs: true,
        clearPreview: true,
        validPlacements: [], // ✨ NOUVEAU
      );
    }
  }

  // ==========================================================================
  // ✨ NOUVELLE FONCTION: Trouver la position la plus proche
  // ==========================================================================



  void cycleToNextOrientation() {
    if (state.selectedPiece == null) return;

    final piece = state.selectedPiece!;
    final newIndex = (state.selectedPositionIndex + 1) % piece.numOrientations;
    final newCell = _calculateDefaultCell(piece, newIndex);

    final newIndices = Map<int, int>.from(state.piecePositionIndices);
    newIndices[piece.id] = newIndex;

    // ✨ NOUVEAU: Régénérer les placements valides après rotation
    final newValidPlacements = _generateValidPlacements(piece, newIndex);

    state = state.copyWith(
      selectedPositionIndex: newIndex,
      piecePositionIndices: newIndices,
      selectedCellInPiece: newCell,
      validPlacements: newValidPlacements, // ✨ Mettre à jour
    );
  }

  PlacedPiece? getPlacedPieceAt(int x, int y) {
    for (final placed in state.placedPieces) {
      for (final cell in placed.absoluteCells) {
        if (cell.x == x && cell.y == y) {
          return placed;
        }
      }
    }
    return null;
  }

  void removePlacedPiece(PlacedPiece placed) {
    final newPlateau = _rebuildPlateau(exclude: placed);

    final newPlaced = state.placedPieces
        .where((p) => p.piece.id != placed.piece.id)
        .toList();
    final newAvailable = [...state.availablePieces, placed.piece];

    // 💡 HINT: Recalculer si une solution est encore possible + le compte
    final (hasPossibleSolution, solutionsCount) =
        _solutionStatus(newPlaced, newAvailable);

    state = state.copyWith(
      plateau: newPlateau,
      placedPieces: newPlaced,
      availablePieces: newAvailable,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      clearSelectedMasterAbs: true,
      isComplete: false,
      solutionsCount: solutionsCount,
      validPlacements: [],
      hasPossibleSolution: hasPossibleSolution,
      deleteCount: state.deleteCount + 1, // 🗑️ Incrémenter le compteur de suppressions
    );

    // 🗄️ Persister l'avancement (no-op en multijoueur).
    _saveCurrentGame();
  }

  // ==========================================================================
  // RESET - génère un nouveau puzzle
  // ==========================================================================

  Future<void> reset() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;

    _isMultiplayer = false;
    // Générer un nouveau puzzle avec la même taille
    final newPuzzle = await _generator.generate(puzzle.size);
    _solutions = await _makeSolutionSource(newPuzzle.size, newPuzzle.pieceIds);

    final pieces = newPuzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final plateau = Plateau.allVisible(puzzle.size.width, puzzle.size.height);

    // Solution « à afficher » : une solution complète du tirage, servie par la SolutionSource
    // (corpus/table) sur le plateau vide. Plus de solveur.
    final firstSolution =
        state.showSolution ? _solutions.hintFrom(plateau, pieces) : null;

    // ⏱️ Reset sans démarrer le timer — efface l'origine, la partie suivante repart de zéro
    resetTimer();

    state = PentoscopeState(
      viewOrientation: state.viewOrientation,
      puzzle: newPuzzle,
      plateau: plateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: {},
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
      showSolution: state.showSolution,
      // ✅ Récupérer de state
      currentSolution: firstSolution,
      // ✅ Stocker la solution
      validPlacements: [], // ✨ NOUVEAU
      hasPossibleSolution: true, // 💡 Reset
      solutionsCount: _solutions.countFrom(plateau), // 🔢 compte initial (plateau vide)
      elapsedSeconds: 0, // ⏱️ Reset timer
    );

    // 🗄️ Recommencer efface la partie en cours précédente (§2.3).
    _clearCurrentGame();
  }

  // ==========================================================================
  // SÉLECTION PIÈCE (SLIDER)
  // ==========================================================================
  void selectPiece(Pento piece) {
    // ✨ BUGFIX: Si la pièce est déjà sélectionnée, utiliser selectedPositionIndex
    // (qui a été mis à jour par l'isométrie)
    // Sinon, récupérer l'index depuis piecePositionIndices
    final positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    final defaultCell = _calculateDefaultCell(piece, positionIndex);
    _cancelSelectedPlacedPieceIfAny();

    // ✨ BUGFIX: Mettre à jour le plateau EN PREMIER
    state = state.copyWith(
      plateau: _rebuildPlateau(),
      selectedPiece: piece,
      selectedPositionIndex: positionIndex,
      clearSelectedPlacedPiece: true,
      selectedCellInPiece: defaultCell,
      clearSelectedMasterAbs: true,
    );

    // ✨ PUIS générer les placements valides avec le NOUVEAU plateau
    final newValidPlacements = _generateValidPlacements(piece, positionIndex);

    state = state.copyWith(validPlacements: newValidPlacements);
  }

  // ==========================================================================
  // SÉLECTION PIÈCE PLACÉE (avec mastercase)
  // ==========================================================================

  void selectPlacedPiece(
    PlacedPiece placed,
    int absoluteX,
    int absoluteY,
  ) {
    if (state.isComplete) return; // ← Bloquer si puzzle complet

    // Calculer la cellule locale cliquée (mastercase) en coordonnées brutes
    final rawLocalX = absoluteX - placed.gridX;
    final rawLocalY = absoluteY - placed.gridY;

    // Convertir en coordonnées normalisées (comme dans _remapSelectedCell)
    final position = placed.piece.orientations[placed.positionIndex];
    final coords = position.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return Point(x, y);
    }).toList();

    final minX = coords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minY = coords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final normalizedCoords = coords.map((p) => Point(p.x - minX, p.y - minY)).toList();

    // Trouver quelle cellule normalisée correspond à la position cliquée
    Point? normalizedMastercase;
    for (int i = 0; i < coords.length; i++) {
      if (coords[i].x == rawLocalX && coords[i].y == rawLocalY) {
        normalizedMastercase = normalizedCoords[i];
        break;
      }
    }

    // Si on n'a pas trouvé, utiliser les coordonnées brutes (fallback)
    final mastercase = normalizedMastercase ?? Point(rawLocalX, rawLocalY);

    // ✨ BUGFIX: Mettre à jour le plateau dans l'état EN PREMIER
    // Sinon _generateValidPlacements() utilise l'ancien plateau!
    state = state.copyWith(
      plateau: _rebuildPlateau(exclude: placed),
      selectedPiece: placed.piece,
      selectedPlacedPiece: placed,
      selectedPositionIndex: placed.positionIndex,
      selectedCellInPiece: mastercase,
      selectedMasterAbs: Point(absoluteX, absoluteY),
      clearPreview: true,
    );

    // ✨ PUIS générer les placements valides avec le NOUVEAU plateau
    var validPlacements = _generateValidPlacements(
      placed.piece,
      placed.positionIndex,
    );

    // 🔑 EXCLURE la position actuelle pour faciliter les translations
    // Sinon le snapping ramène toujours à la position d'origine
    validPlacements = validPlacements
        .where((p) => p.x != placed.gridX || p.y != placed.gridY)
        .toList();

    state = state.copyWith(validPlacements: validPlacements);
  }

  /// Correctif 2 (PLAN_DEPLACEMENT_PIECE §4) — ancre le glissé sur la case réellement
  /// saisie sous le doigt, et non sur la case tapée à la sélection.
  ///
  /// Sans lui, `onDragStarted` ne fait que `setDragging(true)` : la mastercase reste
  /// celle du dernier `selectPlacedPiece`. Si l'on tape la case A puis que l'on saisit la
  /// case B, `_calculateDesiredAnchorFromDrag` translate de `doigt − masterAbs = doigt − A`,
  /// donc la pièce saute de `(B − A)` dès le début du glissé (mécanisme (b) du plan).
  ///
  /// À appeler depuis `onDragStarted` du plateau avec la case **absolue** saisie.
  void setDragMastercase(int absoluteX, int absoluteY) {
    final sp = state.selectedPlacedPiece;
    if (sp == null) return; // glissé depuis le tiroir : aucune case de plateau saisie
    // gridX/gridY est l'ancre normalisée (absoluteCells = gridX + localNorm), donc
    // (absolu − ancre) est directement la coordonnée locale normalisée de la case saisie.
    state = state.copyWith(
      selectedCellInPiece: Point(absoluteX - sp.gridX, absoluteY - sp.gridY),
      selectedMasterAbs: Point(absoluteX, absoluteY),
    );
  }

  /// À appeler depuis l'UI (board) quand l'orientation change.
  /// Ne change aucune coordonnée: uniquement l'interprétation des actions
  /// (ex: Sym H/V) en mode paysage.
  void setViewOrientation(bool isLandscape) {
    final next = isLandscape
        ? ViewOrientation.landscape
        : ViewOrientation.portrait;
    if (state.viewOrientation == next) return;
    state = state.copyWith(viewOrientation: next);
  }

  // ==========================================================================
  // DÉMARRAGE
  // ==========================================================================

  /// Tire au hasard un masque soluble (dialogue de nouvelle partie, hors 6×10).
  Future<int> drawMask(PentoscopeSize size) => _generator.drawMask(size);

  /// Nombre de solutions d'un masque tiré (la table est chargée par drawMask).
  int countOfMask(int mask) => _generator.countOfMask(mask);

  /// Démarre une partie. Si [mask] est fourni (tirage fait au dialogue), la partie l'utilise
  /// tel quel ; sinon un tirage est fait en interne (main.dart au lancement, ou le 6×10).
  Future<void> startPuzzle(
    PentoscopeSize size, {
    int? mask,
    bool showSolution = false,
  }) async {
    _isMultiplayer = false;
    final puzzle = mask != null
        ? _generator.puzzleFromMask(size, mask)
        : await _generator.generate(size);
    _solutions = await _makeSolutionSource(size, puzzle.pieceIds);

    final pieces = puzzle.pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final plateau = Plateau.allVisible(size.width, size.height);

    // 🎯 INITIALISER ALÉATOIREMENT LES POSITIONS
    final Random random = Random();
    final piecePositionIndices = <int, int>{};

    for (final piece in pieces) {
      final randomPos = random.nextInt(piece.numOrientations);
      piecePositionIndices[piece.id] = randomPos;
    }

    // Solution à afficher si l'option « montrer la solution » est active : servie par la
    // SolutionSource (corpus/table) sur le plateau vide. Plus de solveur.
    final firstSolution =
        showSolution ? _solutions.hintFrom(plateau, pieces) : null;

    // ⏱️ Reset timer sans démarrer — efface l'origine, la partie repart de zéro
    resetTimer();

    state = PentoscopeState(
      viewOrientation: ViewOrientation.portrait,
      puzzle: puzzle,
      plateau: plateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: piecePositionIndices,
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
      showSolution: showSolution,
      currentSolution: firstSolution,
      validPlacements: [],
      hasPossibleSolution: true,
      solutionsCount: _solutions.countFrom(plateau), // 🔢 compte initial (plateau vide)
      elapsedSeconds: 0,
    );

    // 🗄️ Nouvelle partie solo : efface la partie en cours précédente (§2.3).
    _clearCurrentGame();
  }

  /// 🎮 Démarre un puzzle avec un seed et des pièces spécifiques (mode multiplayer)
  Future<void> startPuzzleFromSeed(
    PentoscopeSize size,
    int seed,
    List<int> pieceIds,
  ) async {
    // Partie multijoueur : la persistance solo (CurrentGame, records) est désactivée.
    _isMultiplayer = true;
    // Générer le puzzle avec les paramètres fournis
    final puzzle = await _generator.generateFromSeed(size, seed, pieceIds);
    _solutions = await _makeSolutionSource(size, pieceIds);

    final pieces = pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .toList();

    final plateau = Plateau.allVisible(size.width, size.height);

    // Initialiser les positions avec le même seed (pour cohérence)
    final Random random = Random(seed);
    final piecePositionIndices = <int, int>{};

    for (final piece in pieces) {
      final randomPos = random.nextInt(piece.numOrientations);
      piecePositionIndices[piece.id] = randomPos;
    }

    // Reset timer sans démarrer — efface l'origine, la partie repart de zéro
    resetTimer();

    state = PentoscopeState(
      viewOrientation: ViewOrientation.portrait,
      puzzle: puzzle,
      plateau: plateau,
      availablePieces: pieces,
      placedPieces: [],
      piecePositionIndices: piecePositionIndices,
      isComplete: false,
      isometryCount: 0,
      translationCount: 0,
      showSolution: false,
      currentSolution: null,
      validPlacements: [],
      hasPossibleSolution: true,
      solutionsCount: _solutions.countFrom(plateau), // 🔢 compte initial (plateau vide)
      elapsedSeconds: 0,
    );
  }

  /// 💾 Enregistre le record d'un puzzle terminé (appelé à la complétion, état déjà à jour).
  ///
  /// La frontière entre les deux tables passe par `solutionIndexOf` (PLAN_PERSISTANCE §4.3) :
  /// un rectangle complet adossé à une table nomme sa solution → `SolvedSolutions` ; toute
  /// autre taille n'a pas de numéro → `PuzzleStats`. Aucun test de taille ici.
  Future<void> _saveCompletionRecord() async {
    final puzzle = state.puzzle;
    if (puzzle == null || _isMultiplayer) return;

    final board = _rebuildPlateau();
    final solutionNumber = _solutions.solutionIndexOf(board);
    final seconds = getElapsedSeconds();
    final actions =
        state.isometryCount + state.translationCount + state.deleteCount;
    final db = ref.read(settingsDatabaseProvider);

    try {
      if (solutionNumber != null) {
        await db.recordSolvedSolution(
          board: '${puzzle.size.width}x${puzzle.size.height}',
          solutionNumber: solutionNumber,
          timeSeconds: seconds,
          actions: actions,
        );
      } else {
        await db.recordPuzzleCompleted(
          sizeName: puzzle.size.name,
          timeSeconds: seconds,
        );
      }
    } catch (e) {
      debugPrint('❌ Enregistrement du record échoué: $e');
    }
  }

  // ==========================================================================
  // PARTIE EN COURS - persistance (PLAN_PERSISTANCE §2)
  // ==========================================================================

  /// Écrit la partie en cours dans `CurrentGame`. Appelé après chaque changement de
  /// `placedPieces` et au passage en arrière-plan. Ne stocke ni le plateau (reconstruit)
  /// ni les solutions. No-op si aucune partie, ou si elle est déjà complète (la ligne
  /// est alors effacée, pas réécrite).
  Future<void> _saveCurrentGame() async {
    final puzzle = state.puzzle;
    if (puzzle == null || state.isComplete || _isMultiplayer) return;

    final placedJson = jsonEncode([
      for (final p in state.placedPieces)
        {'id': p.piece.id, 'pos': p.positionIndex, 'x': p.gridX, 'y': p.gridY},
    ]);
    final indicesJson = jsonEncode(
      state.piecePositionIndices.map((k, v) => MapEntry(k.toString(), v)),
    );

    try {
      await ref.read(settingsDatabaseProvider).saveCurrentGame(
            sizeName: puzzle.size.name,
            pieceIds: puzzle.pieceIds.join(','),
            solutionCount: puzzle.solutionCount,
            placedPieces: placedJson,
            positionIndices: indicesJson,
            elapsedSeconds: getElapsedSeconds(),
            isometryCount: state.isometryCount,
            translationCount: state.translationCount,
            deleteCount: state.deleteCount,
            hintCount: state.hintCount,
          );
    } catch (e) {
      debugPrint('❌ Sauvegarde partie en cours échouée: $e');
    }
  }

  /// Efface la partie en cours (complétion, ou démarrage d'une partie neuve).
  Future<void> _clearCurrentGame() async {
    try {
      await ref.read(settingsDatabaseProvider).clearCurrentGame();
    } catch (e) {
      debugPrint('❌ Effacement partie en cours échoué: $e');
    }
  }

  /// Fige la partie en cours — appelé par `main.dart` au passage en arrière-plan,
  /// pour capturer `elapsedSeconds` avant que l'app soit suspendue.
  Future<void> saveCurrentGameSnapshot() => _saveCurrentGame();

  /// Reprend une partie sauvegardée **sans** passer par le générateur : reconstruit le
  /// `PentoscopePuzzle` depuis les champs stockés, rejoue les placements, restaure les
  /// compteurs et l'origine du chrono. `showSolution` n'est pas restaurable (§2.4).
  Future<void> restoreGame(CurrentGameData row) async {
    _isMultiplayer = false;
    final size = PentoscopeSize.values.firstWhere((s) => s.name == row.sizeName);
    final pieceIds = row.pieceIds.split(',').map(int.parse).toList();
    final puzzle = PentoscopePuzzle(
      size: size,
      pieceIds: pieceIds,
      solutionCount: row.solutionCount,
    );
    _solutions = await _makeSolutionSource(size, pieceIds);

    final piecePositionIndices =
        (jsonDecode(row.positionIndices) as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as int));

    final placedPieces = [
      for (final e in jsonDecode(row.placedPieces) as List)
        PlacedPiece(
          piece: pentominos[(e['id'] as int) - 1],
          positionIndex: e['pos'] as int,
          gridX: e['x'] as int,
          gridY: e['y'] as int,
        ),
    ];

    final placedIds = placedPieces.map((p) => p.piece.id).toSet();
    final availablePieces = pieceIds
        .map((id) => pentominos.firstWhere((p) => p.id == id))
        .where((p) => !placedIds.contains(p.id))
        .toList();

    // Reconstruire le plateau depuis les placements.
    final plateau = Plateau.allVisible(size.width, size.height);
    for (final pp in placedPieces) {
      for (final cell in pp.absoluteCells) {
        plateau.setCell(cell.x, cell.y, pp.piece.id);
      }
    }

    // État des solutions (même logique que _solutionStatus, mais l'état n'est pas encore posé).
    final count = _solutions.countFrom(plateau);
    final bool hasPossibleSolution;
    if (availablePieces.isEmpty) {
      hasPossibleSolution = false;
    } else if (count != null) {
      hasPossibleSolution = count > 0;
    } else {
      hasPossibleSolution = _solutions.hasSolutionFrom(plateau, availablePieces);
    }

    // ⏱️ Reprendre le chrono à la valeur restaurée, sans démarrer le tic.
    restoreTimerOrigin(row.elapsedSeconds);

    state = PentoscopeState(
      viewOrientation: ViewOrientation.portrait,
      puzzle: puzzle,
      plateau: plateau,
      availablePieces: availablePieces,
      placedPieces: placedPieces,
      piecePositionIndices: piecePositionIndices,
      isComplete: false,
      isometryCount: row.isometryCount,
      translationCount: row.translationCount,
      deleteCount: row.deleteCount,
      hintCount: row.hintCount,
      showSolution: false, // non restaurable (§2.4)
      currentSolution: null,
      validPlacements: [],
      hasPossibleSolution: hasPossibleSolution,
      solutionsCount: count,
      elapsedSeconds: row.elapsedSeconds,
    );
  }

  // ==========================================================================
  // PLACEMENT
  // ==========================================================================

  /// Méthode publique pour obtenir les coordonnées brutes de la mastercase
  /// Utile pour le widget board qui doit reconstruire les coordonnées de drag
  /// 
  /// Note: Cette méthode publique est différente de celle du mixin (qui prend des paramètres)
  Point? getRawMastercaseCoordsPublic() {
    if (state.selectedPiece == null || state.selectedCellInPiece == null) {
      return null;
    }
    return super.getRawMastercaseCoords(
      state.selectedPiece!,
      state.selectedPositionIndex,
      state.selectedCellInPiece!,
    );
  }

  /// Variante « position du doigt » : convertit en ancre puis délègue à
  /// [tryPlaceAtAnchor]. Conservée comme point d'entrée coordonnées-doigt.
  bool tryPlacePiece(int gridX, int gridY) {
    if (state.selectedPiece == null) return false;
    final anchor = _calculateDesiredAnchorFromDrag(gridX, gridY);
    return tryPlaceAtAnchor(anchor.x, anchor.y);
  }

  /// Correctif 3 (PLAN_DEPLACEMENT_PIECE §4) — place la pièce sélectionnée **directement à
  /// l'ancre** (coordonnées normalisées), sans repasser par une position de doigt.
  ///
  /// Le dépôt appelle cette méthode avec `previewX/previewY`, l'ancre déjà snappée et déjà
  /// validée par `updatePreview`. On supprime ainsi la reconstruction d'un faux doigt
  /// (`preview + selectedCellInPiece`) puis sa re-dérivation en ancre — deux conventions de
  /// référence qui ne coïncidaient qu'à condition d'une resynchro parfaite (défaut 3.3).
  bool tryPlaceAtAnchor(int anchorX, int anchorY) {
    if (state.selectedPiece == null) return false;

    final piece = state.selectedPiece!;
    final positionIndex = state.selectedPositionIndex;
    final wasPlacedPiece = state.selectedPlacedPiece != null;

    if (!state.canPlacePiece(piece, positionIndex, anchorX, anchorY)) {
      return false;
    }

    // Créer le nouveau plateau (sans la pièce en cours de déplacement si applicable)
    final newPlateau = _rebuildPlateau(exclude: state.selectedPlacedPiece);

    // Placer la nouvelle pièce
    final newPlaced = PlacedPiece(
      piece: piece,
      positionIndex: positionIndex,
      gridX: anchorX,
      gridY: anchorY,
    );

    for (final cell in newPlaced.absoluteCells) {
      newPlateau.setCell(cell.x, cell.y, piece.id);
    }

    // Mettre à jour les listes
    List<PlacedPiece> newPlacedPieces;
    List<Pento> newAvailable;

    if (state.selectedPlacedPiece != null) {
      // Déplacement d'une pièce existante
      newPlacedPieces = state.placedPieces
          .map((p) => p.piece.id == piece.id ? newPlaced : p)
          .toList();
      newAvailable = state.availablePieces;
    } else {
      // Nouvelle pièce
      newPlacedPieces = [...state.placedPieces, newPlaced];
      newAvailable = state.availablePieces
          .where((p) => p.id != piece.id)
          .toList();
    }

    final isComplete =
        newPlacedPieces.length == (state.puzzle?.size.numPieces ?? 0);

    // Compter les translations (déplacement d'une pièce déjà placée)
    final newTranslationCount = state.selectedPlacedPiece != null
        ? state.translationCount + 1
        : state.translationCount;

    // ⏱️ Arrêter le timer si puzzle complet
    if (isComplete) {
      stopTimer();
    }

    // 💡 HINT: Vérifier si une solution est encore possible + le compte
    final (hasPossibleSolution, solutionsCount) =
        _solutionStatus(newPlacedPieces, newAvailable);

    state = state.copyWith(
      plateau: newPlateau,
      availablePieces: newAvailable,
      placedPieces: newPlacedPieces,
      clearSelectedPiece: true,
      clearSelectedPlacedPiece: true,
      clearSelectedCellInPiece: true,
      clearSelectedMasterAbs: true,
      clearPreview: true,
      isComplete: isComplete,
      translationCount: newTranslationCount,
      currentSolution: state.currentSolution,
      validPlacements: [],
      hasPossibleSolution: hasPossibleSolution, // 💡 HINT
      solutionsCount: solutionsCount, // 🔢
    );

    // 💾 À la complétion : enregistrer le record et effacer la partie en cours. Sinon,
    //    persister l'avancement (no-op en multijoueur, où _isMultiplayer est vrai).
    if (isComplete) {
      _saveCompletionRecord();
      if (!_isMultiplayer) _clearCurrentGame();
    } else {
      _saveCurrentGame();
    }

    // ⏱️ Démarrer le timer au premier placement depuis le slider — mais jamais sur une
    // partie qui vient d'être complétée (le stopTimer ci-dessus a mis isTimerRunning à false).
    if (!isComplete && !isTimerRunning && !wasPlacedPiece) {
      startTimer();
    }

    return true;
  }

  // ==========================================================================
  // PREVIEW
  // ==========================================================================

  void updatePreview(int gridX, int gridY) {
    if (state.selectedPiece == null) {
      if (state.previewX != null || state.previewY != null) {
        state = state.copyWith(clearPreview: true);
      }
      return;
    }

    // ✨ CAS 1 - AUCUN PLACEMENT POSSIBLE → ROUGE PARTOUT
    if (state.validPlacements.isEmpty) {
      // Calculer l'ancre en appliquant le vecteur de translation
      final desiredAnchor = _calculateDesiredAnchorFromDrag(gridX, gridY);
      state = state.copyWith(
        previewX: desiredAnchor.x,
        previewY: desiredAnchor.y,
        isPreviewValid: false, // 🔴 ROUGE
      );
      return;
    }

    // ✨ CAS 2 - PLACEMENTS POSSIBLES → SNAPPING VERT
    final snappedPlacement = _findClosestValidPlacement(gridX, gridY);

    if (snappedPlacement == null) {
      // Correctif 4 (§4) : ici validPlacements n'est pas vide (CAS 1 l'a écarté), donc null
      // signifie « aucun placement valide sous le plafond d'aimantation ». Aperçu ROUGE à
      // l'ancre désirée, plutôt que téléportation vers le placement valide le plus lointain.
      final desiredAnchor = _calculateDesiredAnchorFromDrag(gridX, gridY);
      state = state.copyWith(
        previewX: desiredAnchor.x,
        previewY: desiredAnchor.y,
        isPreviewValid: false, // 🔴 ROUGE — placement refusé au dépôt
      );
      return;
    }

    // 🔑 Le snappedPlacement est déjà une position d'ancre valide
    // Pas besoin d'appliquer la mastercase, c'est déjà dedans
    state = state.copyWith(
      previewX: snappedPlacement.x,
      previewY: snappedPlacement.y,
      isPreviewValid: true, // 🟢 VERT
    );
  }

  // ============================================================================
  // VALIDATION ISOMÉTRIES - NOUVELLE MÉTHODE
  // ============================================================================

  TransformationResult _applyIsoUsingLookup(int Function(Pento p, int idx) f) {
    final piece = state.selectedPiece;
    if (piece == null) return TransformationResult.success;

    final oldIdx = state.selectedPositionIndex;
    final newIdx = f(piece, oldIdx);
    final didChange = oldIdx != newIdx;

    if (!didChange) return TransformationResult.success;

    // ========================================================================
    // CAS 1: Pièce du SLIDER sélectionnée (pas de validation nécessaire)
    // ========================================================================
    final sp = state.selectedPlacedPiece;
    if (sp == null) {
      state = state.copyWith(
        selectedPositionIndex: newIdx,
        selectedCellInPiece: _remapSelectedCell(
          piece: piece,
          oldIndex: oldIdx,
          newIndex: newIdx,
          oldCell: state.selectedCellInPiece,
        ),
        clearPreview: true,
        isometryCount: state.isometryCount + 1,
      );

      // ✨ BUGFIX: Régénérer validPlacements avec le NOUVEAU positionIndex
      final newValidPlacements = _generateValidPlacements(piece, newIdx);
      state = state.copyWith(validPlacements: newValidPlacements);
      return TransformationResult.success;
    }

    // ========================================================================
    // CAS 2: Pièce PLACÉE sur plateau (VALIDATION REQUISE!)
    // ========================================================================

    final transformedPiece = sp.copyWith(positionIndex: newIdx);

    // 🎯 LOGIQUE MASTERCACE FIXE
    late int adjustedGridX;
    late int adjustedGridY;
    bool neededRecentering = false;

    if (state.selectedCellInPiece != null) {
      // === LOG AVANT TRANSFO ===
      final originalPosition = sp.piece.orientations[oldIdx];
      final originalRawCoords = originalPosition.map((cellNum) {
        final x = (cellNum - 1) % 5;
        final y = (cellNum - 1) ~/ 5;
        return Point(x, y);
      }).toList();
      final minXOrig = originalRawCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final minYOrig = originalRawCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final normalizedOrigCoords = originalRawCoords
          .map((p) => Point(p.x - minXOrig, p.y - minYOrig))
          .toList();
      final masterIdxOrig = normalizedOrigCoords.indexWhere(
        (p) => p.x == state.selectedCellInPiece!.x && p.y == state.selectedCellInPiece!.y,
      );
      final masterRawOrig = masterIdxOrig == -1
          ? null
          : originalRawCoords[masterIdxOrig];
      final masterAbsOrig = masterRawOrig == null
          ? null
          : Point(sp.gridX + masterRawOrig.x, sp.gridY + masterRawOrig.y);
      debugPrint(
        '🧩 BEFORE: grid=(${sp.gridX},${sp.gridY}) '
        'masterNorm=(${state.selectedCellInPiece!.x},${state.selectedCellInPiece!.y}) '
        'masterRaw=${masterRawOrig == null ? "null" : "(${masterRawOrig.x},${masterRawOrig.y})"} '
        'masterAbs=${masterAbsOrig == null ? "null" : "(${masterAbsOrig.x},${masterAbsOrig.y})"}',
      );

      // Calculer la position pour maintenir la mastercase fixe
      final fixedPosition = _calculatePositionForFixedMastercase(
        originalPiece: sp,
        transformedPiece: transformedPiece,
        mastercase: state.selectedCellInPiece!,
      );

      adjustedGridX = fixedPosition.x;
      adjustedGridY = fixedPosition.y;

      debugPrint(
        '🎯 Mastercase fixe: (${sp.gridX},${sp.gridY}) → ($adjustedGridX,$adjustedGridY)',
      );
    } else {
      // Logique classique si pas de mastercase définie
      adjustedGridX = sp.gridX;
      adjustedGridY = sp.gridY;
    }

    // Créer une pièce temporaire pour tester la position initiale
    final initialPiece = transformedPiece.copyWith(
      gridX: adjustedGridX,
      gridY: adjustedGridY,
    );

    // Vérifier si la position initiale est valide
    if (!_canPlacePieceWithoutChecker(initialPiece)) {
      // Chercher une position valide proche
      if (state.selectedCellInPiece != null) {
        final mastercaseAbs = Point(
          sp.gridX + state.selectedCellInPiece!.x,
          sp.gridY + state.selectedCellInPiece!.y,
        );
        final nearestPosition = _findNearestValidPosition(
          piece: transformedPiece,
          mastercaseAbs: mastercaseAbs,
          mastercaseLocal: state.selectedCellInPiece!,
        );

        if (nearestPosition == null) {
          debugPrint('❌ Transformation impossible - aucune position valide trouvée');
          return TransformationResult.impossible;
        }

        adjustedGridX = nearestPosition.x;
        adjustedGridY = nearestPosition.y;
        neededRecentering = true;
      } else {
        debugPrint('❌ Transformation impossible - chevauchement et pas de mastercase');
        return TransformationResult.impossible;
      }
    }

    // 🔄 AJUSTEMENT AUTOMATIQUE si la pièce sort du plateau
    // Ajuster X si nécessaire
    while (adjustedGridX < 0 ||
        (adjustedGridX + _getMaxLocalX(transformedPiece) >= state.plateau.width)) {
      if (adjustedGridX > 0) {
        adjustedGridX--;
        neededRecentering = true;
      } else {
        // Ne peut pas aller plus à gauche, chercher une position valide
        if (state.selectedCellInPiece != null) {
          final mastercaseAbs = Point(
            sp.gridX + state.selectedCellInPiece!.x,
            sp.gridY + state.selectedCellInPiece!.y,
          );
          final nearestPosition = _findNearestValidPosition(
            piece: transformedPiece,
            mastercaseAbs: mastercaseAbs,
            mastercaseLocal: state.selectedCellInPiece!,
          );

          if (nearestPosition == null) {
            debugPrint('❌ Transformation impossible - pièce sortirait du plateau');
            return TransformationResult.impossible;
          }

          adjustedGridX = nearestPosition.x;
          adjustedGridY = nearestPosition.y;
          neededRecentering = true;
          break;
        } else {
          debugPrint('❌ Transformation impossible - pièce sortirait du plateau');
          return TransformationResult.impossible;
        }
      }
    }

    // Ajuster Y si nécessaire
    while (adjustedGridY < 0 ||
        (adjustedGridY + _getMaxLocalY(transformedPiece) >= state.plateau.height)) {
      if (adjustedGridY > 0) {
        adjustedGridY--;
        neededRecentering = true;
      } else {
        // Ne peut pas aller plus haut, chercher une position valide
        if (state.selectedCellInPiece != null) {
          final mastercaseAbs = Point(
            sp.gridX + state.selectedCellInPiece!.x,
            sp.gridY + state.selectedCellInPiece!.y,
          );
          final nearestPosition = _findNearestValidPosition(
            piece: transformedPiece,
            mastercaseAbs: mastercaseAbs,
            mastercaseLocal: state.selectedCellInPiece!,
          );

          if (nearestPosition == null) {
            debugPrint('❌ Transformation impossible - pièce sortirait du plateau');
            return TransformationResult.impossible;
          }

          adjustedGridX = nearestPosition.x;
          adjustedGridY = nearestPosition.y;
          neededRecentering = true;
          break;
        } else {
          debugPrint('❌ Transformation impossible - pièce sortirait du plateau');
          return TransformationResult.impossible;
        }
      }
    }

    final finalPiece = transformedPiece.copyWith(
      gridX: adjustedGridX,
      gridY: adjustedGridY,
    );

    // Vérifier une dernière fois que la position est valide
    if (!_canPlacePieceWithoutChecker(finalPiece)) {
      debugPrint('❌ Transformation impossible - position finale invalide');
      return TransformationResult.impossible;
    }

    // ✨ SAUVEGARDER la pièce avec la nouvelle position
    final updatedPlacedPieces = state.placedPieces.map((p) {
      if (p.piece.id == sp.piece.id) {
        return finalPiece;  // ← Utiliser finalPiece ajustée!
      }
      return p;
    }).toList();

    // 🔄 Reconstruire le plateau avec les pièces mises à jour
    final newPlateau = _rebuildPlateau(pieces: updatedPlacedPieces);

    // 💡 Recalculer si une solution est encore possible + le compte
    final (hasPossibleSolution, solutionsCount) =
        _solutionStatus(updatedPlacedPieces, state.availablePieces);

    // Calculer la nouvelle position relative de la mastercase dans la pièce transformée
    Point? newSelectedCellInPiece;
    if (state.selectedCellInPiece != null) {
      // Utiliser l'index STABLE (ordre géométrique) pour remapper la mastercase
      final originalPosition = sp.piece.orientations[oldIdx];
      final transformedPosition = piece.orientations[newIdx];

      final originalCoords = originalPosition.map((cellNum) {
        final x = (cellNum - 1) % 5;
        final y = (cellNum - 1) ~/ 5;
        return Point(x, y);
      }).toList();

      final minXOrig = originalCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final minYOrig = originalCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final normalizedOrigCoords = originalCoords
          .map((p) => Point(p.x - minXOrig, p.y - minYOrig))
          .toList();

      final mastercaseIndex = normalizedOrigCoords.indexWhere(
        (p) => p.x == state.selectedCellInPiece!.x && p.y == state.selectedCellInPiece!.y,
      );

      if (mastercaseIndex != -1) {
        final transformedCoords = transformedPosition.map((cellNum) {
          final x = (cellNum - 1) % 5;
          final y = (cellNum - 1) ~/ 5;
          return Point(x, y);
        }).toList();

        final minXTrans = transformedCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
        final minYTrans = transformedCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
        final normalizedTransCoords = transformedCoords
            .map((p) => Point(p.x - minXTrans, p.y - minYTrans))
            .toList();

        newSelectedCellInPiece = normalizedTransCoords[mastercaseIndex];
      }
    }

    final resolvedSelectedCell = newSelectedCellInPiece ?? _remapSelectedCell(
      piece: piece,
      oldIndex: oldIdx,
      newIndex: newIdx,
      oldCell: state.selectedCellInPiece,
    );

    state = state.copyWith(
      plateau: newPlateau,
      selectedPlacedPiece: finalPiece,  // ← Mettre à jour!
      placedPieces: updatedPlacedPieces,
      selectedPositionIndex: newIdx,
      selectedCellInPiece: resolvedSelectedCell,
      selectedMasterAbs: resolvedSelectedCell == null
          ? null
          : Point(
              finalPiece.gridX + resolvedSelectedCell.x,
              finalPiece.gridY + resolvedSelectedCell.y,
            ),
      clearPreview: true,
      isometryCount: state.isometryCount + 1,
      hasPossibleSolution: hasPossibleSolution, // 💡 Mise à jour!
      solutionsCount: solutionsCount, // 🔢
    );

    // === LOG APRES TRANSFO ===
    if (state.selectedCellInPiece != null) {
      final transformedPosition = piece.orientations[newIdx];
      final transformedRawCoords = transformedPosition.map((cellNum) {
        final x = (cellNum - 1) % 5;
        final y = (cellNum - 1) ~/ 5;
        return Point(x, y);
      }).toList();
      final minXTrans = transformedRawCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final minYTrans = transformedRawCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final normalizedTransCoords = transformedRawCoords
          .map((p) => Point(p.x - minXTrans, p.y - minYTrans))
          .toList();
      final masterIdxTrans = normalizedTransCoords.indexWhere(
        (p) => p.x == state.selectedCellInPiece!.x && p.y == state.selectedCellInPiece!.y,
      );
      final masterRawTrans = masterIdxTrans == -1
          ? null
          : transformedRawCoords[masterIdxTrans];
      final masterAbsTrans = masterRawTrans == null
          ? null
          : Point(finalPiece.gridX + masterRawTrans.x, finalPiece.gridY + masterRawTrans.y);
      debugPrint(
        '🧩 AFTER: grid=(${finalPiece.gridX},${finalPiece.gridY}) '
        'masterNorm=(${state.selectedCellInPiece!.x},${state.selectedCellInPiece!.y}) '
        'masterRaw=${masterRawTrans == null ? "null" : "(${masterRawTrans.x},${masterRawTrans.y})"} '
        'masterAbs=${masterAbsTrans == null ? "null" : "(${masterAbsTrans.x},${masterAbsTrans.y})"}',
      );
    }

    return neededRecentering ? TransformationResult.recentered : TransformationResult.success;
  }

  TransformationResult _applySymmetryAbs(SymmetryType type) {
    final piece = state.selectedPiece;
    final sp = state.selectedPlacedPiece;
    if (piece == null || sp == null) return TransformationResult.success;
    if (state.selectedCellInPiece == null) {
      return TransformationResult.success;
    }

    final oldIdx = state.selectedPositionIndex;

    final masterRaw = getRawMastercaseCoords(
      piece,
      oldIdx,
      state.selectedCellInPiece!,
    );
    final masterAbs = Point(
      sp.gridX + masterRaw.x,
      sp.gridY + masterRaw.y,
    );

    final cellsAbs = sp.absoluteCells.toList();
    debugPrint(
      '🧩 SYM BEFORE: '
      'piece=${piece.id} oldIdx=$oldIdx '
      'grid=(${sp.gridX},${sp.gridY}) '
      'masterAbs=(${masterAbs.x},${masterAbs.y}) '
      'type=$type',
    );
    final symAbs = applySymmetryAbs(
      cellsAbs: cellsAbs,
      masterAbs: masterAbs,
      type: type,
    );

    final normalized = normalizeCoords(symAbs);
    debugPrint('🧮 SYM ABS: $symAbs');
    debugPrint('🧮 SYM NORM: $normalized');
    final newIdx = findOrientationIndexFromNormalized(
      piece: piece,
      normalizedCoords: normalized,
    );

    if (newIdx == null) {
      debugPrint('❌ Symétrie impossible - orientation introuvable');
      return TransformationResult.impossible;
    }
    debugPrint('✅ SYM ORIENTATION: $oldIdx → $newIdx');

    final minX = symAbs.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minY = symAbs.map((p) => p.y).reduce((a, b) => a < b ? a : b);

    final transformedPiece = sp.copyWith(positionIndex: newIdx);

    int adjustedGridX = minX;
    int adjustedGridY = minY;
    debugPrint('🧮 SYM GRID INIT: ($adjustedGridX,$adjustedGridY)');
    bool neededRecentering = false;

    final initialPiece = transformedPiece.copyWith(
      gridX: adjustedGridX,
      gridY: adjustedGridY,
    );

    if (!_canPlacePieceWithoutChecker(initialPiece)) {
      final nearestPosition = _findNearestValidPosition(
        piece: transformedPiece,
        mastercaseAbs: masterAbs,
        mastercaseLocal: state.selectedCellInPiece!,
      );

      if (nearestPosition == null) {
        debugPrint('❌ Symétrie impossible - aucune position valide trouvée');
        return TransformationResult.impossible;
      }

      adjustedGridX = nearestPosition.x;
      adjustedGridY = nearestPosition.y;
      neededRecentering = true;
    }

    while (adjustedGridX < 0 ||
        (adjustedGridX + _getMaxLocalX(transformedPiece) >=
            state.plateau.width)) {
      if (adjustedGridX > 0) {
        adjustedGridX--;
        neededRecentering = true;
      } else {
        final nearestPosition = _findNearestValidPosition(
          piece: transformedPiece,
          mastercaseAbs: masterAbs,
          mastercaseLocal: state.selectedCellInPiece!,
        );

        if (nearestPosition == null) {
          debugPrint('❌ Symétrie impossible - pièce sortirait du plateau');
          return TransformationResult.impossible;
        }

        adjustedGridX = nearestPosition.x;
        adjustedGridY = nearestPosition.y;
        neededRecentering = true;
        break;
      }
    }

    while (adjustedGridY < 0 ||
        (adjustedGridY + _getMaxLocalY(transformedPiece) >=
            state.plateau.height)) {
      if (adjustedGridY > 0) {
        adjustedGridY--;
        neededRecentering = true;
      } else {
        final nearestPosition = _findNearestValidPosition(
          piece: transformedPiece,
          mastercaseAbs: masterAbs,
          mastercaseLocal: state.selectedCellInPiece!,
        );

        if (nearestPosition == null) {
          debugPrint('❌ Symétrie impossible - pièce sortirait du plateau');
          return TransformationResult.impossible;
        }

        adjustedGridX = nearestPosition.x;
        adjustedGridY = nearestPosition.y;
        neededRecentering = true;
        break;
      }
    }

    final finalPiece = transformedPiece.copyWith(
      gridX: adjustedGridX,
      gridY: adjustedGridY,
    );

    if (!_canPlacePieceWithoutChecker(finalPiece)) {
      debugPrint('❌ Symétrie impossible - position finale invalide');
      return TransformationResult.impossible;
    }

    final updatedPlacedPieces = state.placedPieces.map((p) {
      if (p.piece.id == sp.piece.id) {
        return finalPiece;
      }
      return p;
    }).toList();

    final newPlateau = _rebuildPlateau(pieces: updatedPlacedPieces);

    final (hasPossibleSolution, solutionsCount) =
        _solutionStatus(updatedPlacedPieces, state.availablePieces);

    Point? newSelectedCellInPiece;
    if (state.selectedCellInPiece != null) {
      final transformedPosition = piece.orientations[newIdx];
      final transformedCoords = transformedPosition.map((cellNum) {
        final x = (cellNum - 1) % 5;
        final y = (cellNum - 1) ~/ 5;
        return Point(x, y);
      }).toList();

      final minXTrans =
          transformedCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final minYTrans =
          transformedCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
      final normalizedTransCoords = transformedCoords
          .map((p) => Point(p.x - minXTrans, p.y - minYTrans))
          .toList();

      final expectedRaw = Point(
        masterAbs.x - finalPiece.gridX,
        masterAbs.y - finalPiece.gridY,
      );
      final masterIdx = transformedCoords.indexWhere(
        (p) => p.x == expectedRaw.x && p.y == expectedRaw.y,
      );

      if (masterIdx != -1) {
        newSelectedCellInPiece = normalizedTransCoords[masterIdx];
      } else {
        debugPrint(
          '⚠️ SYM mastercase raw not found in new orientation: '
          'expected=(${expectedRaw.x},${expectedRaw.y})',
        );
      }
    }

    final resolvedSelectedCell = newSelectedCellInPiece ?? _remapSelectedCell(
      piece: piece,
      oldIndex: oldIdx,
      newIndex: newIdx,
      oldCell: state.selectedCellInPiece,
    );

    state = state.copyWith(
      plateau: newPlateau,
      selectedPlacedPiece: finalPiece,
      placedPieces: updatedPlacedPieces,
      selectedPositionIndex: newIdx,
      selectedCellInPiece: resolvedSelectedCell,
      selectedMasterAbs: resolvedSelectedCell == null
          ? null
          : Point(
              finalPiece.gridX + resolvedSelectedCell.x,
              finalPiece.gridY + resolvedSelectedCell.y,
            ),
      clearPreview: true,
      isometryCount: state.isometryCount + 1,
      hasPossibleSolution: hasPossibleSolution,
      solutionsCount: solutionsCount, // 🔢
    );

    final finalMasterRaw = getRawMastercaseCoords(
      piece,
      newIdx,
      state.selectedCellInPiece!,
    );
    debugPrint(
      '🧩 SYM AFTER: '
      'grid=(${finalPiece.gridX},${finalPiece.gridY}) '
      'masterAbs=(${finalPiece.gridX + finalMasterRaw.x},${finalPiece.gridY + finalMasterRaw.y})',
    );

    return neededRecentering
        ? TransformationResult.recentered
        : TransformationResult.success;
  }

  /// Calcule la position gridX,gridY pour maintenir la mastercase fixe lors d'une transformation
  Point _calculatePositionForFixedMastercase({
    required PlacedPiece originalPiece,
    required PlacedPiece transformedPiece,
    required Point mastercase,
  }) {
    debugPrint(
      '🧮 CALC: origGrid=(${originalPiece.gridX},${originalPiece.gridY}) '
      'masterNorm=(${mastercase.x},${mastercase.y}) '
      'oldIdx=${originalPiece.positionIndex} newIdx=${transformedPiece.positionIndex}',
    );
    // 1. Trouver l'index STABLE (ordre géométrique) de la mastercase
    // On ne peut pas utiliser le cellNum (il change selon l'orientation).
    final originalPosition = originalPiece.piece.orientations[originalPiece.positionIndex];
    final originalCoords = originalPosition.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return Point(x, y);
    }).toList();

    final minXOrig = originalCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minYOrig = originalCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final normalizedOrigCoords = originalCoords.map((p) => Point(p.x - minXOrig, p.y - minYOrig)).toList();

    // Trouver l'index de la mastercase dans les coordonnées normalisées
    final mastercaseIndex = normalizedOrigCoords.indexWhere(
      (p) => p.x == mastercase.x && p.y == mastercase.y,
    );
    if (mastercaseIndex == -1) {
      debugPrint('Warning: Mastercase not found in original position, keeping original position');
      return Point(originalPiece.gridX, originalPiece.gridY);
    }

    // 2. Calculer les coordonnées normalisées dans la nouvelle orientation
    // et réutiliser le même index (ordre stable)
    final transformedPosition = transformedPiece.piece.orientations[transformedPiece.positionIndex];
    final transformedCoords = transformedPosition.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return Point(x, y);
    }).toList();

    // 4. Position absolue actuelle de la mastercase (coord brute d'origine)
    final originalMasterRaw = originalCoords[mastercaseIndex];
    final mastercaseAbsX = originalPiece.gridX + originalMasterRaw.x;
    final mastercaseAbsY = originalPiece.gridY + originalMasterRaw.y;

    // 5. Calculer gridX, gridY pour que la mastercase reste à la position absolue
    // La cellule brute de la mastercase en orientation transformée est celle au même index
    final newLocalX = transformedCoords[mastercaseIndex].x;
    final newLocalY = transformedCoords[mastercaseIndex].y;

    final newGridX = mastercaseAbsX - newLocalX;
    final newGridY = mastercaseAbsY - newLocalY;

    debugPrint(
      '🧮 CALC: masterIdx=$mastercaseIndex '
      'origRaw=(${originalMasterRaw.x},${originalMasterRaw.y}) '
      'newRaw=($newLocalX,$newLocalY) '
      'newGrid=($newGridX,$newGridY)',
    );

    return Point(newGridX, newGridY);
  }

  /// Helper: calcule la mastercase par défaut (première cellule normalisée)
  /// 
  /// ✅ Utilise maintenant la méthode du mixin
  Point? _calculateDefaultCell(Pento piece, int positionIndex) {
    return calculateDefaultCell(piece, positionIndex);
  }


  /// Annule le mode "pièce placée en main" (sélection sur plateau) en
  /// reconstruisant le plateau complet à partir des pièces placées.
  /// À appeler avant de sélectionner une pièce du slider.
  void _cancelSelectedPlacedPieceIfAny() {
    if (state.selectedPlacedPiece == null) return;

    state = state.copyWith(
      plateau: _rebuildPlateau(),
      clearSelectedPlacedPiece: true,
      clearSelectedMasterAbs: true,
      clearPreview: true,
    );
  }

  /// Calcule l'ancre voulue à partir du drag (doigt) en respectant
  /// l'origine de translation (mastercase sélectionnée).
  /// - Si pièce placée: vecteur = (doigt - masterAbs), ancre = originGrid + vecteur
  /// - Sinon: ancre = doigt - mastercase normalisée
  Point _calculateDesiredAnchorFromDrag(int dragGridX, int dragGridY) {
    final sp = state.selectedPlacedPiece;
    final masterAbs = state.selectedMasterAbs;

    if (sp != null && masterAbs != null) {
      final dx = dragGridX - masterAbs.x;
      final dy = dragGridY - masterAbs.y;
      return Point(sp.gridX + dx, sp.gridY + dy);
    }

    if (state.selectedCellInPiece != null) {
      return Point(
        dragGridX - state.selectedCellInPiece!.x,
        dragGridY - state.selectedCellInPiece!.y,
      );
    }

    return Point(dragGridX, dragGridY);
  }

  bool _canPlacePieceWithoutChecker(PlacedPiece placed) {
    debugPrint(
      '🔎 Vérification ${placed.piece.id} à gridX=${placed.gridX}, gridY=${placed.gridY}',
    );
    debugPrint('   Cells: ${placed.absoluteCells}');

    for (final cell in placed.absoluteCells) {
      // Vérifier les limites du plateau
      if (cell.x < 0 ||
          cell.x >= state.plateau.width ||
          cell.y < 0 ||
          cell.y >= state.plateau.height) {
        debugPrint(
          '   ❌ HORS LIMITES: ($cell.x, $cell.y) plateau=${state.plateau.width}×${state.plateau.height}',
        );
        return false;
      }

      // Vérifier chevauchement
      final cellValue = state.plateau.getCell(cell.x, cell.y);
      if (cellValue != 0 && cellValue != placed.piece.id) {
        debugPrint(
          '   ❌ CHEVAUCHEMENT: ($cell.x, $cell.y) occupée par $cellValue',
        );
        return false;
      }
    }

    debugPrint('   ✅ VALIDE');
    return true;
  }

  /// Cherche la position valide la plus proche autour de la mastercase
  /// Retourne null si aucune position valide n'est trouvée dans un rayon raisonnable
  Point? _findNearestValidPosition({
    required PlacedPiece piece,
    required Point mastercaseAbs,
    required Point mastercaseLocal,
    int maxRadius = 5,
  }) {
    // Retirer temporairement la pièce du plateau pour la vérification
    final tempPlateau = _rebuildPlateau(exclude: piece);

    // Trouver la cellule de la mastercase dans la pièce transformée
    final transformedPosition = piece.piece.orientations[piece.positionIndex];
    final rawCoords = transformedPosition.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return Point(x, y);
    }).toList();

    final minX = rawCoords.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final minY = rawCoords.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final normalizedCoords = rawCoords
        .map((p) => Point(p.x - minX, p.y - minY))
        .toList();

    final mastercaseIndex = normalizedCoords
        .indexWhere((p) => p.x == mastercaseLocal.x && p.y == mastercaseLocal.y);
    if (mastercaseIndex == -1) {
      // La mastercase n'existe pas dans cette orientation
      return null;
    }

    final mastercaseRaw = rawCoords[mastercaseIndex];

    // Position initiale pour garder la mastercase fixe
    final initialGridX = mastercaseAbs.x - mastercaseRaw.x;
    final initialGridY = mastercaseAbs.y - mastercaseRaw.y;

    // Recherche en spirale autour de la position initiale
    for (int radius = 0; radius <= maxRadius; radius++) {
      // Générer toutes les positions à cette distance
      final candidates = <Point>[];
      
      if (radius == 0) {
        candidates.add(Point(initialGridX, initialGridY));
      } else {
        // Parcourir le périmètre du carré de rayon radius
        for (int dx = -radius; dx <= radius; dx++) {
          for (int dy = -radius; dy <= radius; dy++) {
            // Ne garder que les cases sur le périmètre (distance exacte = radius)
            if ((dx.abs() == radius || dy.abs() == radius)) {
              final testGridX = initialGridX + dx;
              final testGridY = initialGridY + dy;
              candidates.add(Point(testGridX, testGridY));
            }
          }
        }
      }

      // Tester chaque candidat
      for (final candidate in candidates) {
        final testPiece = piece.copyWith(
          gridX: candidate.x,
          gridY: candidate.y,
        );

        // Vérifier si cette position est valide
        bool isValid = true;
        for (final cell in testPiece.absoluteCells) {
          // Vérifier les limites
          if (cell.x < 0 ||
              cell.x >= state.plateau.width ||
              cell.y < 0 ||
              cell.y >= state.plateau.height) {
            isValid = false;
            break;
          }

          // Vérifier chevauchement
          final cellValue = tempPlateau.getCell(cell.x, cell.y);
          if (cellValue != 0 && cellValue != piece.piece.id) {
            isValid = false;
            break;
          }
        }

        if (isValid) {
          debugPrint('✅ Position valide trouvée à distance $radius: (${candidate.x}, ${candidate.y})');
          return candidate;
        }
      }
    }

    debugPrint('❌ Aucune position valide trouvée dans un rayon de $maxRadius');
    return null;
  }

  /// Trouve la position valide la plus proche du vecteur de translation
  /// dragGridX/Y = position du doigt sur le plateau
  /// Retourne la position d'ancre valide la plus proche du vecteur
  ///
  /// ✅ FIX: On cherche l'ancre la plus proche de l'ancre désirée
  /// (calculée via le vecteur mastercase -> doigt)
  Point? _findClosestValidPlacement(int dragGridX, int dragGridY) {
    if (state.validPlacements.isEmpty) return null;
    if (state.selectedPiece == null) return null;

    final desiredAnchor = _calculateDesiredAnchorFromDrag(dragGridX, dragGridY);

    // Chercher le placement valide le plus proche de l'ancre désirée
    Point closest = state.validPlacements[0];
    double minDistance = double.infinity;

    for (final placement in state.validPlacements) {
      // Distance entre l'ancre désirée et l'ancre candidate
      final dx = (desiredAnchor.x - placement.x).toDouble();
      final dy = (desiredAnchor.y - placement.y).toDouble();
      final distance = dx * dx + dy * dy;

      if (distance < minDistance) {
        minDistance = distance;
        closest = placement;
      }
    }

    // Correctif 4 (§4) — plafond d'aimantation : au-delà d'environ 1,5 case de l'ancre
    // désirée, on refuse le snap (retour null) plutôt que de téléporter la pièce vers le
    // seul placement valide restant, aussi lointain soit-il (défaut 3.1). Distance au carré,
    // donc seuil au carré. Ne peut être en service qu'avec les correctifs 1 et 2 (§7).
    const double maxSnapDistanceSquared = 1.5 * 1.5;
    if (minDistance > maxSnapDistanceSquared) return null;

    return closest;
  }

  /// Génère TOUS les placements possibles pour une pièce à une positionIndex donnée
  /// Retourne une liste de Point (gridX, gridY) où la pièce peut être placée
  List<Point> _generateValidPlacements(Pento piece, int positionIndex) {
    final validPlacements = <Point>[];
    

    // 🔧 FIX: Calculer les offsets de la pièce pour étendre le balayage
    // Certaines pièces ont des cellules avec des offsets positifs par rapport à l'ancre,
    // donc l'ancre peut être négative pour placer la pièce aux bords gauche/haut
    final position = piece.orientations[positionIndex];
    
    // Trouver les offsets min/max de la forme normalisée
    int minOffsetX = 5, minOffsetY = 5;
    int maxOffsetX = 0, maxOffsetY = 0;
    
    // D'abord calculer le min pour la normalisation (comme dans absoluteCells)
    int normMinX = 5, normMinY = 5;
    for (final cellNum in position) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      if (x < normMinX) normMinX = x;
      if (y < normMinY) normMinY = y;
    }
    
    // Puis calculer les offsets normalisés
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - normMinX;
      final localY = (cellNum - 1) ~/ 5 - normMinY;
      if (localX < minOffsetX) minOffsetX = localX;
      if (localY < minOffsetY) minOffsetY = localY;
      if (localX > maxOffsetX) maxOffsetX = localX;
      if (localY > maxOffsetY) maxOffsetY = localY;
    }

    // 🔧 FIX: Étendre le balayage pour inclure les positions d'ancre négatives
    // si nécessaire pour atteindre les bords du plateau
    // L'ancre peut aller de -maxOffset à (plateauSize - 1)
    final startX = -maxOffsetX;
    final startY = -maxOffsetY;
    final endX = state.plateau.width;
    final endY = state.plateau.height;

    for (int gridX = startX; gridX < endX; gridX++) {
      for (int gridY = startY; gridY < endY; gridY++) {
        if (state.canPlacePiece(piece, positionIndex, gridX, gridY)) {
          validPlacements.add(Point(gridX, gridY));
        }
      }
    }

    debugPrint('   → ${validPlacements.length} positions valides: $validPlacements');
    return validPlacements;
  }

  int _getMaxLocalX(PlacedPiece piece) {
    return piece.absoluteCells.fold(
          0,
          (max, cell) => cell.x > max ? cell.x : max,
        ) -
        piece.gridX;
  }

  int _getMaxLocalY(PlacedPiece piece) {
    return piece.absoluteCells.fold(
          0,
          (max, cell) => cell.y > max ? cell.y : max,
        ) -
        piece.gridY;
  }

  // Helper unifié : reconstruit le plateau depuis une liste de pièces.
  // exclude : pièce à ignorer (ex: pièce sélectionnée temporairement retirée).
  // pieces  : liste source (défaut: state.placedPieces).
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

  // ========================================================================
  // ORIENTATION "VUE" (repère écran)
  // ========================================================================

  // ==========================================================================
  // ISOMÉTRIES (lookup robuste via Pento.cartesianCoords)
  // ==========================================================================

  /// Remapping de la cellule de référence lors d'une isométrie
  /// 
  /// ✅ Utilise maintenant la méthode du mixin (même implémentation)
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

}

/// État du jeu Pentoscope
class PentoscopeState implements PieceManipulationState {
  /// Orientation "vue" (repère écran). Ne change pas la logique.
  /// Sert à interpréter des actions (ex: Sym H/V) en paysage.
  final ViewOrientation viewOrientation;
  final PentoscopePuzzle? puzzle;
  final Plateau plateau;
  final List<Pento> availablePieces;
  final List<PlacedPiece> placedPieces;

  // Sélection pièce du slider
  final Pento? selectedPiece;
  final int selectedPositionIndex;
  final Map<int, int> piecePositionIndices;

  // Sélection pièce placée
  final PlacedPiece? selectedPlacedPiece;
  final Point? selectedCellInPiece; // Mastercase
  final Point? selectedMasterAbs; // Mastercase absolue à la sélection

  // Preview
  final int? previewX;
  final int? previewY;
  final bool isPreviewValid;

  // ✨ NOUVEAU: Liste des placements valides pour la pièce sélectionnée
  final List<Point> validPlacements;

  // État du jeu
  final bool isComplete;
  final int isometryCount;
  final int translationCount;
  final int hintCount;   // 💡 Nombre de fois où la lampe a été utilisée
  final int deleteCount; // 🗑️ Nombre de suppressions de pièces

  final bool isSnapped;
  final bool isDragging;
  final bool showSolution;

  /// Solution complète « à afficher » (guide), sous forme de placements. Vient de la
  /// SolutionSource via hintFrom ; `null` si l'option est désactivée.
  final List<PlacedPiece>? currentSolution;

  // 💡 HINT: Indique si au moins une solution est encore possible
  final bool hasPossibleSolution;

  // 🔢 Nombre de solutions complètes encore compatibles, ou null si la source ne
  // sait pas compter (solveur à la volée). Affiché si GameSettings.showSolutionCounter.
  final int? solutionsCount;

  // ⏱️ Timer
  final int elapsedSeconds;

  const PentoscopeState({
    this.viewOrientation = ViewOrientation.portrait,
    this.puzzle,
    required this.plateau,
    this.availablePieces = const [],
    this.placedPieces = const [],
    this.selectedPiece,
    this.selectedPositionIndex = 0,
    this.piecePositionIndices = const {},
    this.selectedPlacedPiece,
    this.selectedCellInPiece,
    this.selectedMasterAbs,
    this.previewX,
    this.previewY,
    this.isPreviewValid = false,
    this.validPlacements = const [], // ✨ NOUVEAU
    this.isComplete = false,
    this.isometryCount = 0,
    this.translationCount = 0,
    this.hintCount = 0,   // 💡
    this.deleteCount = 0, // 🗑️
    this.isSnapped = false,
    this.isDragging = false,
    this.showSolution = false,
    this.currentSolution,
    this.hasPossibleSolution = true, // 💡 Par défaut true au démarrage
    this.solutionsCount, // 🔢 null tant qu'aucun puzzle à table n'est démarré
    this.elapsedSeconds = 0, // ⏱️ Timer
  });

  factory PentoscopeState.initial() {
    return PentoscopeState(
      plateau: Plateau.allVisible(5, 5),
      showSolution: false, // ✅ NOUVEAU
      currentSolution: null, // ✅ NOUVEAU
    );
  }

  bool canPlacePiece(Pento piece, int positionIndex, int gridX, int gridY) {
    final position = piece.orientations[positionIndex];

    // Trouver le décalage minimum pour normaliser la forme
    int minLocalX = 5, minLocalY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minLocalX) minLocalX = localX;
      if (localY < minLocalY) minLocalY = localY;
    }

    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5 - minLocalX; // Normalisé
      final localY = (cellNum - 1) ~/ 5 - minLocalY; // Normalisé
      final x = gridX + localX;
      final y = gridY + localY;

      if (x < 0 || x >= plateau.width || y < 0 || y >= plateau.height) {
        return false;
      }

      final cellValue = plateau.getCell(x, y);
      if (cellValue != 0) {
        return false;
      }
    }

    return true;
  }

  PentoscopeState copyWith({
    ViewOrientation? viewOrientation,
    PentoscopePuzzle? puzzle,
    Plateau? plateau,
    List<Pento>? availablePieces,
    List<PlacedPiece>? placedPieces,
    Pento? selectedPiece,
    bool clearSelectedPiece = false,
    int? selectedPositionIndex,
    Map<int, int>? piecePositionIndices,
    PlacedPiece? selectedPlacedPiece,
    bool clearSelectedPlacedPiece = false,
    Point? selectedCellInPiece,
    bool clearSelectedCellInPiece = false,
    Point? selectedMasterAbs,
    bool clearSelectedMasterAbs = false,
    int? previewX,
    int? previewY,
    bool? isPreviewValid,
    bool clearPreview = false,
    List<Point>? validPlacements, // ✨ NOUVEAU
    bool? isComplete,
    int? isometryCount,
    int? translationCount,
    int? hintCount,   // 💡
    int? deleteCount, // 🗑️
    bool? isSnapped,
    bool? isDragging,
    bool? showSolution, // ✅ NOUVEAU
    List<PlacedPiece>? currentSolution,
    bool? hasPossibleSolution, // 💡 HINT
    int? solutionsCount, // 🔢
    int? elapsedSeconds, // ⏱️ Timer
  }) {
    return PentoscopeState(
      viewOrientation: viewOrientation ?? this.viewOrientation,
      puzzle: puzzle ?? this.puzzle,
      plateau: plateau ?? this.plateau,
      availablePieces: availablePieces ?? this.availablePieces,
      placedPieces: placedPieces ?? this.placedPieces,
      selectedPiece: clearSelectedPiece
          ? null
          : (selectedPiece ?? this.selectedPiece),
      selectedPositionIndex:
          selectedPositionIndex ?? this.selectedPositionIndex,
      piecePositionIndices: piecePositionIndices ?? this.piecePositionIndices,
      selectedPlacedPiece: clearSelectedPlacedPiece
          ? null
          : (selectedPlacedPiece ?? this.selectedPlacedPiece),
      selectedCellInPiece: clearSelectedCellInPiece
          ? null
          : (selectedCellInPiece ?? this.selectedCellInPiece),
      selectedMasterAbs: clearSelectedMasterAbs
          ? null
          : (selectedMasterAbs ?? this.selectedMasterAbs),
      previewX: clearPreview ? null : (previewX ?? this.previewX),
      previewY: clearPreview ? null : (previewY ?? this.previewY),
      isPreviewValid: clearPreview
          ? false
          : (isPreviewValid ?? this.isPreviewValid),
      validPlacements: validPlacements ?? this.validPlacements,
      // ✨ NOUVEAU
      isComplete: isComplete ?? this.isComplete,
      isometryCount: isometryCount ?? this.isometryCount,
      translationCount: translationCount ?? this.translationCount,
      hintCount: hintCount ?? this.hintCount,
      deleteCount: deleteCount ?? this.deleteCount,
      isSnapped: isSnapped ?? this.isSnapped,
      isDragging: isDragging ?? this.isDragging,
      showSolution: showSolution ?? this.showSolution,
      // ✅ NOUVEAU
      currentSolution: currentSolution ?? this.currentSolution, // ✅ NOUVEAU
      hasPossibleSolution: hasPossibleSolution ?? this.hasPossibleSolution, // 💡 HINT
      solutionsCount: solutionsCount ?? this.solutionsCount, // 🔢
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds, // ⏱️ Timer
    );
  }

  int getPiecePositionIndex(int pieceId) {
    return piecePositionIndices[pieceId] ?? 0;
  }
}

/// Orientation "vue" (repère écran).
///
/// Important: le provider reste en coordonnées logiques. Cette info sert
/// uniquement à interpréter les actions utilisateur (ex: Sym H/V) pour que
/// le ressenti soit cohérent en paysage.
// ViewOrientation vit désormais dans common/view_orientation.dart,
// ré-exporté ci-dessus pour que les imports existants continuent de fonctionner.

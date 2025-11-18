// lib/screens/pentomino_game/widgets/shared/action_slider.dart
// Slider vertical d'actions (mode paysage uniquement)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/providers/pentomino_game_provider.dart';
import 'package:pentapol/providers/pentomino_game_state.dart';
import 'package:pentapol/screens/solutions_browser_screen.dart';
import 'package:pentapol/services/plateau_solution_counter.dart';

/// Slider vertical d'actions en mode paysage
/// 
/// Affiche différents boutons selon le mode :
/// - Mode jeu normal : isométries, solutions, rotation, undo
/// - Mode isométries : transformations, delete, retour
class ActionSlider extends ConsumerWidget {
  const ActionSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);

    if (state.isIsometriesMode) {
      return _buildIsometriesActions(context, state, notifier);
    } else {
      return _buildGameActions(context, state, notifier);
    }
  }

  /// Actions en mode isométries
  Widget _buildIsometriesActions(
    BuildContext context,
    PentominoGameState state,
    PentominoGameNotifier notifier,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Rotation
        IconButton(
          icon: Icon(GameIcons.isometryRotation.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: state.selectedPlacedPiece != null
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.applyIsometryRotation();
                }
              : null,
          tooltip: GameIcons.isometryRotation.tooltip,
          color: state.selectedPlacedPiece != null
              ? GameIcons.isometryRotation.color
              : Colors.grey,
        ),
        const SizedBox(height: 8),

        // Bouton Symétrie Horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: state.selectedPlacedPiece != null
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.applyIsometrySymmetryH();
                }
              : null,
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: state.selectedPlacedPiece != null
              ? GameIcons.isometrySymmetryH.color
              : Colors.grey,
        ),
        const SizedBox(height: 8),

        // Bouton Symétrie Verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: state.selectedPlacedPiece != null
              ? () {
                  HapticFeedback.selectionClick();
                  notifier.applyIsometrySymmetryV();
                }
              : null,
          tooltip: GameIcons.isometrySymmetryV.tooltip,
          color: state.selectedPlacedPiece != null
              ? GameIcons.isometrySymmetryV.color
              : Colors.grey,
        ),
        const SizedBox(height: 8),

        // Bouton Delete (visible si une pièce placée est sélectionnée)
        if (state.selectedPlacedPiece != null)
          IconButton(
            icon: Icon(GameIcons.isometryDelete.icon, size: 28),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: GameIcons.isometryDelete.tooltip,
            color: GameIcons.isometryDelete.color,
          ),
        if (state.selectedPlacedPiece != null) const SizedBox(height: 8),

        // Bouton Retour au Jeu
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.exitIsometriesMode();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: GameIcons.exitIsometries.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                GameIcons.exitIsometries.icon,
                size: 28,
                color: GameIcons.exitIsometries.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Actions en mode jeu normal
  Widget _buildGameActions(
    BuildContext context,
    PentominoGameState state,
    PentominoGameNotifier notifier,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Mode Isométries
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.enterIsometriesMode();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: GameIcons.enterIsometries.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                GameIcons.enterIsometries.icon,
                size: 22,
                color: GameIcons.enterIsometries.color,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Compteur de solutions (coupe)
        if (state.solutionsCount != null && state.placedPieces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  '${state.solutionsCount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: state.solutionsCount! > 0
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
                Icon(
                  GameIcons.solutionsCounter.icon,
                  size: 20,
                  color: state.solutionsCount! > 0
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Bouton "voir les solutions possibles"
        if (state.solutionsCount != null && state.solutionsCount! > 0)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                try {
                  final compatible = state.plateau.getCompatibleSolutionsBigInt();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolutionsBrowserScreen.forSolutions(
                        solutions: compatible,
                        title: 'Solutions possibles',
                      ),
                    ),
                  );
                } catch (e, stackTrace) {
                  debugPrint('❌ Erreur: $e');
                  debugPrint('❌ Stack: $stackTrace');
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GameIcons.viewSolutions.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  GameIcons.viewSolutions.icon,
                  size: 22,
                  color: GameIcons.viewSolutions.color,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Bouton de rotation (visible si pièce sélectionnée)
        if (state.selectedPiece != null)
          IconButton(
            icon: Icon(GameIcons.rotatePiece.icon, size: 22),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              HapticFeedback.selectionClick();
              notifier.applyIsometryRotation();
            },
            tooltip: GameIcons.rotatePiece.tooltip,
            color: GameIcons.rotatePiece.color,
          ),

        // Bouton retirer (visible si pièce placée sélectionnée)
        if (state.selectedPlacedPiece != null)
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: 22),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: GameIcons.removePiece.tooltip,
            color: GameIcons.removePiece.color,
          ),

        const SizedBox(height: 8),

        // Bouton Undo
        IconButton(
          icon: Icon(GameIcons.undo.icon, size: 22),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: state.placedPieces.isNotEmpty && state.selectedPiece == null
              ? () {
                  HapticFeedback.mediumImpact();
                  notifier.undoLastPlacement();
                }
              : null,
          tooltip: GameIcons.undo.tooltip,
        ),
      ],
    );
  }
}


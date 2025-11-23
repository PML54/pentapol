// lib/screens/pentomino_game/widgets/shared/action_slider.dart
// Slider vertical d'actions (mode paysage uniquement)
// Adapté automatiquement selon la sélection de pièce

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/providers/pentomino_game_provider.dart';
import 'package:pentapol/providers/pentomino_game_state.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/solutions_browser_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/services/plateau_solution_counter.dart'; // ✅ AJOUT : Pour l'extension getCompatibleSolutionsBigInt()

/// Slider vertical d'actions en mode paysage
///
/// Affiche automatiquement les bonnes actions selon la sélection :
/// - Mode transformation (pièce sélectionnée) : isométries + delete
/// - Mode général (aucune sélection) : solutions, undo, paramètres
class ActionSlider extends ConsumerWidget {
  const ActionSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Détection automatique du mode
    final isInTransformMode = state.selectedPiece != null || state.selectedPlacedPiece != null;

    if (isInTransformMode) {
      return _buildTransformActions(context, state, notifier, settings);
    } else {
      return _buildGeneralActions(context, state, notifier);
    }
  }

  /// Actions en mode TRANSFORMATION (pièce sélectionnée)
  Widget _buildTransformActions(
      BuildContext context,
      PentominoGameState state,
      PentominoGameNotifier notifier,
      settings,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rotation anti-horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotation.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotation();
          },
          tooltip: GameIcons.isometryRotation.tooltip,
          color: GameIcons.isometryRotation.color,
        ),
        const SizedBox(height: 8),

        // Rotation horaire
        IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationCW();
          },
          tooltip: GameIcons.isometryRotationCW.tooltip,
          color: GameIcons.isometryRotationCW.color,
        ),
        const SizedBox(height: 8),

        // Symétrie Horizontale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryH();
          },
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: GameIcons.isometrySymmetryH.color,
        ),
        const SizedBox(height: 8),

        // Symétrie Verticale
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryV();
          },
          tooltip: GameIcons.isometrySymmetryV.tooltip,
          color: GameIcons.isometrySymmetryV.color,
        ),

        // Delete (uniquement si pièce placée sélectionnée)
        if (state.selectedPlacedPiece != null) ...[
          const SizedBox(height: 8),
          IconButton(
            icon: Icon(GameIcons.removePiece.icon, size: 28),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.removePlacedPiece(state.selectedPlacedPiece!);
            },
            tooltip: GameIcons.removePiece.tooltip,
            color: GameIcons.removePiece.color,
          ),
        ],
      ],
    );
  }

  /// Actions en mode GÉNÉRAL (aucune pièce sélectionnée)
  Widget _buildGeneralActions(
      BuildContext context,
      PentominoGameState state,
      PentominoGameNotifier notifier,
      ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Paramètres
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.settings,
                size: 22,
                color: Colors.indigo,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Compteur de solutions
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

        // Bouton "voir les solutions possibles"
        if (state.solutionsCount != null && state.solutionsCount! > 0) ...[
          const SizedBox(height: 8),
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
        ],

        const SizedBox(height: 12),

        // Bouton Undo
        IconButton(
          icon: Icon(GameIcons.undo.icon, size: 22),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: state.placedPieces.isNotEmpty
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
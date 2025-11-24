// lib/screens/pentomino_game/widgets/shared/action_slider.dart
// Slider vertical d'actions (mode paysage uniquement)
// Adapté automatiquement selon la sélection de pièce

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/models/plateau.dart';  // ✅ AJOUT
import 'package:pentapol/providers/pentomino_game_provider.dart';
import 'package:pentapol/providers/pentomino_game_state.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/solutions_browser_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/services/plateau_solution_counter.dart';

/// ✅ Fonction helper en dehors de la classe
List<BigInt> getCompatibleSolutionsIncludingSelected(PentominoGameState state) {
  if (state.selectedPlacedPiece == null) {
    return state.plateau.getCompatibleSolutionsBigInt();
  }

  final tempPlateau = Plateau.allVisible(6, 10);

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

  final selectedPiece = state.selectedPlacedPiece!;
  final position = selectedPiece.piece.positions[state.selectedPositionIndex];
  for (final cellNum in position) {
    final localX = (cellNum - 1) % 5;
    final localY = (cellNum - 1) ~/ 5;
    final x = selectedPiece.gridX + localX;
    final y = selectedPiece.gridY + localY;
    if (x >= 0 && x < 6 && y >= 0 && y < 10) {
      tempPlateau.setCell(x, y, selectedPiece.piece.id);
    }
  }

  return tempPlateau.getCompatibleSolutionsBigInt();
}

/// Slider vertical d'actions en mode paysage
class ActionSlider extends ConsumerWidget {
  final bool isLandscape;

  const ActionSlider({
    super.key,
    this.isLandscape = true, // Par défaut true car utilisé principalement en paysage
  });

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
        // ✅ Bouton Solutions (si > 0)
        if (state.solutionsCount != null && state.solutionsCount! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final solutions = getCompatibleSolutionsIncludingSelected(state);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SolutionsBrowserScreen.forSolutions(
                      solutions: solutions,
                      title: 'Solutions possibles',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(40, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                '${state.solutionsCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

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

        // Symétrie Horizontale (visuelle)
        // ✅ En mode paysage : H visuel = V logique (à cause de la rotation du plateau)
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (isLandscape) {
              notifier.applyIsometrySymmetryV(); // Paysage: H visuel = V logique
            } else {
              notifier.applyIsometrySymmetryH(); // Portrait: H visuel = H logique
            }
          },
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: GameIcons.isometrySymmetryH.color,
        ),
        const SizedBox(height: 8),

        // Symétrie Verticale (visuelle)
        // ✅ En mode paysage : V visuel = H logique (à cause de la rotation du plateau)
        IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: 28),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (isLandscape) {
              notifier.applyIsometrySymmetryH(); // Paysage: V visuel = H logique
            } else {
              notifier.applyIsometrySymmetryV(); // Portrait: V visuel = V logique
            }
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
        if (state.solutionsCount != null && state.solutionsCount! > 0 && state.placedPieces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final solutions = state.plateau.getCompatibleSolutionsBigInt();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SolutionsBrowserScreen.forSolutions(
                      solutions: solutions,
                      title: 'Solutions possibles',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(40, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                '${state.solutionsCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 8),

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
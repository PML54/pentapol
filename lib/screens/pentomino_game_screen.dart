// Modified: 2025-11-16 10:00:00
// lib/screens/pentomino_game_screen.dart
// Écran de jeu de pentominos avec drag & drop

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/providers/pentomino_game_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/solutions_browser_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';
import 'package:pentapol/services/plateau_solution_counter.dart';
import 'package:pentapol/config/game_icons_config.dart';

// Widgets extraits
import 'package:pentapol/screens/pentomino_game/widgets/shared/action_slider.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/game_board.dart';
import 'package:pentapol/screens/pentomino_game/widgets/game_mode/piece_slider.dart';


class PentominoGameScreen extends ConsumerStatefulWidget {
  const PentominoGameScreen({super.key});

  @override
  ConsumerState<PentominoGameScreen> createState() => _PentominoGameScreenState();
}

class _PentominoGameScreenState extends ConsumerState<PentominoGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation de pulsation pour l'icône œil (plus prononcée)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Détecter l'orientation pour adapter l'AppBar
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      // AppBar uniquement en mode portrait
      appBar: isLandscape ? null : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: state.isIsometriesMode 
              ? settings.ui.isometriesAppBarColor  // Couleur paramétrable en mode isométries
              : null,  // Fond par défaut (indigo) en mode normal
          leading: state.isIsometriesMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    notifier.exitIsometriesMode();
                  },
                  tooltip: 'Sortir du mode isométries',
                )
              : IconButton(
                  icon: Icon(GameIcons.enterIsometries.icon),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    notifier.enterIsometriesMode();
                  },
                  tooltip: GameIcons.enterIsometries.tooltip,
                  color: GameIcons.enterIsometries.color,
                ),
          title: !state.isIsometriesMode && state.solutionsCount != null && state.solutionsCount! > 0 && state.placedPieces.isNotEmpty
              ? ScaleTransition(
                  scale: _pulseAnimation,
                  child: IconButton(
                    icon: Icon(GameIcons.viewSolutions.icon, size: 32),
                    tooltip: GameIcons.viewSolutions.tooltip,
                    color: Colors.lightBlueAccent,
                    onPressed: () {
                      HapticFeedback.selectionClick();

                      // Récupérer les solutions compatibles pour le plateau actuel (BigInt)
                      final compatible = state.plateau.getCompatibleSolutionsBigInt();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SolutionsBrowserScreen.forSolutions(
                            solutions: compatible,
                            title: 'Solutions possibles',
                          ),
                        ),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
          actions: state.isIsometriesMode
              ? [
                  // MODE ISOMÉTRIES : Boutons de transformation (icônes plus grandes)
                  IconButton(
                    icon: Icon(GameIcons.isometryRotation.icon, size: 32),
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
                  IconButton(
                    icon: Icon(GameIcons.isometrySymmetryH.icon, size: 32),
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
                  IconButton(
                    icon: Icon(GameIcons.isometrySymmetryV.icon, size: 32),
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
                  // Bouton Delete (visible si une pièce placée est sélectionnée)
                  if (state.selectedPlacedPiece != null)
                    IconButton(
                      icon: Icon(GameIcons.isometryDelete.icon, size: 32),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        notifier.removePlacedPiece(state.selectedPlacedPiece!);
                      },
                      tooltip: GameIcons.isometryDelete.tooltip,
                      color: GameIcons.isometryDelete.color,
                    ),
                ]
              : [
                  // MODE JEU NORMAL : Boutons normaux
                  // Bouton paramètres à droite
                  IconButton(
                    icon: const Icon(Icons.settings, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    tooltip: 'Paramètres',
                  ),

                  // Boutons de transformation (visibles si pièce sélectionnée)
                  if (state.selectedPiece != null) ...[
                    IconButton(
                      icon: Icon(GameIcons.isometryRotation.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.applyIsometryRotation();
                      },
                      tooltip: GameIcons.isometryRotation.tooltip,
                      color: GameIcons.isometryRotation.color,
                    ),
                    IconButton(
                      icon: Icon(GameIcons.isometrySymmetryH.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.applyIsometrySymmetryH();
                      },
                      tooltip: GameIcons.isometrySymmetryH.tooltip,
                      color: GameIcons.isometrySymmetryH.color,
                    ),
                    IconButton(
                      icon: Icon(GameIcons.isometrySymmetryV.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.applyIsometrySymmetryV();
                      },
                      tooltip: GameIcons.isometrySymmetryV.tooltip,
                      color: GameIcons.isometrySymmetryV.color,
                    ),
                  ],
                  // Bouton retirer (visible si pièce placée sélectionnée)
                  if (state.selectedPlacedPiece != null)
                    IconButton(
                      icon: Icon(GameIcons.removePiece.icon, size: 24),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        notifier.removePlacedPiece(state.selectedPlacedPiece!);
                      },
                      tooltip: GameIcons.removePiece.tooltip,
                      color: GameIcons.removePiece.color,
                    ),
                ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          if (isLandscape) {
            return _buildLandscapeLayout(context, ref, state, notifier);
          } else {
            return _buildPortraitLayout(context, ref, state, notifier);
          }
        },
      ),
    );
  }

  /// Layout portrait (classique) : plateau en haut, slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        Expanded(
          flex: 3,
          child: GameBoard(isLandscape: false),
        ),

        // Slider de pièces horizontal
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: PieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage : plateau à gauche, actions + slider vertical à droite
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      ) {
    final settings = ref.watch(settingsProvider);
    
    return Row(
      children: [
        // Plateau de jeu (10×6 visuel)
        Expanded(
          child: GameBoard(isLandscape: true),
        ),

        // Colonne de droite : actions + slider
        Row(
          children: [
            // Slider d'actions verticales
            Container(
              width: 44,
              decoration: BoxDecoration(
                color: state.isIsometriesMode 
                    ? settings.ui.isometriesAppBarColor.withValues(alpha: 0.3)  // Couleur paramétrable atténuée
                    : Colors.grey.shade200,   // Fond gris en mode normal
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: const ActionSlider(),
            ),

            // Slider de pièces vertical
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: PieceSlider(isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }

}
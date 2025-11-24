// Modified: 2025-11-23 04:11
// lib/screens/pentomino_game_screen.dart
// Interface simplifiée avec 2 modes exclusifs auto-détectés

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
import 'package:pentapol/screens/pentomino_game/widgets/shared/action_slider.dart'
    show ActionSlider, getCompatibleSolutionsIncludingSelected;
import 'package:pentapol/screens/pentomino_game/widgets/shared/game_board.dart';
import 'package:pentapol/screens/pentomino_game/widgets/game_mode/piece_slider.dart';
import 'package:pentapol/models/plateau.dart';




class PentominoGameScreen extends ConsumerStatefulWidget {
  const PentominoGameScreen({super.key});

  @override
  ConsumerState<PentominoGameScreen> createState() => _PentominoGameScreenState();
}

class _PentominoGameScreenState extends ConsumerState<PentominoGameScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Détection automatique du mode selon la sélection
    final isInTransformMode = state.selectedPiece != null || state.selectedPlacedPiece != null;

    // Détecter l'orientation pour adapter l'AppBar
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      // AppBar uniquement en mode portrait
      appBar: isLandscape ? null : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: isInTransformMode
              ? settings.ui.isometriesAppBarColor  // Couleur en mode transformation
              : null,  // Fond par défaut en mode général

          // LEADING : Paramètres (mode général) ou rien (mode transformation)
          leading: !isInTransformMode
              ? IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Paramètres',
          )
              : null,
// TITLE : Bouton Solutions (affiché dès qu'il y a des solutions > 0)
          title: state.solutionsCount != null && state.solutionsCount! > 0
              ? FittedBox(
            fit: BoxFit.scaleDown,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final solutions = getCompatibleSolutionsIncludingSelected(state);
                Navigator.of(context).push(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
              child: Text(
                '${state.solutionsCount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
              : const SizedBox.shrink(),
          // ACTIONS : Mode transformation OU mode général
          actions: isInTransformMode
              ? _buildTransformActions(state, notifier, settings)
              : _buildGeneralActions(state, notifier, settings),
        ),
      ),
      body: Stack(
        children: [
          // Layout principal (portrait ou paysage)
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(context, ref, state, notifier, isInTransformMode);
              } else {
                return _buildPortraitLayout(context, ref, state, notifier);
              }
            },
          ),


        ],
      ),
    );
  }

  /// Actions en mode TRANSFORMATION (pièce sélectionnée)
  List<Widget> _buildTransformActions(state, notifier, settings) {
    return [
      // Rotation anti-horaire
      IconButton(
        icon: Icon(GameIcons.isometryRotation.icon, size: settings.ui.iconSize),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometryRotation();
        },
        tooltip: GameIcons.isometryRotation.tooltip,
        color: GameIcons.isometryRotation.color,
      ),
      // Rotation horaire
      IconButton(
        icon: Icon(GameIcons.isometryRotationCW.icon, size: settings.ui.iconSize),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometryRotationCW();
        },
        tooltip: GameIcons.isometryRotationCW.tooltip,
        color: GameIcons.isometryRotationCW.color,
      ),
      // Symétrie horizontale
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryH.icon, size: settings.ui.iconSize),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometrySymmetryH();
        },
        tooltip: GameIcons.isometrySymmetryH.tooltip,
        color: GameIcons.isometrySymmetryH.color,
      ),
      // Symétrie verticale
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryV.icon, size: settings.ui.iconSize),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometrySymmetryV();
        },
        tooltip: GameIcons.isometrySymmetryV.tooltip,
        color: GameIcons.isometrySymmetryV.color,
      ),
      // Delete (uniquement si pièce placée sélectionnée)
      if (state.selectedPlacedPiece != null)
        IconButton(
          icon: Icon(GameIcons.removePiece.icon, size: settings.ui.iconSize),
          onPressed: () {
            HapticFeedback.mediumImpact();
            notifier.removePlacedPiece(state.selectedPlacedPiece!);
          },
          tooltip: GameIcons.removePiece.tooltip,
          color: GameIcons.removePiece.color,
        ),
    ];
  }

  /// Actions en mode GÉNÉRAL (aucune pièce sélectionnée)
  List<Widget> _buildGeneralActions(state, notifier, settings) {
    return [
      // Bouton Démo/Tutoriel
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () {
          HapticFeedback.selectionClick();

        },
        tooltip: 'Démo : Comment jouer',
      ),
    ];
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
      bool isInTransformMode,
      )
  {
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
            // Slider d'actions verticales (même logique que l'AppBar)
            Container(
              width: 44,
              decoration: BoxDecoration(
                color: isInTransformMode
                    ? settings.ui.isometriesAppBarColor.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: const ActionSlider(isLandscape: true),
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
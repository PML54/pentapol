// Modified: 2025-12-02
// lib/screens/pentomino_game_screen.dart
// Interface simplifiée avec 2 modes exclusifs auto-détectés
// AJOUT: Drag vers slider = retirer la pièce du plateau

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/providers/pentomino_game_provider.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/solutions_browser_screen.dart';
import 'package:pentapol/screens/settings_screen.dart';

import 'package:pentapol/config/game_icons_config.dart';
import 'package:pentapol/models/pentominos.dart';

// Widgets extraits
import 'package:pentapol/screens/pentomino_game/widgets/shared/action_slider.dart'
    show ActionSlider, getCompatibleSolutionsIncludingSelected;
import 'package:pentapol/screens/pentomino_game/widgets/shared/game_board.dart';
import 'package:pentapol/screens/pentomino_game/widgets/game_mode/piece_slider.dart';

import '../tutorial/widgets/highlighted_icon_button.dart';

// Tutorial
import 'package:pentapol/tutorial/tutorial.dart';
import 'package:flutter/services.dart' show rootBundle;

// Duel
import 'package:pentapol/duel/screens/duel_home_screen.dart';

// Pentoscope
import 'package:pentapol/pentoscope/screens/pentoscope_menu_screen.dart';

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
      backgroundColor: Colors.white,
      // AppBar uniquement en mode portrait
      appBar: isLandscape ? null : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: Colors.white,
          // LEADING : Paramètres + Duel (mode général) ou rien (mode transformation)
          leadingWidth: !isInTransformMode ? 144 : 56,
          leading: !isInTransformMode
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Paramètres
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                tooltip: 'Paramètres',
              ),
              // Bouton Mode Duel
              IconButton(
                icon: const Icon(Icons.sports_esports),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DuelHomeScreen()),
                  );
                },
                tooltip: 'Mode Duel',
                color: Colors.blue,
              ),
              // Bouton Pentoscope
              IconButton(
                icon: const Icon(Icons.grid_view),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PentoscopeMenuScreen()),
                  );
                },
                tooltip: 'Pentoscope',
                color: Colors.teal,
              ),
            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                minimumSize: const Size(45, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '${state.solutionsCount}',
                style: const TextStyle(
                  fontSize: 15,
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

          // Tutorial overlay
          const TutorialOverlay(),
          const TutorialControls(),
        ],
      ),
    );
  }

  /// Actions en mode TRANSFORMATION (pièce sélectionnée)
  List<Widget> _buildTransformActions(state, notifier, settings) {
    return [
      // Rotation anti-horaire
      HighlightedIconButton(
        isHighlighted: state.highlightedIsometryIcon == 'rotation',
        child: IconButton(
          icon: Icon(GameIcons.isometryRotation.icon, size: settings.ui.iconSize),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotation();
          },
          tooltip: GameIcons.isometryRotation.tooltip,
          color: GameIcons.isometryRotation.color,
        ),
      ),

      // Rotation horaire
      HighlightedIconButton(
        isHighlighted: state.highlightedIsometryIcon == 'rotation_cw',
        child: IconButton(
          icon: Icon(GameIcons.isometryRotationCW.icon, size: settings.ui.iconSize),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotationCW();
          },
          tooltip: GameIcons.isometryRotationCW.tooltip,
          color: GameIcons.isometryRotationCW.color,
        ),
      ),

      // Symétrie horizontale
      HighlightedIconButton(
        isHighlighted: state.highlightedIsometryIcon == 'symmetry_h',
        child: IconButton(
          icon: Icon(GameIcons.isometrySymmetryH.icon, size: settings.ui.iconSize),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryH();
          },
          tooltip: GameIcons.isometrySymmetryH.tooltip,
          color: GameIcons.isometrySymmetryH.color,
        ),
      ),

      // Symétrie verticale
      HighlightedIconButton(
        isHighlighted: state.highlightedIsometryIcon == 'symmetry_v',
        child: IconButton(
          icon: Icon(GameIcons.isometrySymmetryV.icon, size: settings.ui.iconSize),
          onPressed: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometrySymmetryV();
          },
          tooltip: GameIcons.isometrySymmetryV.tooltip,
          color: GameIcons.isometrySymmetryV.color,
        ),
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
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () async {
          HapticFeedback.selectionClick();

          try {
            // Charger le tutoriel d'introduction
            final yamlContent = await rootBundle.loadString(
              'assets/tutorials/Symmetry_basics.yaml',
            );

            // Parser le script
            final script = YamlScriptParser.parse(yamlContent);

            // Charger et démarrer le tutoriel
            final tutorialNotifier = ref.read(tutorialProvider.notifier);
            tutorialNotifier.loadScript(script);
            await tutorialNotifier.start();

          } catch (e) {
            // En cas d'erreur, afficher un message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
        tooltip: 'Démo : Comment jouer',
      ),
    ];
  }

  // ============================================================================
  // NOUVEAU: Widget slider avec DragTarget pour retirer les pièces
  // ============================================================================

  /// Construit le slider enveloppé dans un DragTarget
  /// Quand on drag une pièce placée vers le slider, elle est retirée du plateau
  Widget _buildSliderWithDragTarget({
    required WidgetRef ref,
    required bool isLandscape,
  }) {
    final state = ref.watch(pentominoGameProvider);
    final notifier = ref.read(pentominoGameProvider.notifier);

    return DragTarget<Pento>(
      onWillAcceptWithDetails: (details) {
        // Accepter seulement si c'est une pièce placée (pas du slider)
        return state.selectedPlacedPiece != null;
      },
      onAcceptWithDetails: (details) {
        // Retirer la pièce du plateau
        if (state.selectedPlacedPiece != null) {
          HapticFeedback.mediumImpact();
          notifier.removePlacedPiece(state.selectedPlacedPiece!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        // Highlight visuel quand on survole avec une pièce placée
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: isLandscape ? null : 140,
          width: isLandscape ? 120 : null,
          decoration: BoxDecoration(
            color: isHovering ? Colors.red.shade50 : Colors.grey.shade100,
            border: isHovering
                ? Border.all(color: Colors.red.shade400, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: isLandscape ? const Offset(-2, 0) : const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Le slider
              PieceSlider(isLandscape: isLandscape),

              // Overlay de suppression au survol
              if (isHovering)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade700,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Layout portrait (classique) : plateau en haut, slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      state,
      notifier,
      )
  {
    debugPrint("🔥 _buildPortraitLayout CALLED");
    return Column(
      children: [
        // Plateau de jeu
        Expanded(
          flex: 3,
          child: GameBoard(isLandscape: false),
        ),

        // Slider de pièces horizontal AVEC DragTarget
        _buildSliderWithDragTarget(ref: ref, isLandscape: false),
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(-1, 0),
                  ),
                ],
              ),
              child: const ActionSlider(isLandscape: true),
            ),

            // Slider de pièces vertical AVEC DragTarget
            _buildSliderWithDragTarget(ref: ref, isLandscape: true),
          ],
        ),
      ],
    );
  }
}
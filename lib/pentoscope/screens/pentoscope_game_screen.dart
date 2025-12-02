// lib/pentoscope/screens/pentoscope_game_screen.dart
// Écran de jeu Pentoscope - calqué sur pentomino_game_screen.dart
// MODIFICATION: Drag vers slider = retirer la pièce

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import '../pentoscope_provider.dart';
import '../widgets/pentoscope_board.dart';
import '../widgets/pentoscope_piece_slider.dart';

class PentoscopeGameScreen extends ConsumerWidget {
  const PentoscopeGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.watch(settingsProvider);

    if (state.puzzle == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun puzzle')),
      );
    }

    // Détection du mode transformation (pièce sélectionnée)
    final isInTransformMode = state.selectedPiece != null || state.selectedPlacedPiece != null;

    // Orientation
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isLandscape
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: null, // PAS DE TITRE
          actions: isInTransformMode
              ? _buildTransformActions(state, notifier, settings)
              : _buildGeneralActions(state, notifier),
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(context, ref, state, notifier, settings, isInTransformMode);
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
  List<Widget> _buildTransformActions(PentoscopeState state, PentoscopeNotifier notifier, settings) {
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

      // Supprimer (uniquement si pièce placée sélectionnée)
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
  List<Widget> _buildGeneralActions(PentoscopeState state, PentoscopeNotifier notifier) {
    return [
      // Compteur pièces
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Text(
            '${state.placedPieces.length}/${state.puzzle?.size.numPieces ?? 0}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),

      // Reset
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          HapticFeedback.mediumImpact();
          notifier.reset();
        },
        tooltip: 'Recommencer',
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
    required Widget sliderChild,
    required BoxDecoration decoration,
    double? width,
    double? height,
  }) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);

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
          width: width,
          height: height,
          decoration: decoration.copyWith(
            border: isHovering
                ? Border.all(color: Colors.red.shade400, width: 3)
                : null,
            color: isHovering
                ? Colors.red.shade50
                : decoration.color,
          ),
          child: Stack(
            children: [
              sliderChild,
              // Icône poubelle qui apparaît au survol
              if (isHovering)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                            size: 32,
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

  /// Layout portrait : plateau en haut, slider en bas
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        const Expanded(
          flex: 3,
          child: PentoscopeBoard(isLandscape: false),
        ),

        // Slider de pièces horizontal avec DragTarget
        _buildSliderWithDragTarget(
          ref: ref,
          isLandscape: false,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          sliderChild: const PentoscopePieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage : plateau à gauche, actions + slider vertical à droite
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      settings,
      bool isInTransformMode,
      ) {
    return Row(
      children: [
        // Plateau de jeu
        const Expanded(
          child: PentoscopeBoard(isLandscape: true),
        ),

        // Colonne de droite : actions + slider
        Row(
          children: [
            // Slider d'actions verticales
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: isInTransformMode
                    ? _buildTransformActions(state, notifier, settings)
                    : [
                  // Reset en mode général
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      notifier.reset();
                    },
                    tooltip: 'Recommencer',
                  ),
                  // Retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  ),
                ],
              ),
            ),

            // Slider de pièces vertical avec DragTarget
            _buildSliderWithDragTarget(
              ref: ref,
              isLandscape: true,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              sliderChild: const PentoscopePieceSlider(isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }
}
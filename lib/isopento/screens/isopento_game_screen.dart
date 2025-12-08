// lib/isopento/screens/isopento_game_screen.dart
// CLAUDE MOD: 12080450 (8 décembre 04h50)
// Modifications: Icones 56px + AppBar vide (pas de sélection) + Supprimer actions paysage (pas sélection) + Croix rouge retour + Inverser symétries H↔V en paysage
// Écran de jeu Isopento - calqué sur pentomino_game_screen.dart
// MODIFICATION: Drag vers slider = retirer la pièce

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import '../isopento_provider.dart';
import '../widgets/isopento_board.dart';
import '../widgets/isopento_piece_slider.dart';

class IsopentoGameScreen extends ConsumerWidget {
  const IsopentoGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(isopentoProvider);
    final notifier = ref.read(isopentoProvider.notifier);
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
          leading: isInTransformMode
              ? IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 56),
            onPressed: () => Navigator.pop(context),
          )
              : null,  // ← Pas de bouton retour quand pas de sélection
          title: null, // PAS DE TITRE
          actions: isInTransformMode
              ? _buildTransformActions(state, notifier, settings, isLandscape: false)
              : [],  // ← Pas d'actions quand pas de sélection
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(context, ref, state, notifier, settings, isInTransformMode, isLandscape);
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
  /// En paysage, les symétries H ↔ V sont inversées (affichage tourné -90°)
  List<Widget> _buildTransformActions(IsopentoState state, IsopentoNotifier notifier, settings, {bool isLandscape = false}) {
    return [
      // Rotation anti-horaire
      IconButton(
        icon: Icon(GameIcons.isometryRotation.icon, size: 56),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometryRotation();
        },
        tooltip: GameIcons.isometryRotation.tooltip,
        color: GameIcons.isometryRotation.color,
      ),

      // Rotation horaire
      IconButton(
        icon: Icon(GameIcons.isometryRotationCW.icon, size: 56),
        onPressed: () {
          HapticFeedback.selectionClick();
          notifier.applyIsometryRotationCW();
        },
        tooltip: GameIcons.isometryRotationCW.tooltip,
        color: GameIcons.isometryRotationCW.color,
      ),

      // Symétrie horizontale (inversée en paysage)
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryH.icon, size: 56),
        onPressed: () {
          HapticFeedback.selectionClick();
          // En paysage: affichage tourné -90°, donc H et V sont inversées
          if (isLandscape) {
            notifier.applyIsometrySymmetryV();  // ← Appeler V au lieu de H
          } else {
            notifier.applyIsometrySymmetryH();
          }
        },
        tooltip: GameIcons.isometrySymmetryH.tooltip,
        color: GameIcons.isometrySymmetryH.color,
      ),

      // Symétrie verticale (inversée en paysage)
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryV.icon, size: 56),
        onPressed: () {
          HapticFeedback.selectionClick();
          // En paysage: affichage tourné -90°, donc H et V sont inversées
          if (isLandscape) {
            notifier.applyIsometrySymmetryH();  // ← Appeler H au lieu de V
          } else {
            notifier.applyIsometrySymmetryV();
          }
        },
        tooltip: GameIcons.isometrySymmetryV.tooltip,
        color: GameIcons.isometrySymmetryV.color,
      ),

      // Supprimer (uniquement si pièce placée sélectionnée)
      if (state.selectedPlacedPiece != null)
        IconButton(
          icon: Icon(GameIcons.removePiece.icon, size: 56),
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
  List<Widget> _buildGeneralActions(IsopentoState state, IsopentoNotifier notifier) {
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
    final state = ref.watch(isopentoProvider);
    final notifier = ref.read(isopentoProvider.notifier);

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
      IsopentoState state,
      IsopentoNotifier notifier,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        const Expanded(
          flex: 3,
          child: IsopentoBoard(isLandscape: false),
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
          sliderChild: const IsopentoPieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage : plateau à gauche, actions + slider vertical à droite
  Widget _buildLandscapeLayout(
      BuildContext context,
      WidgetRef ref,
      IsopentoState state,
      IsopentoNotifier notifier,
      settings,
      bool isInTransformMode,
      bool isLandscape,
      ) {
    return Row(
      children: [
        // Plateau de jeu
        const Expanded(
          child: IsopentoBoard(isLandscape: true),
        ),

        // Colonne de droite : actions + slider
        Row(
          children: [
            // Slider d'actions verticales
            Container(
              width: 72,  // ← Augmenté de 44 à 72 pour les icones 56px
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
                    ? _buildTransformActions(state, notifier, settings, isLandscape: true)  // ← Passer isLandscape: true
                    : [],  // ← VIDE quand pas de sélection (plus de refresh/retour)
              ),  // ← Fermer Column
            ),  // ← Fermer Container

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
              sliderChild: const IsopentoPieceSlider(isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }
}
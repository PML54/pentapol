// lib/pentoscope/screens/pentoscope_game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final puzzle = state.puzzle;

    if (puzzle == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun puzzle chargé')),
      );
    }

    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isInTransformMode = state.selectedPlacedPieceId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isLandscape
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        title: Text('Pentoscope ${puzzle.size.label}'),
        centerTitle: true,
        actions: isInTransformMode
            ? _buildTransformActions(notifier, settings)
            : _buildGeneralActions(state, notifier),
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(context, ref, state, notifier, settings, isInTransformMode)
            : _buildPortraitLayout(context, ref, state, notifier),
      ),
    );
  }

  /// Actions en mode TRANSFORMATION (pièce placée sélectionnée)
  List<Widget> _buildTransformActions(PentoscopeNotifier notifier, settings) {
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

      // Supprimer la pièce
      IconButton(
        icon: Icon(GameIcons.removePiece.icon, size: settings.ui.iconSize),
        onPressed: () {
          HapticFeedback.mediumImpact();
          notifier.removePiece(notifier.state.selectedPlacedPieceId!);
        },
        tooltip: GameIcons.removePiece.tooltip,
        color: GameIcons.removePiece.color,
      ),
    ];
  }

  /// Actions en mode GÉNÉRAL
  List<Widget> _buildGeneralActions(PentoscopeState state, PentoscopeNotifier notifier) {
    return [
      // Infos
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Text(
            '${state.placedPieces.length}/${state.pieces.length}',
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

  /// Layout portrait
  Widget _buildPortraitLayout(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      ) {
    return Column(
      children: [
        // Plateau de jeu
        Expanded(
          flex: 3,
          child: const PentoscopeBoard(isLandscape: false),
        ),

        // Slider de pièces
        Container(
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
          child: const PentoscopePieceSlider(isLandscape: false),
        ),
      ],
    );
  }

  /// Layout paysage
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
            // Actions verticales
            Container(
              width: 50,
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
                    ? _buildTransformActions(notifier, settings)
                    : [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => notifier.reset(),
                  ),
                ],
              ),
            ),

            // Slider vertical
            Container(
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
              child: const PentoscopePieceSlider(isLandscape: true),
            ),
          ],
        ),
      ],
    );
  }
}
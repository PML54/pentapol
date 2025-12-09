// lib/isopento/screens/isopento_game_screen.dart
// Modified: 2512091021
// Écran principal du jeu Isopento - plateau + slider + actions

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/config/game_icons_config.dart';
import '../isopento_provider.dart';
import '../isopento_config.dart';
import '../widgets/isopento_board.dart';
import '../widgets/isopento_piece_slider.dart';

class IsopentoGameScreen extends ConsumerWidget {
  const IsopentoGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(isopentoProvider);
    final notifier = ref.read(isopentoProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final config = isopentoConfig;

    if (state.puzzle == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun puzzle')),
      );
    }

    // Détection du mode transformation (pièce sélectionnée)
    final isInTransformMode =
        state.selectedPiece != null || state.selectedPlacedPiece != null;

    // Orientation
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isLandscape
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AppBar(
          toolbarHeight: 56.0,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: isInTransformMode
              ? IconButton(
            icon: Icon(Icons.close,
                color: Colors.red.shade700,
                size: config.closeIconSize),
            onPressed: () {
              notifier.cancelSelection();
            },
          )
              : null,
          actions: isInTransformMode
              ? _buildTransformActions(
              state, notifier, settings, config,
              isLandscape: false)
              : [],
        ),
      ),
      body: isLandscape
          ? _buildLandscapeLayout(context, state, notifier, settings, config)
          : _buildPortraitLayout(context, state, notifier, settings, config),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context,
      IsopentoState state,
      IsopentoNotifier notifier,
      dynamic settings,
      IsopentoConfig config,
      ) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: IsopentoBoard(isLandscape: false),
        ),
        _buildSliderWithDragTarget(
          ref: null,
          isLandscape: false,
          sliderChild: const IsopentoPieceSlider(isLandscape: false),
          height: config.portraitSliderHeight,
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context,
      IsopentoState state,
      IsopentoNotifier notifier,
      dynamic settings,
      IsopentoConfig config,
      ) {
    final isInTransformMode =
        state.selectedPiece != null || state.selectedPlacedPiece != null;

    return Row(
      children: [
        const Expanded(
          child: IsopentoBoard(isLandscape: true),
        ),
        if (isInTransformMode)
          Container(
            width: config.landscapeActionsWidth,
            color: Colors.grey.shade50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildTransformActions(
                state, notifier, settings, config,
                isLandscape: true,
              ),
            ),
          ),
        _buildSliderWithDragTarget(
          ref: null,
          isLandscape: true,
          sliderChild: const IsopentoPieceSlider(isLandscape: true),
          width: config.landscapeSliderWidth,
        ),
      ],
    );
  }

  List<Widget> _buildTransformActions(
      IsopentoState state,
      IsopentoNotifier notifier,
      dynamic settings,
      IsopentoConfig config, {
        bool isLandscape = false,
      }) {
    return [
      IconButton(
        icon: Icon(GameIcons.isometryRotation.icon,
            size: config.isometryIconSize),
        onPressed: () {
          if (settings.game.enableHaptics) {
            HapticFeedback.selectionClick();
          }
          notifier.applyIsometryRotation();
        },
        tooltip: GameIcons.isometryRotation.tooltip,
        color: GameIcons.isometryRotation.color,
      ),
      IconButton(
        icon: Icon(GameIcons.isometryRotationCW.icon,
            size: config.isometryIconSize),
        onPressed: () {
          if (settings.game.enableHaptics) {
            HapticFeedback.selectionClick();
          }
          notifier.applyIsometryRotationCW();
        },
        tooltip: GameIcons.isometryRotationCW.tooltip,
        color: GameIcons.isometryRotationCW.color,
      ),
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryH.icon,
            size: config.isometryIconSize),
        onPressed: () {
          if (settings.game.enableHaptics) {
            HapticFeedback.selectionClick();
          }
          if (isLandscape) {
            notifier.applyIsometrySymmetryV();
          } else {
            notifier.applyIsometrySymmetryH();
          }
        },
        tooltip: GameIcons.isometrySymmetryH.tooltip,
        color: GameIcons.isometrySymmetryH.color,
      ),
      IconButton(
        icon: Icon(GameIcons.isometrySymmetryV.icon,
            size: config.isometryIconSize),
        onPressed: () {
          if (settings.game.enableHaptics) {
            HapticFeedback.selectionClick();
          }
          if (isLandscape) {
            notifier.applyIsometrySymmetryH();
          } else {
            notifier.applyIsometrySymmetryV();
          }
        },
        tooltip: GameIcons.isometrySymmetryV.tooltip,
        color: GameIcons.isometrySymmetryV.color,
      ),
      if (state.selectedPlacedPiece != null)
        IconButton(
          icon: Icon(GameIcons.removePiece.icon,
              size: config.isometryIconSize),
          onPressed: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.mediumImpact();
            }
            notifier.removePlacedPiece(state.selectedPlacedPiece!);
          },
          tooltip: GameIcons.removePiece.tooltip,
          color: GameIcons.removePiece.color,
        ),
    ];
  }

  Widget _buildSliderWithDragTarget({
    required WidgetRef? ref,
    required bool isLandscape,
    required Widget sliderChild,
    double? width,
    double? height,
  }) {
    return DragTarget<Pento>(
      onWillAccept: (data) => true,
      onMove: (details) {},
      onLeave: (data) {},
      onAcceptWithDetails: (details) {
        // Drag depuis board → slider = suppression pièce
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isHovering ? Colors.red.shade50 : Colors.white,
            border: Border(
              left: isLandscape
                  ? BorderSide(
                color: isHovering ? Colors.red.shade400 : Colors.grey.shade200,
                width: isHovering ? 3 : 1,
              )
                  : BorderSide(
                color: isHovering ? Colors.red.shade400 : Colors.grey.shade200,
                width: isHovering ? 3 : 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              sliderChild,
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
}
// lib/pentoscope/widgets/pentoscope_piece_slider.dart
// Slider de pièces pour Pentoscope - réutilise les composants existants

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/draggable_piece_widget.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_renderer.dart';
import '../pentoscope_provider.dart';

class PentoscopePieceSlider extends ConsumerWidget {
  final bool isLandscape;

  const PentoscopePieceSlider({
    super.key,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.read(settingsProvider);

    final pieces = state.availablePieces;

    if (pieces.isEmpty) {
      return Center(
        child: Text(
          'Toutes les pièces sont placées !',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final scrollDirection = isLandscape ? Axis.vertical : Axis.horizontal;
    final padding = isLandscape
        ? const EdgeInsets.symmetric(vertical: 16, horizontal: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        final piece = pieces[index];
        return _buildDraggablePiece(piece, index, notifier, state, settings);
      },
    );
  }

  Widget _buildDraggablePiece(
      Pento piece,
      int index,
      PentoscopeNotifier notifier,
      PentoscopeState state,
      settings,
      ) {
    final isSelected = state.selectedPieceIndex == index;
    final positionIndex = isSelected ? state.selectedOrientation : 0;

    // En mode paysage : rotation visuelle de -90° (= +3 positions)
    int displayPositionIndex = positionIndex;
    if (isLandscape) {
      displayPositionIndex = (positionIndex + 3) % piece.numPositions;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.amber.shade700, width: 3)
              : null,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: DraggablePieceWidget(
          piece: piece,
          positionIndex: positionIndex,
          isSelected: isSelected,
          selectedPositionIndex: state.selectedOrientation,
          longPressDuration: Duration(milliseconds: settings.game.longPressDuration),
          onSelect: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.selectionClick();
            }
            notifier.selectPiece(index);
          },
          onCycle: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.selectionClick();
            }
            notifier.cycleOrientation();
          },
          onCancel: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.lightImpact();
            }
            notifier.deselectPiece();
          },
          childBuilder: (isDragging) => PieceRenderer(
            piece: piece,
            positionIndex: displayPositionIndex,
            isDragging: isDragging,
            getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
          ),
        ),
      ),
    );
  }
}
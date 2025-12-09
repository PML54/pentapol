// lib/isopento/widgets/isopento_piece_slider.dart
// Modified: 2512091030
// FIXÉ: Utilise DraggablePieceWidget pour que le drag fonctionne

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/draggable_piece_widget.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_renderer.dart';
import '../isopento_provider.dart';

class IsopentoPieceSlider extends ConsumerWidget {
  final bool isLandscape;

  const IsopentoPieceSlider({
    super.key,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(isopentoProvider);
    final notifier = ref.read(isopentoProvider.notifier);
    final settings = ref.read(settingsProvider);

    final pieces = state.availablePieces;

    if (pieces.isEmpty) {
      return const SizedBox.shrink();
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
        return _buildDraggablePiece(piece, notifier, state, settings, isLandscape);
      },
    );
  }

  Widget _buildDraggablePiece(
      Pento piece,
      IsopentoNotifier notifier,
      IsopentoState state,
      settings,
      bool isLandscape,
      )
  {
    int positionIndex = state.selectedPiece?.id == piece.id
        ? state.selectedPositionIndex
        : state.getPiecePositionIndex(piece.id);

    // En mode paysage : rotation visuelle de -90° (= +3 positions)
    int displayPositionIndex = positionIndex;
    if (isLandscape) {
      displayPositionIndex = (positionIndex + 3) % piece.numPositions;
    }

    final isSelected = state.selectedPiece?.id == piece.id;

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
          selectedPositionIndex: state.selectedPositionIndex,
          longPressDuration: Duration(milliseconds: settings.game.longPressDuration),
          onSelect: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.selectionClick();
            }
            notifier.selectPiece(piece);
          },
          onCycle: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.selectionClick();
            }
            notifier.cycleToNextOrientation();
          },
          onCancel: () {
            if (settings.game.enableHaptics) {
              HapticFeedback.lightImpact();
            }
            notifier.cancelSelection();
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
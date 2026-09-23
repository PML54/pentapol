// Modified: 2026-09-22 16:31 — garder la pièce visible hors plateau quand sa copie est masquée sur le plateau.
// Historique: 2026-09-10 10:13 — feedback visible partagé rack/plateau, entrée et sortie du plateau suivies séparément.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/widgets/piece_renderer.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';

/// État visuel éphémère : ne remplace pas le dernier aperçu valide utilisé au dépôt.
final dragOverBoardProvider = NotifierProvider<DragOverBoardNotifier, bool>(
  DragOverBoardNotifier.new,
);

class DragOverBoardNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) {
    if (state != value) state = value;
  }
}

class PieceDragFeedback extends ConsumerWidget {
  final Pento piece;
  final int positionIndex;
  final double cellSize;
  final Color Function(int) getPieceColor;
  final bool showOverBoard;
  const PieceDragFeedback({
    super.key,
    required this.piece,
    required this.positionIndex,
    required this.cellSize,
    required this.getPieceColor,
    this.showOverBoard = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overBoard = ref.watch(dragOverBoardProvider);
    final valid = ref.watch(pentoscopeProvider.select((s) => s.isPreviewValid));
    // Hors du plateau, aucun fantôme ne prend le relais : conserver la pièce sous le doigt pour
    // éviter une zone aveugle entre le rack et le plateau, particulièrement haute sur iPad.
    if (overBoard && !showOverBoard) return const SizedBox.shrink();
    return PieceRenderer(
      piece: piece,
      positionIndex: positionIndex,
      cellSize: cellSize,
      getPieceColor: getPieceColor,
      isDragging: true,
      invalidPlacement: !overBoard || !valid,
    );
  }
}

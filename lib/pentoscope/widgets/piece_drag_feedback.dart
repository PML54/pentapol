// Modified: 2026-09-10 10:13 — feedback visible partagé rack/plateau, entrée et sortie du plateau suivies séparément.
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
  const PieceDragFeedback({
    super.key,
    required this.piece,
    required this.positionIndex,
    required this.cellSize,
    required this.getPieceColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overBoard = ref.watch(dragOverBoardProvider);
    final valid = ref.watch(pentoscopeProvider.select((s) => s.isPreviewValid));
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

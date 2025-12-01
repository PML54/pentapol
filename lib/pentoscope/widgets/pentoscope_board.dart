// lib/pentoscope/widgets/pentoscope_board.dart
// Plateau de jeu paramétré pour Pentoscope

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_renderer.dart';
import '../pentoscope_provider.dart';

class PentoscopeBoard extends ConsumerWidget {
  final bool isLandscape;

  const PentoscopeBoard({
    super.key,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.read(settingsProvider);

    final puzzle = state.puzzle;
    if (puzzle == null) {
      return const Center(child: Text('Aucun puzzle chargé'));
    }

    final boardWidth = puzzle.size.width;
    final boardHeight = puzzle.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimensions visuelles (swap si paysage)
        final visualCols = isLandscape ? boardHeight : boardWidth;
        final visualRows = isLandscape ? boardWidth : boardHeight;

        final cellSize = (constraints.maxWidth / visualCols)
            .clamp(0.0, constraints.maxHeight / visualRows)
            .toDouble();

        return Center(
          child: Container(
            width: cellSize * visualCols,
            height: cellSize * visualRows,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DragTarget<Pento>(
                onWillAcceptWithDetails: (details) => true,
                onMove: (details) {
                  final offset = (context.findRenderObject() as RenderBox?)
                      ?.globalToLocal(details.offset);

                  if (offset != null) {
                    final visualX = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                    final visualY = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);

                    int logicalX, logicalY;
                    if (isLandscape) {
                      logicalX = (visualRows - 1) - visualY;
                      logicalY = visualX;
                    } else {
                      logicalX = visualX;
                      logicalY = visualY;
                    }

                    notifier.updatePreview(logicalX, logicalY);
                  }
                },
                onLeave: (data) {
                  notifier.clearPreview();
                },
                onAcceptWithDetails: (details) {
                  final offset = (context.findRenderObject() as RenderBox?)
                      ?.globalToLocal(details.offset);

                  if (offset != null) {
                    final visualX = (offset.dx / cellSize).floor().clamp(0, visualCols - 1);
                    final visualY = (offset.dy / cellSize).floor().clamp(0, visualRows - 1);

                    int logicalX, logicalY;
                    if (isLandscape) {
                      logicalX = (visualRows - 1) - visualY;
                      logicalY = visualX;
                    } else {
                      logicalX = visualX;
                      logicalY = visualY;
                    }

                    final success = notifier.tryPlacePiece(logicalX, logicalY);

                    if (success) {
                      HapticFeedback.mediumImpact();
                      // Vérifier victoire
                      final newState = ref.read(pentoscopeProvider);
                      if (newState.isComplete) {
                        _showVictoryDialog(context, ref);
                      }
                    } else {
                      HapticFeedback.heavyImpact();
                    }
                  }

                  notifier.clearPreview();
                },
                builder: (context, candidateData, rejectedData) {
                  final totalCells = boardWidth * boardHeight;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      final visualX = index % visualCols;
                      final visualY = index ~/ visualCols;

                      int logicalX, logicalY;
                      if (isLandscape) {
                        logicalX = (visualRows - 1) - visualY;
                        logicalY = visualX;
                      } else {
                        logicalX = visualX;
                        logicalY = visualY;
                      }

                      return _buildCell(
                        context,
                        ref,
                        state,
                        notifier,
                        settings,
                        logicalX,
                        logicalY,
                        boardWidth,
                        boardHeight,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(
      BuildContext context,
      WidgetRef ref,
      PentoscopeState state,
      PentoscopeNotifier notifier,
      settings,
      int logicalX,
      int logicalY,
      int boardWidth,
      int boardHeight,
      ) {
    // Vérifier les limites
    if (logicalX < 0 || logicalX >= boardWidth || logicalY < 0 || logicalY >= boardHeight) {
      return Container(color: Colors.grey.shade800);
    }

    final cellValue = state.board[logicalY][logicalX];

    Color cellColor;
    String cellText = '';
    bool isOccupied = false;

    if (cellValue == 0) {
      cellColor = Colors.grey.shade300;
    } else {
      cellColor = settings.ui.getPieceColor(cellValue);
      cellText = _pieceName(cellValue);
      isOccupied = true;
    }

    // Preview
    bool isPreview = false;
    bool isPreviewValid = false;

    if (state.selectedPiece != null && state.previewX != null && state.previewY != null) {
      final piece = state.selectedPiece!;
      final shape = piece.positions[state.selectedOrientation];

      final minShapeCell = shape.reduce((a, b) => a < b ? a : b);
      final shapeAnchorX = (minShapeCell - 1) % 5;
      final shapeAnchorY = (minShapeCell - 1) ~/ 5;
      final offsetX = state.previewX! - shapeAnchorX;
      final offsetY = state.previewY! - shapeAnchorY;

      for (final shapeCell in shape) {
        final sx = (shapeCell - 1) % 5;
        final sy = (shapeCell - 1) ~/ 5;
        final px = sx + offsetX;
        final py = sy + offsetY;

        if (px == logicalX && py == logicalY) {
          isPreview = true;
          isPreviewValid = state.isPreviewValid;

          if (isPreviewValid) {
            cellColor = settings.ui.getPieceColor(piece.id).withOpacity(0.5);
          } else {
            cellColor = Colors.red.withOpacity(0.3);
          }
          cellText = _pieceName(piece.id);
          break;
        }
      }
    }

    // Sélection (pièce placée)
    bool isSelected = false;
    if (state.selectedPlacedPieceId != null && cellValue == state.selectedPlacedPieceId) {
      isSelected = true;
    }

    // Bordure
    Border border;
    if (isPreview) {
      border = Border.all(
        color: isPreviewValid ? Colors.green : Colors.red,
        width: 3,
      );
    } else if (isSelected) {
      border = Border.all(color: Colors.amber, width: 3);
    } else {
      border = Border.all(color: Colors.grey.shade400, width: 0.5);
    }

    Widget cellWidget = Container(
      decoration: BoxDecoration(
        color: cellColor,
        border: border,
      ),
      child: Center(
        child: Text(
          cellText,
          style: TextStyle(
            color: isPreview
                ? (isPreviewValid ? Colors.green.shade900 : Colors.red.shade900)
                : Colors.white,
            fontWeight: (isSelected || isPreview) ? FontWeight.w900 : FontWeight.bold,
            fontSize: (isSelected || isPreview) ? 16 : 14,
          ),
        ),
      ),
    );

    // Gestion des taps
    if (isOccupied) {
      cellWidget = GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (isSelected) {
            notifier.deselectPlacedPiece();
          } else {
            notifier.selectPlacedPiece(cellValue);
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          notifier.removePiece(cellValue);
        },
        child: cellWidget,
      );
    } else if (state.selectedPiece != null) {
      cellWidget = GestureDetector(
        onTap: () {
          final success = notifier.tryPlacePiece(logicalX, logicalY);
          if (success) {
            HapticFeedback.mediumImpact();
            final newState = ref.read(pentoscopeProvider);
            if (newState.isComplete) {
              _showVictoryDialog(context, ref);
            }
          } else {
            HapticFeedback.heavyImpact();
          }
        },
        child: cellWidget,
      );
    }

    return cellWidget;
  }

  String _pieceName(int pieceId) {
    const names = ['X', 'P', 'T', 'F', 'Y', 'V', 'U', 'L', 'N', 'W', 'Z', 'I'];
    if (pieceId < 1 || pieceId > 12) return '?';
    return names[pieceId - 1];
  }

  void _showVictoryDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(pentoscopeProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 8),
            Text('Bravo !'),
          ],
        ),
        content: Text(
          'Puzzle ${state.puzzle?.size.label} complété en ${state.moveCount} coups !',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(pentoscopeProvider.notifier).reset();
            },
            child: const Text('Rejouer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Menu'),
          ),
        ],
      ),
    );
  }
}
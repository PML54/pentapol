// lib/pentoscope/widgets/pentoscope_board.dart
// Plateau Pentoscope - calqué sur game_board.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_border_calculator.dart';
import 'package:pentapol/screens/pentomino_game/widgets/shared/piece_renderer.dart';
import '../pentoscope_provider.dart';

class PentoscopeBoard extends ConsumerWidget {
  final bool isLandscape;

  const PentoscopeBoard({
    super.key,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pentoscopeProvider);
    final notifier = ref.read(pentoscopeProvider.notifier);
    final settings = ref.read(settingsProvider);

    final puzzle = state.puzzle;
    if (puzzle == null) {
      return const Center(child: Text('Aucun puzzle'));
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

        final gridWidth = cellSize * visualCols;
        final gridHeight = cellSize * visualRows;

        // Offset du plateau centré
        final offsetX = (constraints.maxWidth - gridWidth) / 2;
        final offsetY = (constraints.maxHeight - gridHeight) / 2;

        // DragTarget englobe TOUT l'espace pour capturer le drag partout
        return DragTarget<Pento>(
          onWillAcceptWithDetails: (details) => true,
          onMove: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;

            final localOffset = renderBox.globalToLocal(details.offset);

            // Coordonnées relatives au plateau centré
            final plateauX = localOffset.dx - offsetX;
            final plateauY = localOffset.dy - offsetY;

            // Hors du plateau ?
            if (plateauX < 0 || plateauX >= gridWidth ||
                plateauY < 0 || plateauY >= gridHeight) {
              notifier.clearPreview();
              return;
            }

            final visualX = (plateauX / cellSize).floor().clamp(0, visualCols - 1);
            final visualY = (plateauY / cellSize).floor().clamp(0, visualRows - 1);

            int logicalX, logicalY;
            if (isLandscape) {
              logicalX = (visualRows - 1) - visualY;
              logicalY = visualX;
            } else {
              logicalX = visualX;
              logicalY = visualY;
            }

            notifier.updatePreview(logicalX, logicalY);
          },
          onLeave: (data) {
            notifier.clearPreview();
          },
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) {
              notifier.clearPreview();
              return;
            }

            final localOffset = renderBox.globalToLocal(details.offset);
            final plateauX = localOffset.dx - offsetX;
            final plateauY = localOffset.dy - offsetY;

            if (plateauX < 0 || plateauX >= gridWidth ||
                plateauY < 0 || plateauY >= gridHeight) {
              notifier.clearPreview();
              return;
            }

            final visualX = (plateauX / cellSize).floor().clamp(0, visualCols - 1);
            final visualY = (plateauY / cellSize).floor().clamp(0, visualRows - 1);

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
              final newState = ref.read(pentoscopeProvider);
              if (newState.isComplete) {
                _showVictoryDialog(context, ref);
              }
            } else {
              HapticFeedback.heavyImpact();
            }

            notifier.clearPreview();
          },
          builder: (context, candidateData, rejectedData) {
            return Center(
              child: Container(
                width: gridWidth,
                height: gridHeight,
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: visualCols,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                    ),
                    itemCount: boardWidth * boardHeight,
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
                        isLandscape,
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
      bool isLandscape,
      ) {
    final cellValue = state.plateau.getCell(logicalX, logicalY);

    Color cellColor;
    String cellText = '';
    bool isOccupied = false;

    if (cellValue == -1) {
      cellColor = Colors.grey.shade800;
    } else if (cellValue == 0) {
      cellColor = Colors.grey.shade300;
    } else {
      cellColor = settings.ui.getPieceColor(cellValue);
      cellText = cellValue.toString();
      isOccupied = true;
    }

    bool isSelected = false;
    bool isReferenceCell = false;
    bool isPreview = false;

    // Pièce placée sélectionnée
    if (state.selectedPlacedPiece != null) {
      final selectedPiece = state.selectedPlacedPiece!;
      final position = selectedPiece.piece.positions[state.selectedPositionIndex];

      // Calculer la normalisation
      final minOffset = _getMinOffset(position);

      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5 - minOffset.$1;
        final localY = (cellNum - 1) ~/ 5 - minOffset.$2;
        final pieceX = selectedPiece.gridX + localX;
        final pieceY = selectedPiece.gridY + localY;

        if (pieceX == logicalX && pieceY == logicalY) {
          isSelected = true;

          if (state.selectedCellInPiece != null) {
            isReferenceCell = (localX == state.selectedCellInPiece!.x &&
                localY == state.selectedCellInPiece!.y);
          }

          if (cellValue == 0) {
            cellColor = settings.ui.getPieceColor(selectedPiece.piece.id);
            cellText = selectedPiece.piece.id.toString();
            isOccupied = true;
          }
          break;
        }
      }
    }

    // Preview
    if (!isSelected &&
        state.selectedPiece != null &&
        state.previewX != null &&
        state.previewY != null) {
      final piece = state.selectedPiece!;
      final position = piece.positions[state.selectedPositionIndex];

      // Calculer la normalisation
      final minOffset = _getMinOffset(position);

      for (final cellNum in position) {
        final localX = (cellNum - 1) % 5 - minOffset.$1;
        final localY = (cellNum - 1) ~/ 5 - minOffset.$2;
        final pieceX = state.previewX! + localX;
        final pieceY = state.previewY! + localY;

        if (pieceX == logicalX && pieceY == logicalY) {
          isPreview = true;
          if (state.isPreviewValid) {
            cellColor = settings.ui.getPieceColor(piece.id).withValues(alpha: 0.4);
          } else {
            cellColor = Colors.red.withValues(alpha: 0.3);
          }
          cellText = piece.id.toString();
          break;
        }
      }
    }

    // Bordure
    Border border;
    if (isReferenceCell) {
      border = Border.all(color: Colors.red, width: 4);
    } else if (isPreview) {
      border = Border.all(
        color: state.isPreviewValid ? Colors.green : Colors.red,
        width: 3,
      );
    } else if (isSelected) {
      border = Border.all(color: Colors.amber, width: 3);
    } else {
      // Utiliser PieceBorderCalculator pour les bordures fusionnées
      border = PieceBorderCalculator.calculate(
          logicalX, logicalY, state.plateau, isLandscape);
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
                ? (state.isPreviewValid ? Colors.green.shade900 : Colors.red.shade900)
                : Colors.white,
            fontWeight: (isSelected || isPreview) ? FontWeight.w900 : FontWeight.bold,
            fontSize: (isSelected || isPreview) ? 16 : 14,
          ),
        ),
      ),
    );

    // Pièce sélectionnée : draggable
    if (isSelected && state.selectedPiece != null) {
      cellWidget = Draggable<Pento>(
        data: state.selectedPiece!,
        feedback: Material(
          color: Colors.transparent,
          child: PieceRenderer(
            piece: state.selectedPiece!,
            positionIndex: state.selectedPositionIndex,
            isDragging: true,
            getPieceColor: (pieceId) => settings.ui.getPieceColor(pieceId),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: cellWidget,
        ),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.selectPlacedPiece(state.selectedPlacedPiece!, logicalX, logicalY);
          },
          onDoubleTap: () {
            HapticFeedback.selectionClick();
            notifier.applyIsometryRotation();
          },
          child: cellWidget,
        ),
      );
    } else if (isOccupied && !isSelected) {
      // Pièce placée non sélectionnée : sélectionnable
      cellWidget = GestureDetector(
        onTap: () {
          final piece = notifier.getPlacedPieceAt(logicalX, logicalY);
          if (piece != null) {
            HapticFeedback.selectionClick();
            notifier.selectPlacedPiece(piece, logicalX, logicalY);
          }
        },
        child: cellWidget,
      );
    } else if (!isOccupied && state.selectedPiece != null && cellValue == 0) {
      // Case vide avec pièce sélectionnée : annuler sélection
      cellWidget = GestureDetector(
        onTap: () {
          notifier.cancelSelection();
        },
        child: cellWidget,
      );
    }

    return cellWidget;
  }

  /// Calcule le décalage minimum pour normaliser une forme
  (int, int) _getMinOffset(List<int> position) {
    int minX = 5, minY = 5;
    for (final cellNum in position) {
      final localX = (cellNum - 1) % 5;
      final localY = (cellNum - 1) ~/ 5;
      if (localX < minX) minX = localX;
      if (localY < minY) minY = localY;
    }
    return (minX, minY);
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
// 251206 1600
// Version: Claude V2
// lib/duel_isometry/widgets/duel_isometry_plateau.dart
// Plateau partagé avec solution + cellules coloriées

import 'package:flutter/material.dart';
import 'package:pentapol/models/plateau.dart';
import 'package:pentapol/duel_isometry/services/duel_isometry_validator.dart';

typedef OnCellTapped = void Function(int x, int y);

/// Plateau partagé pour Duel Isométries
class DuelIsometryPlateau extends StatefulWidget {
  final Plateau solutionPlateau;
  final Map<int, ({int x, int y, int orientation})> myPlacedPieces;
  final Map<int, ({int x, int y, int orientation})> opponentPlacedPieces;
  final int? previewPieceId;
  final int? previewOrientation;
  final ValidationResult? previewValidation;
  final OnCellTapped? onCellTapped;
  final Color myPlacedColor;
  final Color opponentPlacedColor;
  final Color solutionColor;
  final bool isEnabled;

  const DuelIsometryPlateau({
    super.key,
    required this.solutionPlateau,
    required this.myPlacedPieces,
    required this.opponentPlacedPieces,
    this.previewPieceId,
    this.previewOrientation,
    this.previewValidation,
    this.onCellTapped,
    this.myPlacedColor = Colors.blue,
    this.opponentPlacedColor = Colors.red,
    this.solutionColor = Colors.grey,
    this.isEnabled = true,
  });

  @override
  State<DuelIsometryPlateau> createState() => _DuelIsometryPlateauState();
}

class _DuelIsometryPlateauState extends State<DuelIsometryPlateau> {
  int? _hoverX;
  int? _hoverY;

  Color _getBorderColor(int pieceId) {
    bool myPlace = false;
    bool opponentPlace = false;

    for (final entry in widget.myPlacedPieces.entries) {
      if (entry.key == pieceId) {
        myPlace = true;
        break;
      }
    }

    for (final entry in widget.opponentPlacedPieces.entries) {
      if (entry.key == pieceId) {
        opponentPlace = true;
        break;
      }
    }

    if (myPlace && opponentPlace) {
      return Colors.black;
    } else if (myPlace) {
      return widget.myPlacedColor;
    } else if (opponentPlace) {
      return widget.opponentPlacedColor;
    }
    return Colors.grey;
  }

  Color _getCellColor(int x, int y) {
    int? pieceAtCell;

    for (final entry in widget.myPlacedPieces.entries) {
      final placement = entry.value;
      if (_isCellInPiece(x, y, entry.key, placement.orientation)) {
        pieceAtCell = entry.key;
        break;
      }
    }

    if (pieceAtCell == null) {
      for (final entry in widget.opponentPlacedPieces.entries) {
        final placement = entry.value;
        if (_isCellInPiece(x, y, entry.key, placement.orientation)) {
          pieceAtCell = entry.key;
          break;
        }
      }
    }

    if (pieceAtCell != null) {
      return Colors.white;
    }

    if (widget.solutionPlateau.getCell(x, y) > 0) {
      return widget.solutionColor.withOpacity(0.15);
    }

    return Colors.white;
  }

  bool _isCellInPiece(
      int cellX,
      int cellY,
      int pieceId,
      int orientation,
      ) {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.solutionPlateau.width;
    final height = widget.solutionPlateau.height;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width,
              childAspectRatio: 1,
            ),
            itemCount: width * height,
            itemBuilder: (context, index) {
              final x = index % width;
              final y = index ~/ width;
              final isHover = _hoverX == x && _hoverY == y;
              final cellColor = _getCellColor(x, y);

              return MouseRegion(
                onEnter: (_) => setState(() {
                  _hoverX = x;
                  _hoverY = y;
                }),
                onExit: (_) => setState(() {
                  _hoverX = null;
                  _hoverY = null;
                }),
                child: GestureDetector(
                  onTap: widget.isEnabled
                      ? () => widget.onCellTapped?.call(x, y)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cellColor,
                      border: Border.all(
                        color: isHover ? Colors.purple : Colors.grey.shade300,
                        width: isHover ? 2 : 1,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
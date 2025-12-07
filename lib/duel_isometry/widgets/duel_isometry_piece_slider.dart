// 251206 1730
// Version: Claude V2 Final
// lib/duel_isometry/widgets/duel_isometry_piece_slider.dart
// Slider des 12 pièces avec rotation & isométries

import 'package:flutter/material.dart';
import 'package:pentapol/duel_isometry/services/duel_isometry_validator.dart';
import 'package:pentapol/models/pentominos.dart';

typedef OnPieceSelected = void Function(int pieceId, int orientation);

class DuelIsometryPieceSlider extends StatefulWidget {
  final Map<int, ({int x, int y, int orientation})> myPlacedPieces;
  final Map<int, ({int x, int y, int orientation})> opponentPlacedPieces;
  final int? selectedPieceId;
  final OnPieceSelected? onPieceSelected;
  final Color myPlacedColor;
  final Color opponentPlacedColor;
  final Color selectedBorderColor;
  final bool isEnabled;

  const DuelIsometryPieceSlider({
    super.key,
    required this.myPlacedPieces,
    required this.opponentPlacedPieces,
    this.selectedPieceId,
    this.onPieceSelected,
    this.myPlacedColor = Colors.blue,
    this.opponentPlacedColor = Colors.red,
    this.selectedBorderColor = Colors.purple,
    this.isEnabled = true,
  });

  @override
  State<DuelIsometryPieceSlider> createState() =>
      _DuelIsometryPieceSliderState();
}

class _DuelIsometryPieceSliderState extends State<DuelIsometryPieceSlider> {
  late Map<int, int> pieceOrientations;

  @override
  void initState() {
    super.initState();
    pieceOrientations = {for (int i = 1; i <= 12; i++) i: 0};
  }

  void _rotateSelected() {
    if (widget.selectedPieceId == null) return;
    if (!widget.isEnabled) return;

    final pieceId = widget.selectedPieceId!;
    final piece = pentominos[pieceId - 1];
    final currentOrientation = pieceOrientations[pieceId] ?? 0;
    final nextOrientation = (currentOrientation + 1) % piece.numPositions;

    setState(() {
      pieceOrientations[pieceId] = nextOrientation;
    });

    widget.onPieceSelected?.call(pieceId, nextOrientation);
  }

  Color _getPieceBackground(int pieceId) {
    final isMyPlaced = widget.myPlacedPieces.containsKey(pieceId);
    final isOpponentPlaced = widget.opponentPlacedPieces.containsKey(pieceId);

    if (isMyPlaced && isOpponentPlaced) {
      return Color.lerp(widget.myPlacedColor, widget.opponentPlacedColor, 0.5) ??
          Colors.grey;
    } else if (isMyPlaced) {
      return widget.myPlacedColor.withValues(alpha: 0.3);
    } else if (isOpponentPlaced) {
      return widget.opponentPlacedColor.withValues(alpha: 0.3);
    }
    return Colors.grey.shade100;
  }

  Color _getPieceBorder(int pieceId) {
    final isMyPlaced = widget.myPlacedPieces.containsKey(pieceId);
    final isOpponentPlaced = widget.opponentPlacedPieces.containsKey(pieceId);

    if (isMyPlaced && isOpponentPlaced) {
      return Colors.black;
    } else if (isMyPlaced) {
      return widget.myPlacedColor;
    } else if (isOpponentPlaced) {
      return widget.opponentPlacedColor;
    }
    return Colors.grey;
  }

  Widget _buildPieceCard(int pieceId) {
    final isSelected = widget.selectedPieceId == pieceId;
    final orientation = pieceOrientations[pieceId] ?? 0;
    final isometries = DuelIsometryValidator.countIsometries(pieceId, orientation);
    final isMyPlaced = widget.myPlacedPieces.containsKey(pieceId);
    final isOpponentPlaced = widget.opponentPlacedPieces.containsKey(pieceId);

    return GestureDetector(
      onTap: widget.isEnabled
          ? () {
        setState(() {
          if (widget.selectedPieceId != pieceId) {
            widget.onPieceSelected?.call(pieceId, orientation);
          }
        });
      }
          : null,
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? widget.selectedBorderColor
                : _getPieceBorder(pieceId),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _getPieceBackground(pieceId),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$pieceId',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'O$orientation',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '±$isometries',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (isMyPlaced || isOpponentPlaced)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isMyPlaced)
                      Icon(Icons.check_circle,
                          size: 10, color: widget.myPlacedColor),
                    if (isMyPlaced && isOpponentPlaced)
                      const SizedBox(width: 2),
                    if (isOpponentPlaced)
                      Icon(Icons.person,
                          size: 10, color: widget.opponentPlacedColor),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('⚙️ DuelIsometryPieceSlider.build');
    const cardsPerRow = 6;

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Pièces 1-6
            SizedBox(
              height: 100,
              child: GridView.count(
                crossAxisCount: cardsPerRow,
                childAspectRatio: 0.9,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(6, (i) => _buildPieceCard(i + 1)),
              ),
            ),
            const SizedBox(height: 4),

            // Row 2: Pièces 7-12
            SizedBox(
              height: 100,
              child: GridView.count(
                crossAxisCount: cardsPerRow,
                childAspectRatio: 0.9,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(6, (i) => _buildPieceCard(i + 7)),
              ),
            ),

            // Controls: Bouton Tourner
            if (widget.selectedPieceId != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.isEnabled ? _rotateSelected : null,
                    icon: const Icon(Icons.rotate_right),
                    label: const Text('Tourner'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
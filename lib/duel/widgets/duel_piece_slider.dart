// lib/duel/widgets/duel_piece_slider.dart
// Slider des pièces pour le mode duel

import 'package:flutter/material.dart';

class DuelPieceSlider extends StatelessWidget {
  final List<int> availablePieces;   // Pièces disponibles (pas encore placées)
  final List<int> myPlacedPieces;    // Pièces que j'ai placées
  final List<int> opponentPieces;    // Pièces placées par l'adversaire
  final int? selectedPiece;
  final ValueChanged<int> onPieceSelected;
  final VoidCallback? onRotate;

  const DuelPieceSlider({
    super.key,
    required this.availablePieces,
    required this.myPlacedPieces,
    required this.opponentPieces,
    this.selectedPiece,
    required this.onPieceSelected,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implémenter le slider
    // - Pièces disponibles : normales, sélectionnables
    // - Mes pièces placées : vertes, non sélectionnables
    // - Pièces adversaire : rouges/grisées, non sélectionnables
    return Container(
      height: 100,
      color: Colors.grey[300],
      child: const Center(
        child: Text('TODO: Slider des pièces'),
      ),
    );
  }
}

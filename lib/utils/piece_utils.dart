// Modified: 2026-08-31 16:39 — table de lettres unique (REFERENCE_TIRAGES §10) : la table
//           `pieceNames` (entièrement périmée : pièce 2 = « I » alors qu'elle a 8 orientations) et
//           `getPieceName` sont retirées ; les lettres viennent de pentominos.pentominoLetter.
// lib/utils/piece_utils.dart
// Historique: 2025-11-16 11:00:00 — Utilitaires communs pour les pièces de pentominos

import 'package:flutter/material.dart';
import 'package:pentapol/common/pentominos.dart';

/// Couleurs par défaut des pièces (schéma classique)
const List<Color> defaultPieceColors = [
  Color(0xFFE57373), // 1 - Rouge
  Color(0xFF81C784), // 2 - Vert
  Color(0xFF64B5F6), // 3 - Bleu
  Color(0xFFFFD54F), // 4 - Jaune
  Color(0xFFBA68C8), // 5 - Violet
  Color(0xFFFF8A65), // 6 - Orange
  Color(0xFF4DB6AC), // 7 - Turquoise
  Color(0xFFA1887F), // 8 - Marron
  Color(0xFF90A4AE), // 9 - Gris-bleu
  Color(0xFFF06292), // 10 - Rose
  Color(0xFF9575CD), // 11 - Violet clair
  Color(0xFF4DD0E1), // 12 - Cyan
];

/// Obtenir la couleur par défaut d'une pièce
Color getDefaultPieceColor(int pieceId) {
  if (pieceId >= 1 && pieceId <= 12) {
    return defaultPieceColors[pieceId - 1];
  }
  return Colors.grey;
}

/// Widget pour afficher l'aperçu d'une pièce
class PiecePreview extends StatelessWidget {
  final Pento piece;
  final Color color;
  final double cellSize;
  final bool showBorder;
  
  const PiecePreview({
    super.key,
    required this.piece,
    required this.color,
    this.cellSize = 12.0,
    this.showBorder = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final baseShape = piece.baseShape;
    
    // Calculer les coordonnées min/max
    int minX = 4, maxX = 0, minY = 4, maxY = 0;
    for (final cellNum in baseShape) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    
    final width = maxX - minX + 1;
    final height = maxY - minY + 1;
    
    return SizedBox(
      width: width * cellSize,
      height: height * cellSize,
      child: Stack(
        children: baseShape.map((cellNum) {
          final x = (cellNum - 1) % 5;
          final y = (cellNum - 1) ~/ 5;
          return Positioned(
            left: (x - minX) * cellSize,
            top: (y - minY) * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.7),
                border: showBorder ? Border.all(color: Colors.white, width: 1) : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget pour afficher une pièce avec sa lettre
class PieceIcon extends StatelessWidget {
  final int pieceId;
  final Color color;
  final double size;
  final bool showBorder;
  
  const PieceIcon({
    super.key,
    required this.pieceId,
    required this.color,
    this.size = 50.0,
    this.showBorder = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final pieceName = pentominoLetter(pieceId);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: showBorder ? Border.all(color: Colors.grey.shade400, width: 2) : null,
      ),
      child: Center(
        child: Text(
          pieceName,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Obtenir le code couleur hexadécimal d'une couleur
String getColorHex(Color color) {
  final argb = color.value.toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}

/// Palette de couleurs prédéfinies pour le sélecteur
List<Color> getPredefinedColors() {
  return [
    // Rouges
    Colors.red.shade900,
    Colors.red.shade700,
    Colors.red.shade500,
    Colors.red.shade300,
    // Roses
    Colors.pink.shade700,
    Colors.pink.shade500,
    Colors.pink.shade300,
    // Violets
    Colors.purple.shade700,
    Colors.purple.shade500,
    Colors.purple.shade300,
    Colors.deepPurple.shade700,
    Colors.deepPurple.shade500,
    // Bleus
    Colors.indigo.shade700,
    Colors.indigo.shade500,
    Colors.blue.shade700,
    Colors.blue.shade500,
    Colors.blue.shade300,
    Colors.lightBlue.shade700,
    Colors.lightBlue.shade500,
    // Cyans
    Colors.cyan.shade700,
    Colors.cyan.shade500,
    Colors.teal.shade700,
    Colors.teal.shade500,
    // Verts
    Colors.green.shade900,
    Colors.green.shade700,
    Colors.green.shade500,
    Colors.green.shade300,
    Colors.lightGreen.shade700,
    Colors.lightGreen.shade500,
    Colors.lime.shade700,
    Colors.lime.shade500,
    // Jaunes
    Colors.yellow.shade700,
    Colors.yellow.shade500,
    Colors.amber.shade700,
    Colors.amber.shade500,
    // Oranges
    Colors.orange.shade700,
    Colors.orange.shade500,
    Colors.deepOrange.shade700,
    Colors.deepOrange.shade500,
    // Marrons
    Colors.brown.shade700,
    Colors.brown.shade500,
    Colors.brown.shade300,
    // Gris
    Colors.grey.shade900,
    Colors.grey.shade700,
    Colors.grey.shade500,
    Colors.grey.shade300,
    Colors.blueGrey.shade700,
    Colors.blueGrey.shade500,
    // Noir et blanc
    Colors.black,
    Colors.white,
  ];
}


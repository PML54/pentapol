// lib/duel/widgets/opponent_piece_overlay.dart
// Overlay de hachures pour les pièces de l'adversaire

import 'package:flutter/material.dart';

/// Widget qui affiche des hachures sur une pièce adverse
class OpponentPieceOverlay extends StatelessWidget {
  final Widget child;
  final Color hatchColor;
  final double hatchWidth;
  final double hatchSpacing;

  const OpponentPieceOverlay({
    super.key,
    required this.child,
    this.hatchColor = Colors.black,
    this.hatchWidth = 2.0,
    this.hatchSpacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: CustomPaint(
            painter: _HatchPainter(
              color: hatchColor.withOpacity(0.3),
              strokeWidth: hatchWidth,
              spacing: hatchSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner des hachures diagonales
class _HatchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double spacing;

  _HatchPainter({
    required this.color,
    required this.strokeWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Dessiner des lignes diagonales (haut-gauche vers bas-droite)
    final maxDimension = size.width + size.height;

    for (double i = -maxDimension; i < maxDimension; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.spacing != spacing;
  }
}

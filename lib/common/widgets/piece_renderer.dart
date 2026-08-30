// Modified: 2026-08-30 13:50 — PLAN_ERGONOMIE §6 étape 4 : le numéro (badge) sur la pièce suit
//           cellSize (× 0.55, ≈ 12 au défaut 22) au lieu d'une taille fixe.
// lib/common/widgets/piece_renderer.dart
// Historique: 2026-08-30 13:30 — étape 1 : cellSize devient un paramètre (défaut 22.0), additif.
// Historique: 2026-08-29 13:43 — déménagé de l'ancien dossier du mode classique vers
//             lib/common/widgets/ : partagé par Pentoscope et le multijoueur.
// Widget pour afficher visuellement une pièce de pentomino

import 'package:flutter/material.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/game_colors.dart';

/// Widget qui affiche une pièce de pentomino
/// 
/// Utilisé dans :
/// - Le slider de pièces
/// - Le feedback de drag
/// - Partout où on doit afficher une pièce
class PieceRenderer extends StatelessWidget {
  final Pento piece;
  final int positionIndex;
  final bool isDragging;
  final Color Function(int pieceId) getPieceColor;

  /// Taille d'une case de la pièce, en points. Défaut 22 : le rendu reste identique
  /// pour tout appelant qui ne le précise pas (changement additif, PLAN_ERGONOMIE §4a).
  final double cellSize;

  const PieceRenderer({
    super.key,
    required this.piece,
    required this.positionIndex,
    this.isDragging = false,
    required this.getPieceColor,
    this.cellSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final position = piece.orientations[positionIndex];

    // Convertir les cellNum (1-25) en coordonnées (x, y)
    final coords = position.map((cellNum) {
      final x = (cellNum - 1) % 5;
      final y = (cellNum - 1) ~/ 5;
      return {'x': x, 'y': y};
    }).toList();

    // Calculer les dimensions de la pièce
    int minX = coords[0]['x']!;
    int maxX = coords[0]['x']!;
    int minY = coords[0]['y']!;
    int maxY = coords[0]['y']!;

    for (final coord in coords) {
      final x = coord['x']!;
      final y = coord['y']!;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final width = maxX - minX + 1;
    final height = maxY - minY + 1;

    return Container(
      width: width * cellSize + 8,
      height: height * cellSize + 8,
      decoration: BoxDecoration(
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: GameColors.draggingShadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Les 5 carrés de la pièce
          for (final coord in coords)
            Positioned(
              left: (coord['x']! - minX) * cellSize + 4,
              top: (coord['y']! - minY) * cellSize + 4,
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: getPieceColor(piece.id),
                  border: Border.all(color: GameColors.pieceInnerBorderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.shadowColorDark,
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                // Numéro de la pièce sur le premier carré
                child: coord == coords.first
                    ? Center(
                        child: Text(
                          piece.id.toString(),
                          style: TextStyle(
                            color: GameColors.pieceTextColor,
                            // Badge proportionnel à la case (§4e) ; ≈ 12 au défaut cellSize 22.
                            fontSize: cellSize * 0.55,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}


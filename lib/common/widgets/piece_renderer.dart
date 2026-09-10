// Modified: 2026-09-10 10:13 — feedback invalide visible : remplissage atténué et contour rouge de la silhouette.
// Historique: 2026-09-02 16:46 — paramètre showLabel (défaut true) : masque le numéro de la pièce ;
//           l'écran d'accueil l'utilise à false (pièces nues). Additif, jeu/duel inchangés.
// lib/common/widgets/piece_renderer.dart
// Historique: 2026-08-30 13:50 — PLAN_ERGONOMIE §6 étape 4 : le numéro (badge) sur la pièce suit
//           cellSize (× 0.55, ≈ 12 au défaut 22) au lieu d'une taille fixe.
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

  /// Feedback de dépôt interdit : couleur conservée, remplissage atténué et contour rouge.
  final bool invalidPlacement;
  final Color Function(int pieceId) getPieceColor;

  /// Taille d'une case de la pièce, en points. Défaut 22 : le rendu reste identique
  /// pour tout appelant qui ne le précise pas (changement additif, PLAN_ERGONOMIE §4a).
  final double cellSize;

  /// Affiche le numéro de la pièce sur la première case. Défaut `true` : inchangé pour le jeu
  /// et le duel. L'écran d'accueil le met à `false` (pièces nues — PLAN_ECRAN_ACCUEIL §1).
  final bool showLabel;

  const PieceRenderer({
    super.key,
    required this.piece,
    required this.positionIndex,
    this.isDragging = false,
    this.invalidPlacement = false,
    required this.getPieceColor,
    this.cellSize = 22.0,
    this.showLabel = true,
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
                  color: invalidPlacement
                      ? getPieceColor(piece.id).withValues(alpha: 0.55)
                      : getPieceColor(piece.id),
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
                // Numéro de la pièce sur le premier carré (masquable : accueil sans numéros)
                child: (showLabel && coord == coords.first)
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
          if (invalidPlacement)
            Positioned.fill(child: IgnorePointer(child: CustomPaint(
              painter: _InvalidOutline(position: position, cellSize: cellSize),
            ))),
        ],
      ),
    );
  }
}

/// Trace seulement les arêtes extérieures, afin de conserver la silhouette de la pièce.
class _InvalidOutline extends CustomPainter {
  final List<int> position;
  final double cellSize;
  const _InvalidOutline({required this.position, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cells = position.map((n) => ((n - 1) % 5, (n - 1) ~/ 5)).toSet();
    final minX = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minY = cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    final path = Path();
    for (final (x, y) in cells) {
      final left = 4 + (x - minX) * cellSize;
      final top = 4 + (y - minY) * cellSize;
      final right = left + cellSize;
      final bottom = top + cellSize;
      if (!cells.contains((x, y - 1))) { path.moveTo(left, top); path.lineTo(right, top); }
      if (!cells.contains((x, y + 1))) { path.moveTo(left, bottom); path.lineTo(right, bottom); }
      if (!cells.contains((x - 1, y))) { path.moveTo(left, top); path.lineTo(left, bottom); }
      if (!cells.contains((x + 1, y))) { path.moveTo(right, top); path.lineTo(right, bottom); }
    }
    // Sous-trait blanc : contour lisible aussi sur les pièces rouges et les fonds sombres.
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawPath(path, Paint()..color = Colors.red.shade700..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _InvalidOutline oldDelegate) =>
      oldDelegate.position != position || oldDelegate.cellSize != cellSize;
}

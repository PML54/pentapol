// Modified: 2026-09-23 07:03 — suivre la rotation antihoraire du plateau en paysage.
// Historique: 2026-09-23 05:48 — adapter le découpage à toutes les dimensions de plateau.
// Historique: 2026-09-23 05:32 — recevoir la solution-image fixée au démarrage de la partie.
// Historique: 2026-09-23 05:13 — prototype 6×10 : découper une image par cellules de pentominos.
// lib/pentoscope/widgets/illustrated_piece_cells.dart

import 'package:flutter/material.dart';

import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/point.dart';

const String kIllustratedPuzzleAsset =
    'assets/images/pentapol_puzzle_landscape_3x5.png';

/// Le plateau logique pivote de 90° vers la gauche en paysage.
const int kIllustratedLandscapeQuarterTurns = 3;

/// Découpage stable de l'image selon la première solution 6×10 de référence.
///
/// Pour chaque pièce, l'ordre des cinq coordonnées est celui de `Pento.orientations`.
/// Cet ordre est conservé par les isométries : un fragment suit donc sa cellule quand
/// la pièce tourne, se retourne ou se déplace.
class IllustratedPuzzleLayout {
  final Map<int, List<Point>> sourceCellsByPiece;
  final int boardWidth;
  final int boardHeight;

  const IllustratedPuzzleLayout(
    this.sourceCellsByPiece, {
    required this.boardWidth,
    required this.boardHeight,
  });

  factory IllustratedPuzzleLayout.fromSolution(
    List<PlacedPiece> solution, {
    required int boardWidth,
    required int boardHeight,
  }) {
    return IllustratedPuzzleLayout(
      {
        for (final placed in solution)
          placed.piece.id: placed.absoluteCells.toList(growable: false),
      },
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
  }

  List<Point>? cellsForPiece(int pieceId) => sourceCellsByPiece[pieceId];
}

/// Affiche la case [sourceCell] de l'image 6×10 à la taille de la case courante.
class IllustratedPuzzleCell extends StatelessWidget {
  final Point sourceCell;
  final double cellSize;
  final int boardWidth;
  final int boardHeight;
  final int quarterTurns;
  final double opacity;

  const IllustratedPuzzleCell({
    super.key,
    required this.sourceCell,
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
    this.quarterTurns = 0,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final fragment = SizedBox(
      width: cellSize,
      height: cellSize,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: cellSize * boardWidth,
          maxWidth: cellSize * boardWidth,
          minHeight: cellSize * boardHeight,
          maxHeight: cellSize * boardHeight,
          child: Transform.translate(
            offset: Offset(-sourceCell.x * cellSize, -sourceCell.y * cellSize),
            child: Image.asset(
              kIllustratedPuzzleAsset,
              width: cellSize * boardWidth,
              height: cellSize * boardHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: opacity,
      child: quarterTurns == 0
          ? fragment
          : RotatedBox(quarterTurns: quarterTurns, child: fragment),
    );
  }
}

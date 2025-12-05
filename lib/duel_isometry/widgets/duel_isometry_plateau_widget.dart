// lib/duel_isometry/widgets/duel_isometry_plateau_widget.dart

import 'package:flutter/material.dart';
import 'package:pentapol/models/plateau.dart';

class DuelIsometryPlateauWidget extends StatelessWidget {
  final Plateau plateau;

  const DuelIsometryPlateauWidget({
    required this.plateau,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${plateau.width}x${plateau.height}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: plateau.width,
                childAspectRatio: 1,
              ),
              itemCount: plateau.width * plateau.height,
              itemBuilder: (context, index) {
                final x = index % plateau.width;
                final y = index ~/ plateau.width;
                final pieceId = plateau.getCell(x, y);

                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: pieceId == 0
                        ? Colors.white
                        : _getColorForPiece(pieceId),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: pieceId > 0
                      ? Center(
                          child: Text(
                            '$pieceId',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPiece(int pieceId) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
      Colors.cyan, Colors.indigo, Colors.lime, Colors.brown,
    ];
    return colors[(pieceId - 1) % colors.length];
  }
}

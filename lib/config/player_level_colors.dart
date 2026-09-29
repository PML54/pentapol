// Modified: 2026-09-29 06:05 — définir une couleur distincte et visible pour chacun des neuf niveaux.
// lib/config/player_level_colors.dart

import 'package:flutter/material.dart';

const List<Color> playerLevelColors = [
  Color(0xFF1565C0), // 1 — bleu
  Color(0xFF0088A3), // 2 — cyan
  Color(0xFF00897B), // 3 — turquoise
  Color(0xFF2E7D32), // 4 — vert
  Color(0xFF7A8F00), // 5 — jaune-vert
  Color(0xFFC58B00), // 6 — ambre
  Color(0xFFE66A00), // 7 — orange
  Color(0xFFC62828), // 8 — rouge
  Color(0xFF7B1FA2), // 9 — violet
];

Color playerLevelColor(int level) =>
    playerLevelColors[(level - 1).clamp(0, playerLevelColors.length - 1)];

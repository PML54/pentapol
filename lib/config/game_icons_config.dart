// lib/config/game_icons_config.dart
// Configuration centralisée des icônes de l'application

import 'package:flutter/material.dart';

/// Modes de jeu
enum GameMode {
  normal,      // Mode jeu normal
  isometries,  // Mode isométries
}

/// Configuration d'une icône avec ses propriétés
class GameIconConfig {
  final IconData icon;
  final String tooltip;
  final Color color;
  final List<GameMode> visibleInModes; // Dans quels modes l'icône est visible
  final String description;

  const GameIconConfig({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.visibleInModes,
    required this.description,
  });

  /// Vérifie si l'icône est visible dans un mode donné
  bool isVisibleIn(GameMode mode) => visibleInModes.contains(mode);
}

/// Catalogue complet des icônes de l'application
class GameIcons {
  // ==================== NAVIGATION ====================

  /// Paramètres de l'application
  static const settings = GameIconConfig(
    icon: Icons.settings,
    tooltip: 'Paramètres',
    color: Colors.white,
    visibleInModes: [GameMode.normal, GameMode.isometries],
    description: 'Ouvre l\'écran des paramètres',
  );

  /// Mode Isométries (depuis mode normal)
  static const enterIsometries = GameIconConfig(
    icon: Icons.school,
    tooltip: 'Mode Isométries',
    color: Color(0xFFAB47BC), // Colors.purple[400]
    visibleInModes: [GameMode.normal],
    description: 'Passe en mode isométries (sauvegarde l\'état actuel)',
  );

  /// Retour au jeu (depuis mode isométries)
  static const exitIsometries = GameIconConfig(
    icon: Icons.emoji_events, // 🏆 Coupe/Trophée pour "retour au jeu"
    tooltip: 'Retour au Jeu',
    color: Color(0xFFAB47BC), // Colors.purple[400]
    visibleInModes: [GameMode.isometries],
    description: 'Quitte le mode isométries et restaure l\'état du jeu',
  );

  // ==================== JEU NORMAL ====================

  /// Voir les solutions possibles
  static const viewSolutions = GameIconConfig(
    icon: Icons.visibility,
    tooltip: 'Voir les solutions possibles',
    color: Color(0xFF42A5F5), // Colors.blue[400]
    visibleInModes: [GameMode.normal],
    description: 'Affiche les solutions compatibles avec l\'état actuel',
  );

  /// Indicateur de solutions (coupe/trophée)
  static const solutionsCounter = GameIconConfig(
    icon: Icons.emoji_events,
    tooltip: 'Nombre de solutions',
    color: Colors.green, // Dynamique selon le nombre
    visibleInModes: [GameMode.normal],
    description: 'Affiche le nombre de solutions possibles',
  );

  /// Rotation de pièce (en jeu normal)
  static const rotatePiece = GameIconConfig(
    icon: Icons.rotate_right,
    tooltip: 'Rotation',
    color: Color(0xFF42A5F5), // Colors.blue[400]
    visibleInModes: [GameMode.normal],
    description: 'Fait pivoter la pièce sélectionnée',
  );

  /// Retirer une pièce du plateau
  static const removePiece = GameIconConfig(
    icon: Icons.delete_outline,
    tooltip: 'Retirer',
    color: Color(0xFFE53935), // Colors.red[600]
    visibleInModes: [GameMode.normal],
    description: 'Retire la pièce sélectionnée du plateau',
  );

  /// Annuler le dernier placement
  static const undo = GameIconConfig(
    icon: Icons.undo,
    tooltip: 'Annuler',
    color: Colors.white70,
    visibleInModes: [GameMode.normal],
    description: 'Annule le dernier placement de pièce',
  );

  // ==================== ISOMÉTRIES ====================

  /// Rotation 90° anti-horaire (transformation isométrique)
  static const isometryRotation = GameIconConfig(
    icon: Icons.rotate_right,
    tooltip: 'Rotation 90° ↺',
    color: Color(0xFFFFA726), // Colors.orange[400]
    visibleInModes: [GameMode.normal, GameMode.isometries],
    description: 'Applique une rotation de 90° anti-horaire à la pièce',
  );

  /// Rotation 90° horaire (transformation isométrique)
  static const isometryRotationCW = GameIconConfig(
    icon: Icons.rotate_left,
    tooltip: 'Rotation 90° ↻',
    color: Color(0xFFFF7043), // Colors.deepOrange[400]
    visibleInModes: [GameMode.normal, GameMode.isometries],
    description: 'Applique une rotation de 90° horaire à la pièce',
  );

  /// Symétrie horizontale
  static const isometrySymmetryH = GameIconConfig(
    icon: Icons.swap_horiz,
    tooltip: 'Symétrie Horizontale',
    color: Color(0xFF42A5F5), // Colors.blue[400]
    visibleInModes: [GameMode.isometries],
    description: 'Applique une symétrie selon l\'axe horizontal',
  );

  /// Symétrie verticale
  static const isometrySymmetryV = GameIconConfig(
    icon: Icons.swap_vert,
    tooltip: 'Symétrie Verticale',
    color: Color(0xFF66BB6A), // Colors.green[400]
    visibleInModes: [GameMode.isometries],
    description: 'Applique une symétrie selon l\'axe vertical',
  );

  /// Retirer une pièce (en mode isométries)
  static const isometryDelete = GameIconConfig(
    icon: Icons.delete_outline,
    tooltip: 'Retirer',
    color: Color(0xFFE53935), // Colors.red[600]
    visibleInModes: [GameMode.isometries],
    description: 'Retire la pièce sélectionnée du plateau',
  );

  // ==================== HELPERS ====================

  /// Retourne toutes les icônes pour un mode donné
  static List<GameIconConfig> getIconsForMode(GameMode mode) {
    return [
      settings,
      enterIsometries,
      exitIsometries,
      viewSolutions,
      solutionsCounter,
      rotatePiece,
      removePiece,
      undo,
      isometryRotation,
      isometryRotationCW,
      isometrySymmetryH,
      isometrySymmetryV,
      isometryDelete,
    ].where((icon) => icon.isVisibleIn(mode)).toList();
  }

  /// Affiche la liste des icônes dans la console (debug)
  static void printIconsForMode(GameMode mode) {
    print('\n📋 Icônes visibles en mode ${mode.name}:');
    print('─' * 60);
    for (final icon in getIconsForMode(mode)) {
      print('${icon.icon.codePoint.toRadixString(16).padLeft(4, '0')} '
          '│ ${icon.tooltip.padRight(25)} │ ${icon.description}');
    }
    print('─' * 60);
  }
}
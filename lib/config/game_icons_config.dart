// Modified: 2026-09-02 11:03 — ajout de isometryIconSize(context) : taille partagée des icônes
//           d'isométrie (solo + duel), portrait — retour de Paul « trop petites sur iPhone ».
// lib/config/game_icons_config.dart
// Convention isométries :
// TW = rotation trigo (anti-horaire) = +90°
// CW = rotation horaire              = -90°
// H  = symétrie axe horizontal (haut/bas)
// V  = symétrie axe vertical (gauche/droite)

import 'package:flutter/material.dart';

/// Taille des icônes de la barre d'isométrie (rotation/miroir/suppression), **partagée par les
/// écrans solo et duel** pour rester cohérente. Cible d'action, délibérément plus grosse que la
/// barre d'état : `shortestSide × 0.12` borné [44, 84]. Sur iPhone la barre d'état plafonne à 30
/// et ces boutons paraissaient trop petits au doigt (retour de Paul) ; ici ≈ 44-48.
/// Appliquée en **portrait** ; le paysage garde ses rails compacts.
double isometryIconSize(BuildContext context) =>
    (MediaQuery.of(context).size.shortestSide * 0.12).clamp(44.0, 84.0);

enum GameMode {
  normal,
  isometries,
}

class GameIconConfig {
  final IconData icon;
  final String tooltip;
  final Color color;
  final List<GameMode> visibleInModes;
  final String description;

  const GameIconConfig({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.visibleInModes,
    required this.description,
  });

  bool isVisibleIn(GameMode mode) => visibleInModes.contains(mode);
}

class GameIcons {
  // ==================== NAVIGATION ====================

  static const settings = GameIconConfig(
    icon: Icons.settings,
    tooltip: 'Paramètres',
    color: Colors.white,
    visibleInModes: [GameMode.normal, GameMode.isometries],
    description: "Ouvre l'écran des paramètres",
  );

  static const enterIsometries = GameIconConfig(
    icon: Icons.school,
    tooltip: 'Mode Isométries',
    color: Color(0xFFAB47BC),
    visibleInModes: [GameMode.normal],
    description: "Passe en mode isométries (sauvegarde l'état actuel)",
  );

  static const exitIsometries = GameIconConfig(
    icon: Icons.emoji_events,
    tooltip: 'Retour au Jeu',
    color: Color(0xFFAB47BC),
    visibleInModes: [GameMode.isometries],
    description: "Quitte le mode isométries et restaure l'état du jeu",
  );

  // ==================== JEU NORMAL ====================

  static const viewSolutions = GameIconConfig(
    icon: Icons.visibility,
    tooltip: 'Voir les solutions',
    color: Color(0xFF42A5F5),
    visibleInModes: [GameMode.normal],
    description: "Affiche les solutions compatibles avec l'état actuel",
  );

  static const solutionsCounter = GameIconConfig(
    icon: Icons.emoji_events,
    tooltip: 'Nombre de solutions',
    color: Colors.green,
    visibleInModes: [GameMode.normal],
    description: 'Affiche le nombre de solutions possibles',
  );

  static const rotatePiece = GameIconConfig(
    icon: Icons.rotate_right,
    tooltip: 'Rotation',
    color: Color(0xFF42A5F5),
    visibleInModes: [GameMode.normal],
    description: 'Fait pivoter la pièce sélectionnée (mode normal)',
  );

  static const removePiece = GameIconConfig(
    icon: Icons.delete_outline,
    tooltip: 'Retirer',
    color: Color(0xFFE53935),
    visibleInModes: [GameMode.normal],
    description: 'Retire la pièce sélectionnée du plateau',
  );

  static const undo = GameIconConfig(
    icon: Icons.undo,
    tooltip: 'Annuler',
    color: Colors.white70,
    visibleInModes: [GameMode.normal],
    description: 'Annule le dernier placement de pièce',
  );

  // ==================== ISOMÉTRIES ====================
  // Convention stable :
  // - TW = anti-horaire = ↺
  // - CW = horaire      = ↻
  // - SymH = miroir axe horizontal (haut/bas)
  // - SymV = miroir axe vertical   (gauche/droite)

  static const isometryRotationTW = GameIconConfig(
    icon: Icons.rotate_left,            // (choix UI) ↺
    tooltip: 'Rotation 90° ↺ (TW)',
    color: Color(0xFF42A5F5),
    visibleInModes: [GameMode.isometries],
    description: "Rotation 90° anti-horaire (trigo)",
  );

  static const isometryRotationCW = GameIconConfig(
    icon: Icons.rotate_right,           // (choix UI) ↻
    tooltip: 'Rotation 90° ↻ (CW)',
    color: Color(0xFF42A5F5),
    visibleInModes: [GameMode.isometries],
    description: "Rotation 90° horaire",
  );

  static const isometrySymmetryH = GameIconConfig(
    icon: Icons.swap_vert,
    tooltip: 'Symétrie axe horizontal (SymH)',
    color: Color(0xFF66BB6A),
    visibleInModes: [GameMode.isometries],
    description: "Miroir haut ↔ bas (axe horizontal)",
  );

  static const isometrySymmetryV = GameIconConfig(
    icon: Icons.swap_horiz,
    tooltip: 'Symétrie axe vertical (SymV)',
    color: Color(0xFF66BB6A),
    visibleInModes: [GameMode.isometries],
    description: "Miroir gauche ↔ droite (axe vertical)",
  );

  static const isometryDelete = GameIconConfig(
    icon: Icons.delete_outline,
    tooltip: 'Retirer',
    color: Color(0xFFE53935),
    visibleInModes: [GameMode.isometries],
    description: 'Retire la pièce sélectionnée du plateau (mode isométries)',
  );

  // ==================== LISTES ORDONNÉES PAR MODE ====================

  static List<GameIconConfig> getIconsForMode(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return [
          settings,
          enterIsometries,
          viewSolutions,
          solutionsCounter,
          rotatePiece,
          removePiece,
          undo,
        ];

      case GameMode.isometries:
        return [
          settings,
          exitIsometries,

          // Ordre UI stable (ex: bas→haut ou gauche→droite)
          isometryRotationTW,
          isometryRotationCW,
          isometrySymmetryH,
          isometrySymmetryV,
          isometryDelete,
        ];
    }
  }
}

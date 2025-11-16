// Modified: 2025-11-16 09:45:00
// lib/models/app_settings.dart
// Modèles pour les paramètres de l'application

import 'package:flutter/material.dart';

/// Schéma de couleurs pour les pièces
enum PieceColorScheme {
  classic,    // Couleurs vives classiques
  pastel,     // Couleurs pastel douces
  neon,       // Couleurs néon éclatantes
  monochrome, // Nuances de gris
  rainbow,    // Arc-en-ciel
}

/// Niveau de difficulté du jeu
enum GameDifficulty {
  easy,       // Facile : indices visuels, pas de limite de temps
  normal,     // Normal : jeu standard
  hard,       // Difficile : moins d'indices, chronomètre
  expert,     // Expert : mode compétition
}

/// Paramètres UI
class UISettings {
  final PieceColorScheme colorScheme;
  final bool showPieceNumbers;      // Afficher les numéros sur les pièces
  final bool showGridLines;         // Afficher les lignes de grille
  final bool enableAnimations;      // Activer les animations
  final double pieceOpacity;        // Opacité des pièces (0.0 - 1.0)
  
  const UISettings({
    this.colorScheme = PieceColorScheme.classic,
    this.showPieceNumbers = true,
    this.showGridLines = false,
    this.enableAnimations = true,
    this.pieceOpacity = 1.0,
  });
  
  UISettings copyWith({
    PieceColorScheme? colorScheme,
    bool? showPieceNumbers,
    bool? showGridLines,
    bool? enableAnimations,
    double? pieceOpacity,
  }) {
    return UISettings(
      colorScheme: colorScheme ?? this.colorScheme,
      showPieceNumbers: showPieceNumbers ?? this.showPieceNumbers,
      showGridLines: showGridLines ?? this.showGridLines,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      pieceOpacity: pieceOpacity ?? this.pieceOpacity,
    );
  }
  
  /// Obtenir la couleur d'une pièce selon le schéma actuel
  Color getPieceColor(int pieceId) {
    switch (colorScheme) {
      case PieceColorScheme.classic:
        return _getClassicColor(pieceId);
      case PieceColorScheme.pastel:
        return _getPastelColor(pieceId);
      case PieceColorScheme.neon:
        return _getNeonColor(pieceId);
      case PieceColorScheme.monochrome:
        return _getMonochromeColor(pieceId);
      case PieceColorScheme.rainbow:
        return _getRainbowColor(pieceId);
    }
  }
  
  Color _getClassicColor(int pieceId) {
    const colors = [
      Color(0xFFE57373), // Rouge
      Color(0xFF81C784), // Vert
      Color(0xFF64B5F6), // Bleu
      Color(0xFFFFD54F), // Jaune
      Color(0xFFBA68C8), // Violet
      Color(0xFFFF8A65), // Orange
      Color(0xFF4DB6AC), // Turquoise
      Color(0xFFA1887F), // Marron
      Color(0xFF90A4AE), // Gris-bleu
      Color(0xFFF06292), // Rose
      Color(0xFF9575CD), // Violet clair
      Color(0xFF4DD0E1), // Cyan
    ];
    return colors[pieceId % colors.length];
  }
  
  Color _getPastelColor(int pieceId) {
    const colors = [
      Color(0xFFFFCDD2), // Rose pastel
      Color(0xFFC8E6C9), // Vert pastel
      Color(0xFFBBDEFB), // Bleu pastel
      Color(0xFFFFF9C4), // Jaune pastel
      Color(0xFFE1BEE7), // Violet pastel
      Color(0xFFFFCCBC), // Orange pastel
      Color(0xFFB2DFDB), // Turquoise pastel
      Color(0xFFD7CCC8), // Marron pastel
      Color(0xFFCFD8DC), // Gris pastel
      Color(0xFFF8BBD0), // Rose clair pastel
      Color(0xFFD1C4E9), // Violet clair pastel
      Color(0xFFB2EBF2), // Cyan pastel
    ];
    return colors[pieceId % colors.length];
  }
  
  Color _getNeonColor(int pieceId) {
    const colors = [
      Color(0xFFFF1744), // Rouge néon
      Color(0xFF00E676), // Vert néon
      Color(0xFF2979FF), // Bleu néon
      Color(0xFFFFEA00), // Jaune néon
      Color(0xFFD500F9), // Violet néon
      Color(0xFFFF6E40), // Orange néon
      Color(0xFF1DE9B6), // Turquoise néon
      Color(0xFFFF9100), // Ambre néon
      Color(0xFF00E5FF), // Cyan néon
      Color(0xFFFF4081), // Rose néon
      Color(0xFF651FFF), // Violet profond néon
      Color(0xFF00B0FF), // Bleu clair néon
    ];
    return colors[pieceId % colors.length];
  }
  
  Color _getMonochromeColor(int pieceId) {
    final shades = [
      Colors.grey[900]!,
      Colors.grey[800]!,
      Colors.grey[700]!,
      Colors.grey[600]!,
      Colors.grey[500]!,
      Colors.grey[400]!,
      Colors.grey[300]!,
      Colors.grey[200]!,
      Colors.grey[100]!,
      Colors.grey[50]!,
      Colors.blueGrey[300]!,
      Colors.blueGrey[100]!,
    ];
    return shades[pieceId % shades.length];
  }
  
  Color _getRainbowColor(int pieceId) {
    // Arc-en-ciel : Rouge -> Orange -> Jaune -> Vert -> Bleu -> Violet
    const colors = [
      Color(0xFFFF0000), // Rouge
      Color(0xFFFF7F00), // Orange
      Color(0xFFFFFF00), // Jaune
      Color(0xFF00FF00), // Vert
      Color(0xFF0000FF), // Bleu
      Color(0xFF4B0082), // Indigo
      Color(0xFF9400D3), // Violet
      Color(0xFFFF1493), // Rose vif
      Color(0xFF00CED1), // Turquoise foncé
      Color(0xFFFFD700), // Or
      Color(0xFF32CD32), // Vert citron
      Color(0xFF8A2BE2), // Bleu violet
    ];
    return colors[pieceId % colors.length];
  }
  
  Map<String, dynamic> toJson() {
    return {
      'colorScheme': colorScheme.index,
      'showPieceNumbers': showPieceNumbers,
      'showGridLines': showGridLines,
      'enableAnimations': enableAnimations,
      'pieceOpacity': pieceOpacity,
    };
  }
  
  factory UISettings.fromJson(Map<String, dynamic> json) {
    return UISettings(
      colorScheme: PieceColorScheme.values[json['colorScheme'] ?? 0],
      showPieceNumbers: json['showPieceNumbers'] ?? true,
      showGridLines: json['showGridLines'] ?? false,
      enableAnimations: json['enableAnimations'] ?? true,
      pieceOpacity: json['pieceOpacity'] ?? 1.0,
    );
  }
}

/// Paramètres de jeu
class GameSettings {
  final GameDifficulty difficulty;
  final bool showSolutionCounter;   // Afficher le compteur de solutions
  final bool enableHints;           // Activer les indices
  final bool enableTimer;           // Activer le chronomètre
  final bool enableHaptics;         // Activer le retour haptique
  final int longPressDuration;      // Durée du long press en ms
  
  const GameSettings({
    this.difficulty = GameDifficulty.normal,
    this.showSolutionCounter = true,
    this.enableHints = false,
    this.enableTimer = false,
    this.enableHaptics = true,
    this.longPressDuration = 200,
  });
  
  GameSettings copyWith({
    GameDifficulty? difficulty,
    bool? showSolutionCounter,
    bool? enableHints,
    bool? enableTimer,
    bool? enableHaptics,
    int? longPressDuration,
  }) {
    return GameSettings(
      difficulty: difficulty ?? this.difficulty,
      showSolutionCounter: showSolutionCounter ?? this.showSolutionCounter,
      enableHints: enableHints ?? this.enableHints,
      enableTimer: enableTimer ?? this.enableTimer,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      longPressDuration: longPressDuration ?? this.longPressDuration,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'difficulty': difficulty.index,
      'showSolutionCounter': showSolutionCounter,
      'enableHints': enableHints,
      'enableTimer': enableTimer,
      'enableHaptics': enableHaptics,
      'longPressDuration': longPressDuration,
    };
  }
  
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      difficulty: GameDifficulty.values[json['difficulty'] ?? 1],
      showSolutionCounter: json['showSolutionCounter'] ?? true,
      enableHints: json['enableHints'] ?? false,
      enableTimer: json['enableTimer'] ?? false,
      enableHaptics: json['enableHaptics'] ?? true,
      longPressDuration: json['longPressDuration'] ?? 200,
    );
  }
}

/// Paramètres globaux de l'application
class AppSettings {
  final UISettings ui;
  final GameSettings game;
  
  const AppSettings({
    this.ui = const UISettings(),
    this.game = const GameSettings(),
  });
  
  AppSettings copyWith({
    UISettings? ui,
    GameSettings? game,
  }) {
    return AppSettings(
      ui: ui ?? this.ui,
      game: game ?? this.game,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ui': ui.toJson(),
      'game': game.toJson(),
    };
  }
  
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      ui: UISettings.fromJson(json['ui'] ?? {}),
      game: GameSettings.fromJson(json['game'] ?? {}),
    );
  }
}


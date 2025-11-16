// Modified: 2025-11-16 08:30:00
// lib/providers/game_config_provider.dart
// Provider pour gérer la configuration du jeu et la progression du joueur

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/game_config.dart';

/// Provider pour la configuration du jeu
final gameConfigProvider = NotifierProvider<GameConfigNotifier, GameConfig>(() {
  return GameConfigNotifier();
});

class GameConfigNotifier extends Notifier<GameConfig> {
  @override
  GameConfig build() {
    _loadConfig();
    return kDefaultConfig;
  }
  
  /// Charge la configuration depuis les préférences
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final levelIndex = prefs.getInt('player_level') ?? 0;
    final level = PlayerLevel.values[levelIndex];
    state = GameConfig(level: level);
  }
  
  /// Sauvegarde la configuration
  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_level', state.level.index);
  }
  
  /// Change le niveau du joueur
  Future<void> setLevel(PlayerLevel level) async {
    state = GameConfig(level: level);
    await _saveConfig();
  }
  
  /// Progression automatique du niveau
  Future<void> checkLevelUp(PlayerStats stats) async {
    PlayerLevel? newLevel;
    
    // Débutant → Intermédiaire : 3 puzzles complétés
    if (state.level == PlayerLevel.beginner && stats.puzzlesCompleted >= 3) {
      newLevel = PlayerLevel.intermediate;
    }
    
    // Intermédiaire → Avancé : 15 puzzles + utilisation des rotations
    if (state.level == PlayerLevel.intermediate && 
        stats.puzzlesCompleted >= 15 && 
        stats.rotationsUsed > 20) {
      newLevel = PlayerLevel.advanced;
    }
    
    // Avancé → Expert : 50 puzzles + temps moyen < 5min
    if (state.level == PlayerLevel.advanced && 
        stats.puzzlesCompleted >= 50 && 
        stats.averageTime.inMinutes < 5) {
      newLevel = PlayerLevel.expert;
    }
    
    if (newLevel != null) {
      await setLevel(newLevel);
    }
  }
}

/// Statistiques du joueur
class PlayerStats {
  final int puzzlesCompleted;
  final int rotationsUsed;
  final Duration averageTime;
  final int totalPlayTime; // en secondes
  
  const PlayerStats({
    required this.puzzlesCompleted,
    required this.rotationsUsed,
    required this.averageTime,
    required this.totalPlayTime,
  });
  
  factory PlayerStats.empty() {
    return const PlayerStats(
      puzzlesCompleted: 0,
      rotationsUsed: 0,
      averageTime: Duration.zero,
      totalPlayTime: 0,
    );
  }
}

/// Provider pour les statistiques du joueur
final playerStatsProvider = NotifierProvider<PlayerStatsNotifier, PlayerStats>(() {
  return PlayerStatsNotifier();
});

class PlayerStatsNotifier extends Notifier<PlayerStats> {
  @override
  PlayerStats build() {
    _loadStats();
    return PlayerStats.empty();
  }
  
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    state = PlayerStats(
      puzzlesCompleted: prefs.getInt('puzzles_completed') ?? 0,
      rotationsUsed: prefs.getInt('rotations_used') ?? 0,
      averageTime: Duration(seconds: prefs.getInt('average_time_seconds') ?? 0),
      totalPlayTime: prefs.getInt('total_play_time') ?? 0,
    );
  }
  
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puzzles_completed', state.puzzlesCompleted);
    await prefs.setInt('rotations_used', state.rotationsUsed);
    await prefs.setInt('average_time_seconds', state.averageTime.inSeconds);
    await prefs.setInt('total_play_time', state.totalPlayTime);
  }
  
  Future<void> incrementPuzzlesCompleted(Duration completionTime) async {
    final newAverage = Duration(
      seconds: ((state.averageTime.inSeconds * state.puzzlesCompleted) + 
                completionTime.inSeconds) ~/ 
               (state.puzzlesCompleted + 1),
    );
    
    state = PlayerStats(
      puzzlesCompleted: state.puzzlesCompleted + 1,
      rotationsUsed: state.rotationsUsed,
      averageTime: newAverage,
      totalPlayTime: state.totalPlayTime + completionTime.inSeconds,
    );
    
    await _saveStats();
  }
  
  Future<void> incrementRotations() async {
    state = PlayerStats(
      puzzlesCompleted: state.puzzlesCompleted,
      rotationsUsed: state.rotationsUsed + 1,
      averageTime: state.averageTime,
      totalPlayTime: state.totalPlayTime,
    );
    await _saveStats();
  }
}


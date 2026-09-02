// Modified: 2026-09-02 20:37 — progression solo : setUserName, advanceLevel (plafonné kMaxLevel),
//           ensureLoaded (attendre le chargement avant de lire currentLevel au démarrage).
// Historique: 2026-08-31 09:45 — PLAN_ERGONOMIE §8 (décision 62) : retrait des 9 setters des
//           réglages morts (setDifficulty, setEnableAnimations, setEnableHints, setEnableTimer,
//           setIconSize, setIsometriesAppBarColor, setPieceOpacity, setShowGridLines,
//           setShowPieceNumbers). Les setters Duel et les vivants restent.
// lib/providers/settings_provider.dart
// Historique: 2604221200 — Fix print() → debugPrint() dans les catch.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart' show kMaxLevel;

/// Provider pour la base de données des paramètres
final settingsDatabaseProvider = Provider<SettingsDatabase>((ref) {
  return SettingsDatabase();
});

/// Provider pour les paramètres de l'application
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _storageKey = 'app_settings';
  late SettingsDatabase _db;
  Future<void>? _loadFuture;

  @override
  AppSettings build() {
    _db = ref.read(settingsDatabaseProvider);
    _loadFuture = _loadSettings();
    return const AppSettings();
  }

  /// À attendre avant de lire des réglages persistés au démarrage (ex: currentLevel dans
  /// main.dart) — sinon on lirait les défauts tant que _loadSettings n'a pas fini.
  Future<void> ensureLoaded() => _loadFuture ?? Future.value();

  /// Progression solo : nom du joueur (saisi au 1er puzzle réussi).
  Future<void> setUserName(String? name) async {
    state = state.copyWith(userName: name, clearUserName: name == null);
    await _saveSettings();
  }

  /// Progression solo : passe au niveau suivant (plafonné à kMaxLevel).
  Future<void> advanceLevel() async {
    if (state.currentLevel >= kMaxLevel) return;
    state = state.copyWith(currentLevel: state.currentLevel + 1);
    await _saveSettings();
  }

  /// Enregistrer le résultat d'une partie (isWin: true=victoire, false=défaite, null=égalité)
  Future<void> recordDuelGame({required bool? isWin}) async {
    state = state.copyWith(
      duel: state.duel.recordGame(isWin: isWin),
    );
    await _saveSettings();
  }

  /// Réinitialiser tous les paramètres Duel (garder nom et stats)
  Future<void> resetDuelSettings() async {
    final currentName = state.duel.playerName;
    final currentStats = (
    totalGamesPlayed: state.duel.totalGamesPlayed,
    totalWins: state.duel.totalWins,
    totalLosses: state.duel.totalLosses,
    totalDraws: state.duel.totalDraws,
    );

    state = state.copyWith(
      duel: DuelSettings.defaults.copyWith(
        playerName: currentName,
        totalGamesPlayed: currentStats.totalGamesPlayed,
        totalWins: currentStats.totalWins,
        totalLosses: currentStats.totalLosses,
        totalDraws: currentStats.totalDraws,
      ),
    );
    await _saveSettings();
  }

  // === Paramètres UI ===

  /// Réinitialiser les statistiques Duel
  Future<void> resetDuelStats() async {
    state = state.copyWith(
      duel: state.duel.resetStats(),
    );
    await _saveSettings();
  }

  /// Réinitialise tous les paramètres par défaut
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  /// Change le schéma de couleurs des pièces
  Future<void> setColorScheme(PieceColorScheme scheme) async {
    state = state.copyWith(
      ui: state.ui.copyWith(colorScheme: scheme),
    );
    await _saveSettings();
  }

  /// Définit les couleurs personnalisées
  Future<void> setCustomColors(List<Color> colors) async {
    state = state.copyWith(
      ui: state.ui.copyWith(
        customColors: colors,
        colorScheme: PieceColorScheme.custom,
      ),
    );
    await _saveSettings();
  }

  /// Définir la durée personnalisée (en secondes)
  Future<void> setDuelCustomDuration(int seconds) async {
    state = state.copyWith(
      duel: state.duel.copyWith(
        duration: DuelDuration.custom,
        customDurationSeconds: seconds.clamp(60, 1800),
      ),
    );
    await _saveSettings();
  }

  /// Définir la durée de partie
  Future<void> setDuelDuration(DuelDuration duration) async {
    state = state.copyWith(
      duel: state.duel.copyWith(duration: duration),
    );
    await _saveSettings();
  }

  /// Définir l'opacité du guide (0.1 - 0.5)
  Future<void> setDuelGuideOpacity(double opacity) async {
    state = state.copyWith(
      duel: state.duel.copyWith(guideOpacity: opacity.clamp(0.1, 0.5)),
    );
    await _saveSettings();
  }

  // === Paramètres de jeu ===

  /// Définir l'opacité des hachures (0.2 - 0.6)
  Future<void> setDuelHatchOpacity(double opacity) async {
    state = state.copyWith(
      duel: state.duel.copyWith(hatchOpacity: opacity.clamp(0.2, 0.6)),
    );
    await _saveSettings();
  }



  /// Définir le nom du joueur
  Future<void> setDuelPlayerName(String? name) async {
    state = state.copyWith(
      duel: state.duel.copyWith(playerName: name),
    );
    await _saveSettings();
  }

  /// Activer/désactiver le guide de solution
  Future<void> setDuelShowGuide(bool show) async {
    state = state.copyWith(
      duel: state.duel.copyWith(showSolutionGuide: show),
    );
    await _saveSettings();
  }

  /// Activer/désactiver les hachures sur pièces adversaires
  Future<void> setDuelShowHatch(bool show) async {
    state = state.copyWith(
      duel: state.duel.copyWith(showHatchOnOpponent: show),
    );
    await _saveSettings();
  }

  /// Activer/désactiver l'affichage des pièces adversaires
  Future<void> setDuelShowOpponentProgress(bool show) async {
    state = state.copyWith(
      duel: state.duel.copyWith(showOpponentProgress: show),
    );
    await _saveSettings();
  }

  // === Paramètres Duel ===

  /// Activer/désactiver les numéros sur le guide
  Future<void> setDuelShowPieceNumbers(bool show) async {
    state = state.copyWith(
      duel: state.duel.copyWith(showPieceNumbers: show),
    );
    await _saveSettings();
  }

  /// Activer/désactiver les sons
  Future<void> setDuelSounds(bool enable) async {
    state = state.copyWith(
      duel: state.duel.copyWith(enableSounds: enable),
    );
    await _saveSettings();
  }

  // ============================================================
// MÉTHODES À AJOUTER DANS settings_provider.dart
// Dans la classe SettingsNotifier, ajouter ces méthodes :
// ============================================================

  // ============================================================
  // DUEL SETTINGS
  // ============================================================

  /// Activer/désactiver les vibrations
  Future<void> setDuelVibration(bool enable) async {
    state = state.copyWith(
      duel: state.duel.copyWith(enableVibration: enable),
    );
    await _saveSettings();
  }

  /// Active/désactive le retour haptique
  Future<void> setEnableHaptics(bool enable) async {
    state = state.copyWith(
      game: state.game.copyWith(enableHaptics: enable),
    );
    await _saveSettings();
  }

  /// Change la durée du long press
  Future<void> setLongPressDuration(int duration) async {
    state = state.copyWith(
      game: state.game.copyWith(longPressDuration: duration),
    );
    await _saveSettings();
  }

  /// Active/désactive le compteur de solutions
  Future<void> setShowSolutionCounter(bool show) async {
    state = state.copyWith(
      game: state.game.copyWith(showSolutionCounter: show),
    );
    await _saveSettings();
  }

  /// Charge les paramètres depuis SQLite
  Future<void> _loadSettings() async {
    try {
      final jsonString = await _db.getSetting(_storageKey);

      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres: $e');
    }
  }

  /// Sauvegarde les paramètres dans SQLite
  Future<void> _saveSettings() async {
    try {
      final jsonString = jsonEncode(state.toJson());
      await _db.setSetting(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

// ============================================================
// N'OUBLIE PAS D'IMPORTER DuelDuration si nécessaire :
// import 'package:pentapol/models/app_settings.dart';
// ============================================================
}
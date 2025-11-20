// Modified: 2025-11-16 10:30:00
// lib/providers/settings_provider.dart
// Provider pour gérer les paramètres de l'application avec SQLite

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../database/settings_database.dart';

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

  @override
  AppSettings build() {
    _db = ref.read(settingsDatabaseProvider);
    _loadSettings();
    return const AppSettings();
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
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  /// Sauvegarde les paramètres dans SQLite
  Future<void> _saveSettings() async {
    try {
      final jsonString = jsonEncode(state.toJson());
      await _db.setSetting(_storageKey, jsonString);
    } catch (e) {
      print('Erreur lors de la sauvegarde des paramètres: $e');
    }
  }

  // === Paramètres UI ===

  /// Change le schéma de couleurs des pièces
  Future<void> setColorScheme(PieceColorScheme scheme) async {
    state = state.copyWith(
      ui: state.ui.copyWith(colorScheme: scheme),
    );
    await _saveSettings();
  }

  /// Active/désactive l'affichage des numéros sur les pièces
  Future<void> setShowPieceNumbers(bool show) async {
    state = state.copyWith(
      ui: state.ui.copyWith(showPieceNumbers: show),
    );
    await _saveSettings();
  }

  /// Active/désactive l'affichage des lignes de grille
  Future<void> setShowGridLines(bool show) async {
    state = state.copyWith(
      ui: state.ui.copyWith(showGridLines: show),
    );
    await _saveSettings();
  }

  /// Active/désactive les animations
  Future<void> setEnableAnimations(bool enable) async {
    state = state.copyWith(
      ui: state.ui.copyWith(enableAnimations: enable),
    );
    await _saveSettings();
  }

  /// Change l'opacité des pièces
  Future<void> setPieceOpacity(double opacity) async {
    state = state.copyWith(
      ui: state.ui.copyWith(pieceOpacity: opacity),
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

  /// Change la couleur de fond de l'AppBar en mode isométries
  Future<void> setIsometriesAppBarColor(Color color) async {
    state = state.copyWith(
      ui: state.ui.copyWith(isometriesAppBarColor: color),
    );
    await _saveSettings();
  }

  /// Change la taille des icônes
  Future<void> setIconSize(double size) async {
    state = state.copyWith(
      ui: state.ui.copyWith(iconSize: size),
    );
    await _saveSettings();
  }

  // === Paramètres de jeu ===

  /// Change le niveau de difficulté
  Future<void> setDifficulty(GameDifficulty difficulty) async {
    state = state.copyWith(
      game: state.game.copyWith(difficulty: difficulty),
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

  /// Active/désactive les indices
  Future<void> setEnableHints(bool enable) async {
    state = state.copyWith(
      game: state.game.copyWith(enableHints: enable),
    );
    await _saveSettings();
  }

  /// Active/désactive le chronomètre
  Future<void> setEnableTimer(bool enable) async {
    state = state.copyWith(
      game: state.game.copyWith(enableTimer: enable),
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

  /// Réinitialise tous les paramètres par défaut
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }
}
// Modified: 2026-09-12 10:58 — sauvegarde fiable du barème pour les prochaines parties.
// Historique: 2026-09-12 07:25 — enregistrement du barème pour les prochaines parties solo.
// Historique: 2026-09-11 15:10 — retrait de l’enregistrement des exercices du mode supprimé.
// lib/providers/settings_provider.dart
// Historique: 2026-09-10 06:37 — setShowPieceNumbers(bool) : pastille des pièces posées (C8, retour de Paul).
//           Plus setRackCellRatio(double) : taille des pièces du rack, réglable en live, bornée [0.30, 0.60].
// Historique: 2026-09-09 09:08 — setShowCounters(bool) : affiche/masque les compteurs isométries + fautes
//           dans la barre du jeu (retour de Paul).
// Historique: 2026-09-09 07:01 — sensibilité du drag : setLongPressDuration borne la valeur à [50, 200] ms
//           (retour de Paul, défaut 100).
// Historique: 2026-09-08 22:37 — Mode entraînement (PLAN_MODE_ENTRAINEMENT §6) : recordTrainingExercise()
//           incrémente trainingExercisesDone (retour d'exercice, PAS un record — aucune écriture dans
//           PuzzleStats/SolvedSolutions). JSON, pas de migration.
// Historique: 2026-09-07 07:34 — conformité défi V1 : setShareScoresOptIn(bool) (consentement §8),
//           setChallengeConsentAsked (proposition unique à la 1re complétion d'un défi) et
//           deleteOnlineIdentity() (efface les scores serveur + le playerId local + coupe l'opt-in,
//           suppression RGPD §7.4). ensurePlayerId reste paresseux, appelé sous opt-in seulement.
// Historique: 2026-09-07 07:17 — conformité défi V1 : setShareScoresOptIn(bool) (consentement §8) et
//           deleteOnlineIdentity() (efface les scores serveur + le playerId local + coupe l'opt-in,
//           suppression RGPD §7.4). ensurePlayerId reste paresseux, appelé sous opt-in seulement.
// Historique: 2026-09-06 04:50 — i18n : setLocale(code) — null = suit l'appareil, 'en'/'fr' = forcé.
// Historique: 2026-09-04 16:25 — défi Phase 3 : generatePlayerId (128 bits, Random.secure) + ensurePlayerId
//           (paresseux, à la 1re soumission de défi — pas au lancement). Identité §7.4, distincte du pseudo.
// Historique: 2026-09-02 20:37 — progression solo : setUserName, advanceLevel (plafonné kMaxLevel),
//           ensureLoaded (attendre le chargement avant de lire currentLevel au démarrage).
// Historique: 2026-08-31 09:45 — PLAN_ERGONOMIE §8 (décision 62) : retrait des 9 setters des
//           réglages morts (setDifficulty, setEnableAnimations, setEnableHints, setEnableTimer,
//           setIconSize, setIsometriesAppBarColor, setPieceOpacity, setShowGridLines,
//           setShowPieceNumbers). Les setters Duel et les vivants restent.
// lib/providers/settings_provider.dart
// Historique: 2604221200 — Fix print() → debugPrint() dans les catch.

import 'package:pentapol/pentoscope/geometry_score.dart';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/database/settings_database.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/challenge_api.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart' show kMaxLevel;

/// Génère une identité 128 bits (32 hex) via `Random.secure()` — clé primaire du joueur côté
/// serveur de classement (CDC §7.4), distincte du pseudo. Fonction pure, testable.
String generatePlayerId() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

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

  Future<void> setGeometryRules(GeometryRules rules) async {
    await ensureLoaded();
    final next = state.copyWith(game: state.game.copyWith(geometryRules: rules));
    await _db.setSetting(_storageKey, jsonEncode(next.toJson()));
    state = state.copyWith(game: state.game.copyWith(geometryRules: rules));
  }

  /// Progression solo : nom du joueur (saisi au 1er puzzle réussi).
  Future<void> setUserName(String? name) async {
    state = state.copyWith(userName: name, clearUserName: name == null);
    await _saveSettings();
  }

  /// Identité 128 bits du joueur (CDC §7.4). La génère et la persiste si absente, la retourne.
  /// **Paresseux** : appelé à la 1re soumission de défi, pas au lancement — l'identifiant persistant
  /// n'existe donc que quand le classement est utilisé (RGPD, §8). Distinct du pseudo.
  Future<String> ensurePlayerId() async {
    final existing = state.playerId;
    if (existing != null && existing.length == 32) return existing;
    final id = generatePlayerId();
    state = state.copyWith(playerId: id);
    await _saveSettings();
    return id;
  }

  /// Consentement à l'envoi de score au classement en ligne (CDC §8). Défaut `false` ; activé par
  /// un geste explicite (dialogue de consentement / interrupteur Réglages). Tant qu'il est faux,
  /// `_submitChallengeScore` ne fait rien et aucun `playerId` n'est généré.
  Future<void> setShareScoresOptIn(bool value) async {
    if (state.shareScoresOptIn == value) return;
    state = state.copyWith(shareScoresOptIn: value);
    await _saveSettings();
  }

  /// Marque que l'opt-in a été **proposé** automatiquement à la fin d'un défi (garde la proposition
  /// unique — le joueur peut toujours activer plus tard via les Réglages / le classement).
  Future<void> setChallengeConsentAsked(bool value) async {
    if (state.challengeConsentAsked == value) return;
    state = state.copyWith(challengeConsentAsked: value);
    await _saveSettings();
  }

  /// Suppression RGPD (CDC §7.4) : efface les scores du joueur côté serveur (DELETE), puis efface
  /// le `playerId` local et **coupe l'opt-in**. Échec réseau silencieux (§7.8) — le local est
  /// nettoyé quoi qu'il arrive, et l'id étant secret, une ligne serveur orpheline reste inatteignable.
  Future<void> deleteOnlineIdentity() async {
    final id = state.playerId;
    if (id != null && id.length == 32) {
      await ChallengeApi().deleteMyScores(playerId: id);
    }
    state = state.copyWith(clearPlayerId: true, shareScoresOptIn: false);
    await _saveSettings();
  }

  /// Langue de l'interface : `null` = suit la locale de l'appareil, `'en'`/`'fr'` = forcé.
  Future<void> setLocale(String? code) async {
    state = state.copyWith(localeCode: code, clearLocaleCode: code == null);
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

  /// Change la durée du long press (sensibilité du drag). Bornée à [50, 200] ms (retour de Paul).
  Future<void> setLongPressDuration(int duration) async {
    state = state.copyWith(
      game: state.game.copyWith(longPressDuration: duration.clamp(50, 200)),
    );
    await _saveSettings();
  }

  /// Afficher/masquer les compteurs isométries + fautes dans la barre du jeu (retour de Paul).
  Future<void> setShowCounters(bool value) async {
    state = state.copyWith(game: state.game.copyWith(showCounters: value));
    await _saveSettings();
  }

  /// Taille des pièces du rack (rapport à la case du plateau, décision 6). Réglable en live pour
  /// calibrer sur device (retour de Paul, 2026-09-10). Bornée à la plage utile 0,30-0,60.
  Future<void> setRackCellRatio(double ratio) async {
    state = state.copyWith(
      game: state.game.copyWith(rackCellRatio: ratio.clamp(0.30, 0.60)),
    );
    await _saveSettings();
  }

  /// Afficher/masquer le numéro (pastille unique) des pièces posées sur le plateau (C8, retour
  /// de Paul, 2026-09-10).
  Future<void> setShowPieceNumbers(bool value) async {
    state = state.copyWith(game: state.game.copyWith(showPieceNumbers: value));
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
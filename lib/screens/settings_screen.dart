// Modified: 2026-09-12 10:58 — accès au réglage du barème avant déploiement.
// Historique: 2026-09-10 06:38 — réglage « Numéro des pièces » (SwitchListTile → setShowPieceNumbers, C8) :
//           pastille des pièces posées. Plus « Taille des pièces du rack » (stepper 0.30-0.60) →
//           setRackCellRatio : calibrage live du rack sur device (retour de Paul, décision 6).
// Historique: 2026-09-09 09:08 — nouveau réglage « compteurs » (isométries + fautes dans la barre du jeu),
//           SwitchListTile → setShowCounters (retour de Paul).
// Historique: 2026-09-09 07:01 — sensibilité du drag : bornes du réglage 100/500 → 50/200 (retour de Paul,
//           défaut 100 ms). Plage effective 50-100-150-200 ms (pas de 50).
// Historique: 2026-09-08 09:05 — ergonomie : le nom affiché au classement (userName) est exposé DANS la
//           section « Classement en ligne » (tuile « Nom affiché » → dialogue → setUserName), là où on
//           l'attend, en plus de la tuile Duel qui écrivait déjà le même champ canonique.
// Historique: 2026-09-07 07:17 — conformité défi V1 : section « Classement en ligne » — interrupteur
//           opt-in (shareScoresOptIn, §8) + suppression des données de classement (RGPD §7.4).
// Historique: 2026-09-06 04:50 — i18n : toutes les chaînes de l'écran via AppLocalizations + sélecteur
//           de langue (Système/Français/English → settings.localeCode) sous la section Interface.
// Historique: 2026-09-02 20:37 — pseudo unique : « Nom du joueur » lit/écrit settings.userName (nom
//           canonique) au lieu de duel.playerName ; setUserName remplace setDuelPlayerName ici.
// lib/screens/settings_screen.dart
// Historique: 2026-09-01 08:58 — sortie fiable sur iPad : bouton « Fermer » ancré en bas
//           (bottomNavigationBar) + SafeArea, la flèche retour du haut étant recouverte par les
//           commandes multitâche d'iPadOS.
// lib/screens/settings_screen.dart
// Historique: 2026-08-31 09:45 — PLAN_ERGONOMIE §8 (décision 62) : écran de réglages minimal —
//             retrait des 9 entrées mortes (numéros, grille, animations, opacité, taille d'icônes,
//             couleur isométries, difficulté, indices, chrono) et de leurs helpers orphelins.
//             Restent : couleurs, personnaliser, compteur de solutions, haptique, drag, Duel, À propos.
// Historique: 2025-11-30 — Ajout section Duel et version.

import 'package:flutter/material.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';
import 'package:pentapol/screens/geometry_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/l10n/app_localizations.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/screens/custom_colors_screen.dart';
import 'package:pentapol/config/build_info.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reset,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.reset),
                  content: Text(l10n.settingsResetConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.reset),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await notifier.resetToDefaults();
              }
            },
          ),
        ],
      ),
      // Sortie toujours atteignable : sur iPad les commandes multitâche d'iPadOS recouvrent le
      // coin haut-gauche où vit la flèche retour. Ce bouton, ancré en bas et hors des zones
      // système (SafeArea), garantit une issue quel que soit l'habillage de la fenêtre.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            label: Text(l10n.close),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
        children: [
          // === SECTION UI ===
          _buildSectionHeader(l10n.sectionInterface),

          // Langue de l'interface (Système = suit l'appareil)
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_languageName(l10n, settings.localeCode)),
            onTap: () => _showLanguageDialog(context, notifier, settings.localeCode),
          ),

          // Schéma de couleurs
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(l10n.pieceColors),
            subtitle: Text(_colorSchemeName(l10n, settings.ui.colorScheme)),
            onTap: () => _showColorSchemeDialog(context, notifier, settings.ui.colorScheme),
          ),

          // Personnaliser les couleurs (visible si schéma custom)
          if (settings.ui.colorScheme == PieceColorScheme.custom)
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text(l10n.customizeColors),
              subtitle: Text(l10n.customizeColorsSub),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomColorsScreen()),
                );
              },
            ),

          const Divider(),

          // === SECTION JEU ===
          _buildSectionHeader(l10n.sectionGame),

          if (kGeometryTuningEnabled)
            ListTile(
              key: const ValueKey('geometry-settings'),
              leading: const Icon(Icons.tune),
              title: Text(l10n.geometryTitle),
              subtitle: Text(l10n.geometrySettingsSub),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => const GeometrySettingsScreen())),
            ),

          // Compteur de solutions
          SwitchListTile(
            secondary: const Icon(Icons.emoji_events),
            title: Text(l10n.solutionCounter),
            subtitle: Text(l10n.solutionCounterSub),
            value: settings.game.showSolutionCounter,
            onChanged: (value) => notifier.setShowSolutionCounter(value),
          ),

          // Numéro des pièces posées (C8, décision 7) : une pastille par pièce, optionnel.
          SwitchListTile(
            secondary: const Icon(Icons.tag_faces_outlined),
            title: Text(l10n.showPieceNumbers),
            subtitle: Text(l10n.showPieceNumbersSub),
            value: settings.game.showPieceNumbers,
            onChanged: (value) => notifier.setShowPieceNumbers(value),
          ),

          // Retour haptique
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(l10n.haptics),
            subtitle: Text(l10n.hapticsSub),
            value: settings.game.enableHaptics,
            onChanged: (value) => notifier.setEnableHaptics(value),
          ),

          // Compteurs isométries + fautes dans la barre du jeu
          SwitchListTile(
            secondary: const Icon(Icons.tag),
            title: Text(l10n.showCounters),
            subtitle: Text(l10n.showCountersSub),
            value: settings.game.showCounters,
            onChanged: (value) => notifier.setShowCounters(value),
          ),

          // Durée du long press
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: Text(l10n.dragSensitivity),
            subtitle: Text(l10n.dragMs(settings.game.longPressDuration)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: settings.game.longPressDuration > 50
                      ? () => notifier.setLongPressDuration(settings.game.longPressDuration - 50)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: settings.game.longPressDuration < 200
                      ? () => notifier.setLongPressDuration(settings.game.longPressDuration + 50)
                      : null,
                ),
              ],
            ),
          ),

          // Taille des pièces du rack (rapport à la case du plateau, décision 6). Réglage de
          // calibrage — à revoir avant l'App Store (CHECKLIST_APPSTORE).
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: Text(l10n.rackSize),
            subtitle: Text(settings.game.rackCellRatio.toStringAsFixed(2)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: settings.game.rackCellRatio > 0.30
                      ? () => notifier.setRackCellRatio(settings.game.rackCellRatio - 0.02)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: settings.game.rackCellRatio < 0.60
                      ? () => notifier.setRackCellRatio(settings.game.rackCellRatio + 0.02)
                      : null,
                ),
              ],
            ),
          ),

          const Divider(),

          // === SECTION CLASSEMENT EN LIGNE ===
          _buildSectionHeader(l10n.sectionRanking),

          // Nom affiché au classement (= settings.userName, nom canonique). Exposé ICI, là où on
          // l'attend, en plus de la tuile Duel qui écrit le même champ (le pseudo est partagé
          // classement + duel). Édition par un dialogue simple → setUserName.
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.displayName),
            subtitle: Text(settings.userName?.isNotEmpty == true
                ? settings.userName!
                : l10n.notDefined),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editDisplayName(context, ref),
          ),

          // Opt-in à l'envoi de score (§8 : désactivé par défaut, activé par geste explicite).
          SwitchListTile(
            secondary: const Icon(Icons.leaderboard_outlined),
            title: Text(l10n.shareScores),
            subtitle: Text(l10n.shareScoresSub),
            value: settings.shareScoresOptIn,
            onChanged: (value) => notifier.setShareScoresOptIn(value),
          ),

          // Suppression RGPD (§7.4) : efface les scores serveur + l'identité locale. Inactif tant
          // qu'aucune identité n'a été créée (rien à supprimer).
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteOnlineData),
            subtitle: Text(l10n.deleteOnlineDataSub),
            enabled: settings.playerId != null,
            onTap: settings.playerId == null
                ? null
                : () => _confirmDeleteOnlineData(context, ref),
          ),

          const Divider(),

          // === SECTION DUEL ===
          _buildSectionHeader(l10n.sectionDuel),

          // Tile pour accéder aux paramètres Duel
          _buildDuelSettingsTile(context, ref, settings),

          const Divider(),

          // === SECTION À PROPOS ===
          _buildSectionHeader(l10n.sectionAbout),

          // Version de l'app
          _buildVersionTile(context),

          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  /// Édite le nom affiché au classement (`settings.userName`). Dialogue simple : champ + Enregistrer.
  /// Écrit le même champ canonique que la tuile Duel (le pseudo est partagé classement + duel).
  Future<void> _editDisplayName(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(settingsProvider.notifier);
    final controller =
        TextEditingController(text: ref.read(settingsProvider).userName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.displayName),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l10n.duelNicknameHint,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if (name == null) return; // annulé
    await notifier.setUserName(name.isEmpty ? null : name);
  }

  /// Confirme puis supprime les données de classement (RGPD §7.4) : scores serveur + identité locale.
  Future<void> _confirmDeleteOnlineData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteOnlineData),
        content: Text(l10n.deleteOnlineDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsProvider.notifier).deleteOnlineIdentity();
    messenger.showSnackBar(SnackBar(content: Text(l10n.deleteOnlineDataDone)));
  }

  // === WIDGETS DUEL ===

  Widget _buildDuelSettingsTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final l10n = AppLocalizations.of(context);
    final playerName = settings.userName ?? l10n.notDefined;
    final duration = settings.duel.durationFormatted;
    final stats = l10n.duelStatsSummary(settings.duel.totalWins,
        settings.duel.totalLosses, settings.duel.totalDraws);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.sports_esports, color: Colors.deepPurple),
      ),
      title: Text(l10n.duelSettings),
      subtitle: Text('$playerName • $duration • $stats'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDuelSettingsDialog(context, ref),
    );
  }

  void _showDuelSettingsDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Controllers
    final nameController = TextEditingController(text: settings.userName ?? '');
    DuelDuration selectedDuration = settings.duel.duration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final l10n = AppLocalizations.of(ctx);
          return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.sports_esports, color: Colors.deepPurple, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      l10n.duelSettings,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nom du joueur
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.duelPlayerName,
                    hintText: l10n.duelNicknameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLength: 20,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Durée de partie
                Text(
                  l10n.gameDuration,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DuelDuration.values.where((d) => d != DuelDuration.custom).map((duration) {
                    final isSelected = selectedDuration == duration;
                    return ChoiceChip(
                      label: Text('${duration.icon} ${duration.label}'),
                      selected: isSelected,
                      selectedColor: Colors.deepPurple.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => selectedDuration = duration);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Statistiques
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statsHeader,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(l10n.statGames, '${settings.duel.totalGamesPlayed}', Icons.sports_esports),
                          _buildStatColumn(l10n.statWins, '${settings.duel.totalWins}', Icons.emoji_events, Colors.green),
                          _buildStatColumn(l10n.statLosses, '${settings.duel.totalLosses}', Icons.close, Colors.red),
                          _buildStatColumn(l10n.statDraws, '${settings.duel.totalDraws}', Icons.handshake, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          l10n.winRate(settings.duel.winRate.toStringAsFixed(1)),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _confirmResetDuelStats(ctx, notifier);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.duelResetStats),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            await notifier.setUserName(name);
                          }
                          await notifier.setDuelDuration(selectedDuration);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.deepPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _confirmResetDuelStats(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
        title: Text(l10n.clearStatsTitle),
        content: Text(l10n.clearStatsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              await notifier.resetDuelStats();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clearAction),
          ),
        ],
        );
      },
    );
  }

  // === WIDGET VERSION ===

  Widget _buildVersionTile(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.info_outline, color: Colors.blue),
      ),
      title: Text(AppLocalizations.of(context).version),
      subtitle: Text(
        BuildInfo.versionWithDate,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      onTap: () => _showAboutDialog(context),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.extension, color: Colors.deepPurple.shade400),
            const SizedBox(width: 12),
            const Text(BuildInfo.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutRow(l10n.version, BuildInfo.fullVersion),
            _buildAboutRow(l10n.buildLabel, BuildInfo.buildDateFormatted),
            _buildAboutRow(l10n.aboutAuthor, BuildInfo.author),
            const Divider(height: 24),
            Text(
              BuildInfo.description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© ${BuildInfo.copyrightYear} ${BuildInfo.author}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
        );
      },
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // === HELPERS EXISTANTS ===

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  String _colorSchemeName(AppLocalizations l10n, PieceColorScheme scheme) {
    switch (scheme) {
      case PieceColorScheme.classic:
        return l10n.colorSchemeClassic;
      case PieceColorScheme.pastel:
        return l10n.colorSchemePastel;
      case PieceColorScheme.neon:
        return l10n.colorSchemeNeon;
      case PieceColorScheme.monochrome:
        return l10n.colorSchemeMonochrome;
      case PieceColorScheme.rainbow:
        return l10n.colorSchemeRainbow;
      case PieceColorScheme.custom:
        return l10n.colorSchemeCustom;
    }
  }

  /// Libellé du choix de langue (Système = suit l'appareil).
  String _languageName(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'fr':
        return l10n.languageFrench;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }

  void _showLanguageDialog(
      BuildContext context, SettingsNotifier notifier, String? current) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        // null = Système ; 'fr'/'en' = forcé.
        final options = <String?>[null, 'fr', 'en'];
        return AlertDialog(
          title: Text(l10n.settingsLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((code) {
              return RadioListTile<String?>(
                title: Text(_languageName(l10n, code)),
                value: code,
                groupValue: current,
                onChanged: (value) {
                  notifier.setLocale(value);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showColorSchemeDialog(
      BuildContext context,
      SettingsNotifier notifier,
      PieceColorScheme current,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
        title: Text(l10n.pieceColors),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PieceColorScheme.values.map((scheme) {
            return RadioListTile<PieceColorScheme>(
              title: Text(_colorSchemeName(l10n, scheme)),
              value: scheme,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  notifier.setColorScheme(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        );
      },
    );
  }

}
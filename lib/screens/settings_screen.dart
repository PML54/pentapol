// Modified: 2026-09-01 08:58 — sortie fiable sur iPad : bouton « Fermer » ancré en bas
//           (bottomNavigationBar) + SafeArea, la flèche retour du haut étant recouverte par les
//           commandes multitâche d'iPadOS.
// lib/screens/settings_screen.dart
// Historique: 2026-08-31 09:45 — PLAN_ERGONOMIE §8 (décision 62) : écran de réglages minimal —
//             retrait des 9 entrées mortes (numéros, grille, animations, opacité, taille d'icônes,
//             couleur isométries, difficulté, indices, chrono) et de leurs helpers orphelins.
//             Restent : couleurs, personnaliser, compteur de solutions, haptique, drag, Duel, À propos.
// Historique: 2025-11-30 — Ajout section Duel et version.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Réinitialiser'),
                  content: const Text(
                    'Voulez-vous réinitialiser tous les paramètres par défaut ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Réinitialiser'),
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
            label: const Text('Fermer'),
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
          _buildSectionHeader('Interface'),

          // Schéma de couleurs
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Couleurs des pièces'),
            subtitle: Text(_getColorSchemeName(settings.ui.colorScheme)),
            onTap: () => _showColorSchemeDialog(context, notifier, settings.ui.colorScheme),
          ),

          // Personnaliser les couleurs (visible si schéma custom)
          if (settings.ui.colorScheme == PieceColorScheme.custom)
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Personnaliser les couleurs'),
              subtitle: const Text('Définir les 12 couleurs des pièces'),
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
          _buildSectionHeader('Jeu'),

          // Compteur de solutions
          SwitchListTile(
            secondary: const Icon(Icons.emoji_events),
            title: const Text('Compteur de solutions'),
            subtitle: const Text('Afficher le nombre de solutions possibles'),
            value: settings.game.showSolutionCounter,
            onChanged: (value) => notifier.setShowSolutionCounter(value),
          ),

          // Retour haptique
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Retour haptique'),
            subtitle: const Text('Vibrations lors des actions'),
            value: settings.game.enableHaptics,
            onChanged: (value) => notifier.setEnableHaptics(value),
          ),

          // Durée du long press
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: const Text('Sensibilité du drag'),
            subtitle: Text('${settings.game.longPressDuration}ms'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: settings.game.longPressDuration > 100
                      ? () => notifier.setLongPressDuration(settings.game.longPressDuration - 50)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: settings.game.longPressDuration < 500
                      ? () => notifier.setLongPressDuration(settings.game.longPressDuration + 50)
                      : null,
                ),
              ],
            ),
          ),

          const Divider(),

          // === SECTION DUEL ===
          _buildSectionHeader('Mode Duel'),

          // Tile pour accéder aux paramètres Duel
          _buildDuelSettingsTile(context, ref, settings),

          const Divider(),

          // === SECTION À PROPOS ===
          _buildSectionHeader('À propos'),

          // Version de l'app
          _buildVersionTile(context),

          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  // === WIDGETS DUEL ===

  Widget _buildDuelSettingsTile(BuildContext context, WidgetRef ref, AppSettings settings) {
    final playerName = settings.duel.playerName ?? 'Non défini';
    final duration = settings.duel.durationFormatted;
    final stats = '${settings.duel.totalWins}V / ${settings.duel.totalLosses}D / ${settings.duel.totalDraws}N';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.sports_esports, color: Colors.deepPurple),
      ),
      title: const Text('Paramètres Duel'),
      subtitle: Text('$playerName • $duration • $stats'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDuelSettingsDialog(context, ref),
    );
  }

  void _showDuelSettingsDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Controllers
    final nameController = TextEditingController(text: settings.duel.playerName ?? '');
    DuelDuration selectedDuration = settings.duel.duration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                    const Text(
                      'Paramètres Duel',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    labelText: 'Nom du joueur',
                    hintText: 'Entrez votre pseudo',
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
                const Text(
                  'Durée de partie',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
                      const Text(
                        '📊 Statistiques',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Parties', '${settings.duel.totalGamesPlayed}', Icons.sports_esports),
                          _buildStatColumn('Victoires', '${settings.duel.totalWins}', Icons.emoji_events, Colors.green),
                          _buildStatColumn('Défaites', '${settings.duel.totalLosses}', Icons.close, Colors.red),
                          _buildStatColumn('Égalités', '${settings.duel.totalDraws}', Icons.handshake, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Taux de victoire : ${settings.duel.winRate.toStringAsFixed(1)}%',
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
                        child: const Text('Réinit. stats'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            await notifier.setDuelPlayerName(name);
                          }
                          await notifier.setDuelDuration(selectedDuration);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Sauvegarder'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer les statistiques ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await notifier.resetDuelStats();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
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
      title: const Text('Version'),
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
      builder: (ctx) => AlertDialog(
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
            _buildAboutRow('Version', BuildInfo.fullVersion),
            _buildAboutRow('Build', BuildInfo.buildDateFormatted),
            _buildAboutRow('Auteur', BuildInfo.author),
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
            child: const Text('Fermer'),
          ),
        ],
      ),
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

  String _getColorSchemeName(PieceColorScheme scheme) {
    switch (scheme) {
      case PieceColorScheme.classic:
        return 'Classique';
      case PieceColorScheme.pastel:
        return 'Pastel';
      case PieceColorScheme.neon:
        return 'Néon';
      case PieceColorScheme.monochrome:
        return 'Monochrome';
      case PieceColorScheme.rainbow:
        return 'Arc-en-ciel';
      case PieceColorScheme.custom:
        return 'Personnalisé';
    }
  }

  void _showColorSchemeDialog(
      BuildContext context,
      SettingsNotifier notifier,
      PieceColorScheme current,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Couleurs des pièces'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PieceColorScheme.values.map((scheme) {
            return RadioListTile<PieceColorScheme>(
              title: Text(_getColorSchemeName(scheme)),
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
      ),
    );
  }

}
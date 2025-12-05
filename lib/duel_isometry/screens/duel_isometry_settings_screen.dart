// lib/duel/screens/duel_settings_screen.dart
// Écran de paramétrage du mode Duel
// Peut être utilisé standalone ou intégré dans settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/providers/settings_provider.dart';
// Import du nouveau DuelSettings (à mettre dans app_settings.dart)
// import 'package:pentapol/models/app_settings.dart';

// === ENUMS (à déplacer dans app_settings.dart) ===

/// Durée de partie prédéfinie
enum DuelDuration {
  short,    // 1 minute
  normal,   // 3 minutes (défaut)
  long,     // 5 minutes
  marathon, // 10 minutes
  custom,   // Durée personnalisée
}

extension DuelDurationExtension on DuelDuration {
  int get seconds {
    switch (this) {
      case DuelDuration.short: return 60;
      case DuelDuration.normal: return 180;
      case DuelDuration.long: return 300;
      case DuelDuration.marathon: return 600;
      case DuelDuration.custom: return 180;
    }
  }

  String get label {
    switch (this) {
      case DuelDuration.short: return '1 min';
      case DuelDuration.normal: return '3 min';
      case DuelDuration.long: return '5 min';
      case DuelDuration.marathon: return '10 min';
      case DuelDuration.custom: return 'Perso';
    }
  }

  String get icon {
    switch (this) {
      case DuelDuration.short: return '⚡';
      case DuelDuration.normal: return '⏱️';
      case DuelDuration.long: return '🕐';
      case DuelDuration.marathon: return '🏃';
      case DuelDuration.custom: return '⚙️';
    }
  }
}

// === ÉCRAN PRINCIPAL ===

class DuelSettingsScreen extends ConsumerStatefulWidget {
  const DuelSettingsScreen({super.key});

  @override
  ConsumerState<DuelSettingsScreen> createState() => _DuelSettingsScreenState();
}

class _DuelSettingsScreenState extends ConsumerState<DuelSettingsScreen> {
  // Controllers pour les champs texte
  late TextEditingController _nameController;
  late TextEditingController _customDurationController;

  // État local pour preview
  DuelDuration _selectedDuration = DuelDuration.normal;
  double _guideOpacity = 0.35;
  double _hatchOpacity = 0.4;
  bool _showGuide = true;
  bool _showHatch = true;
  bool _enableSounds = true;
  bool _enableVibration = true;
  bool _showOpponentProgress = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customDurationController = TextEditingController(text: '180');

    // Charger les valeurs actuelles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final settings = ref.read(settingsProvider);
    final duel = settings.duel;

    setState(() {
      _nameController.text = duel.playerName ?? '';
      // Quand DuelSettings sera enrichi, charger les autres valeurs ici
      // _selectedDuration = duel.duration;
      // _customDurationController.text = duel.customDurationSeconds.toString();
      // _guideOpacity = duel.guideOpacity;
      // etc.
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres Duel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaults,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === SECTION : Identité ===
          _buildSectionHeader('👤 Identité', Icons.person),
          _buildNameField(),
          const SizedBox(height: 24),

          // === SECTION : Durée de partie ===
          _buildSectionHeader('⏱️ Durée de partie', Icons.timer),
          _buildDurationSelector(),
          if (_selectedDuration == DuelDuration.custom)
            _buildCustomDurationField(),
          const SizedBox(height: 24),

          // === SECTION : Affichage ===
          _buildSectionHeader('👁️ Affichage', Icons.visibility),
          _buildSwitchTile(
            title: 'Guide de solution',
            subtitle: 'Afficher la solution en filigrane',
            value: _showGuide,
            onChanged: (v) => setState(() => _showGuide = v),
          ),
          if (_showGuide)
            _buildSliderTile(
              title: 'Opacité du guide',
              value: _guideOpacity,
              min: 0.1,
              max: 0.5,
              divisions: 8,
              label: '${(_guideOpacity * 100).round()}%',
              onChanged: (v) => setState(() => _guideOpacity = v),
            ),
          _buildSwitchTile(
            title: 'Pièces adversaire visibles',
            subtitle: 'Voir les placements en temps réel',
            value: _showOpponentProgress,
            onChanged: (v) => setState(() => _showOpponentProgress = v),
          ),
          if (_showOpponentProgress)
            _buildSwitchTile(
              title: 'Hachures sur pièces adversaire',
              subtitle: 'Distinguer visuellement les pièces',
              value: _showHatch,
              onChanged: (v) => setState(() => _showHatch = v),
            ),
          if (_showOpponentProgress && _showHatch)
            _buildSliderTile(
              title: 'Opacité des hachures',
              value: _hatchOpacity,
              min: 0.2,
              max: 0.6,
              divisions: 8,
              label: '${(_hatchOpacity * 100).round()}%',
              onChanged: (v) => setState(() => _hatchOpacity = v),
            ),
          const SizedBox(height: 24),

          // === SECTION : Feedback ===
          _buildSectionHeader('📳 Feedback', Icons.vibration),
          _buildSwitchTile(
            title: 'Sons',
            subtitle: 'Placement, victoire, défaite',
            value: _enableSounds,
            onChanged: (v) => setState(() => _enableSounds = v),
          ),
          _buildSwitchTile(
            title: 'Vibrations',
            subtitle: 'Retour haptique',
            value: _enableVibration,
            onChanged: (v) => setState(() => _enableVibration = v),
          ),
          const SizedBox(height: 24),

          // === SECTION : Statistiques ===
          _buildSectionHeader('📊 Statistiques', Icons.bar_chart),
          _buildStatsCard(),
          const SizedBox(height: 32),

          // === Bouton Sauvegarder ===
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Sauvegarder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === WIDGETS HELPER ===

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nom du joueur',
        hintText: 'Entrez votre pseudo',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLength: 20,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildDurationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DuelDuration.values.map((duration) {
        final isSelected = _selectedDuration == duration;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(duration.icon),
              const SizedBox(width: 4),
              Text(duration.label),
            ],
          ),
          selected: isSelected,
          selectedColor: Colors.deepPurple.shade100,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedDuration = duration);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildCustomDurationField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Durée (secondes)',
                hintText: '60 - 1800',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDuration(int.tryParse(_customDurationController.text) ?? 180),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey.shade600)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Colors.deepPurple,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(label, style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Colors.deepPurple,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    // TODO: Lire les vraies stats depuis settings.duel
    final gamesPlayed = 0;
    final wins = 0;
    final losses = 0;
    final draws = 0;
    final winRate = gamesPlayed > 0 ? (wins / gamesPlayed * 100) : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Parties', '$gamesPlayed', Icons.sports_esports),
                _buildStatItem('Victoires', '$wins', Icons.emoji_events, color: Colors.green),
                _buildStatItem('Défaites', '$losses', Icons.close, color: Colors.red),
                _buildStatItem('Égalités', '$draws', Icons.handshake, color: Colors.orange),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.percent, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Taux de victoire : ${winRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _confirmResetStats,
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Réinitialiser les statistiques'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.deepPurple, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // === ACTIONS ===

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) return '$mins min';
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();

    // Sauvegarder le nom (méthode existante)
    if (name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setDuelPlayerName(name);
    }

    // TODO: Quand DuelSettings sera enrichi, sauvegarder les autres paramètres :
    // await ref.read(settingsProvider.notifier).setDuelDuration(_selectedDuration);
    // await ref.read(settingsProvider.notifier).setDuelGuideOpacity(_guideOpacity);
    // etc.

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paramètres sauvegardés'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser ?'),
        content: const Text(
          'Remettre tous les paramètres à leur valeur par défaut ?\n'
              '(Le nom et les statistiques seront conservés)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedDuration = DuelDuration.normal;
                _customDurationController.text = '180';
                _guideOpacity = 0.35;
                _hatchOpacity = 0.4;
                _showGuide = true;
                _showHatch = true;
                _enableSounds = true;
                _enableVibration = true;
                _showOpponentProgress = true;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _confirmResetStats() {
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
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: ref.read(settingsProvider.notifier).resetDuelStats();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Statistiques effacées'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// WIDGET À INTÉGRER DANS settings_screen.dart (section Duel)
// ============================================================

/// Tile pour accéder aux paramètres Duel depuis l'écran principal
class DuelSettingsTile extends ConsumerWidget {
  const DuelSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final playerName = settings.duel.playerName ?? 'Non défini';
    // TODO: final duration = settings.duel.durationFormatted;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.sports_esports, color: Colors.deepPurple),
      ),
      title: const Text('Mode Duel'),
      subtitle: Text('Joueur : $playerName'), // TODO: ajouter durée
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DuelSettingsScreen()),
        );
      },
    );
  }
}
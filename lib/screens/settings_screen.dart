// Modified: 2025-11-16 09:45:00
// lib/screens/settings_screen.dart
// Écran de paramètres de l'application

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

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
      body: ListView(
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
          
          // Afficher numéros
          SwitchListTile(
            secondary: const Icon(Icons.numbers),
            title: const Text('Numéros sur les pièces'),
            subtitle: const Text('Afficher les numéros des pièces'),
            value: settings.ui.showPieceNumbers,
            onChanged: (value) => notifier.setShowPieceNumbers(value),
          ),
          
          // Lignes de grille
          SwitchListTile(
            secondary: const Icon(Icons.grid_on),
            title: const Text('Lignes de grille'),
            subtitle: const Text('Afficher les lignes du plateau'),
            value: settings.ui.showGridLines,
            onChanged: (value) => notifier.setShowGridLines(value),
          ),
          
          // Animations
          SwitchListTile(
            secondary: const Icon(Icons.animation),
            title: const Text('Animations'),
            subtitle: const Text('Activer les animations'),
            value: settings.ui.enableAnimations,
            onChanged: (value) => notifier.setEnableAnimations(value),
          ),
          
          // Opacité des pièces
          ListTile(
            leading: const Icon(Icons.opacity),
            title: const Text('Opacité des pièces'),
            subtitle: Slider(
              value: settings.ui.pieceOpacity,
              min: 0.3,
              max: 1.0,
              divisions: 7,
              label: '${(settings.ui.pieceOpacity * 100).round()}%',
              onChanged: (value) => notifier.setPieceOpacity(value),
            ),
          ),
          
          const Divider(),
          
          // === SECTION JEU ===
          _buildSectionHeader('Jeu'),
          
          // Niveau de difficulté
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Niveau de difficulté'),
            subtitle: Text(_getDifficultyName(settings.game.difficulty)),
            onTap: () => _showDifficultyDialog(context, notifier, settings.game.difficulty),
          ),
          
          // Compteur de solutions
          SwitchListTile(
            secondary: const Icon(Icons.emoji_events),
            title: const Text('Compteur de solutions'),
            subtitle: const Text('Afficher le nombre de solutions possibles'),
            value: settings.game.showSolutionCounter,
            onChanged: (value) => notifier.setShowSolutionCounter(value),
          ),
          
          // Indices
          SwitchListTile(
            secondary: const Icon(Icons.lightbulb_outline),
            title: const Text('Indices'),
            subtitle: const Text('Activer les indices visuels'),
            value: settings.game.enableHints,
            onChanged: (value) => notifier.setEnableHints(value),
          ),
          
          // Chronomètre
          SwitchListTile(
            secondary: const Icon(Icons.timer),
            title: const Text('Chronomètre'),
            subtitle: const Text('Afficher le temps de résolution'),
            value: settings.game.enableTimer,
            onChanged: (value) => notifier.setEnableTimer(value),
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
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
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
    }
  }
  
  String _getDifficultyName(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Facile';
      case GameDifficulty.normal:
        return 'Normal';
      case GameDifficulty.hard:
        return 'Difficile';
      case GameDifficulty.expert:
        return 'Expert';
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
  
  void _showDifficultyDialog(
    BuildContext context,
    SettingsNotifier notifier,
    GameDifficulty current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Niveau de difficulté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameDifficulty.values.map((difficulty) {
            return RadioListTile<GameDifficulty>(
              title: Text(_getDifficultyName(difficulty)),
              value: difficulty,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  notifier.setDifficulty(value);
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


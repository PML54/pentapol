// Modified: 2025-12-02
// lib/screens/home_screen.dart
// Menu principal avec Duel Isométries

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pentomino_game_screen.dart';
import 'settings_screen.dart';
import 'solutions_browser_screen.dart';
import '../duel/screens/duel_home_screen.dart';
import '../duel_isometry/screens/duel_isometry_home_screen.dart';
import '../duel_isometry/screens/duel_isometry_game_screen.dart';
import '../pentoscope/screens/pentoscope_menu_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pentapol'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(Icons.grid_3x3, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Pentapol',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Puzzles de pentominos',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Jeu classique
          _buildMenuCard(
            context: context,
            title: 'Jeu Classique',
            subtitle: 'Placer 12 pièces sur un plateau 6×10',
            icon: Icons.games,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PentominoGameScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Pentoscope
          _buildMenuCard(
            context: context,
            title: 'Pentoscope',
            subtitle: 'Mini-puzzles pour débutants (3-6 pièces)',
            icon: Icons.auto_awesome,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PentoscopeMenuScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Mode Duel Classique
          _buildMenuCard(
            context: context,
            title: 'Duel Classique',
            subtitle: 'Course aux placements en temps réel',
            icon: Icons.people,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DuelHomeScreen(),
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/isopento_menu');
            },
            child: const Text('isopento'),
          ),
          const SizedBox(height: 16),

          // Mode Duel Isométries - NOUVEAU
          _buildMenuCard(
            context: context,
            title: 'Duel Isométries',
            subtitle: 'Reconstruisez la cible avec le moins de transformations',
            icon: Icons.rotate_90_degrees_ccw,
            color: Colors.purple,
            badge: 'NOUVEAU',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DuelIsometryHomeScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Navigateur de solutions
          _buildMenuCard(
            context: context,
            title: 'Solutions',
            subtitle: 'Explorer les 2339 solutions canoniques',
            icon: Icons.explore,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SolutionsBrowserScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Tutoriels (TODO)
          _buildMenuCard(
            context: context,
            title: 'Tutoriels',
            subtitle: 'Apprendre à jouer avec des guides interactifs',
            icon: Icons.school,
            color: Colors.blueGrey,
            enabled: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutoriels à venir prochainement'),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Statistiques (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Parties jouées', '0'),
                  _buildStatRow('Puzzles complétés', '0'),
                  _buildStatRow('Meilleur temps', '--:--'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: enabled ? 2 : 0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled ? color : Colors.grey,
                ),
              ),

              const SizedBox(width: 16),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: enabled ? null : Colors.grey,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled ? Colors.grey : Colors.grey.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
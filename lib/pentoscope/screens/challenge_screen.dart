// Modified: 2026-09-05 00:20 — Phase 5 : icône « classement » par taille → LeaderboardScreen.
// lib/pentoscope/screens/challenge_screen.dart
// Historique: 2026-09-04 07:05 — création : écran « Défi de la semaine » (CDC §7, Phase 2). Choix
//           d'une des six tailles ; lance le défi dérivé (mode classé) puis l'écran de jeu. HORS V1.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/challenge.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';
import 'package:pentapol/pentoscope/screens/leaderboard_screen.dart';

/// Écran de sélection du défi de la semaine : le joueur choisit une dimension de plateau, tout le
/// reste (masque + rack) est dérivé de la semaine courante (CDC §7.1). Mode classé.
class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = weeksSinceEpoch(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Défi de la semaine')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Semaine $week',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisis une taille. La configuration est la même pour tous cette semaine, '
              'et l\'indice est désactivé (mode classé).',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            for (final size in kChallengeSizes)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined, color: Color(0xFF2E9E5B)),
                  title: Text(
                    '${size.width}×${size.height}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${size.numPieces} pièces'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.leaderboard_outlined),
                        tooltip: 'Classement',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeaderboardScreen(
                              week: weeksSinceEpoch(DateTime.now()),
                              size: size,
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.play_arrow),
                    ],
                  ),
                  onTap: () => _launch(context, ref, size),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(
      BuildContext context, WidgetRef ref, PentoscopeSize size) async {
    await ref.read(pentoscopeProvider.notifier).startWeeklyChallenge(size);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PentoscopeGameScreen()),
    );
  }
}

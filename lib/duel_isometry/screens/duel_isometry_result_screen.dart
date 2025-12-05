// lib/duel/screens/duel_result_screen.dart
// Écran de résultat de la partie

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/duel_isometry_provider.dart';
import '../models/duel_isometry_state.dart';
import 'duel_isometry_home_screen.dart';

class DuelResultScreen extends ConsumerWidget {
  const DuelResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelState = ref.watch(duelIsometryProvider);

    final isWinner = duelState.isWinner;
    final isDraw = duelState.isDraw;
    final localScore = duelState.localScore;
    final opponentScore = duelState.opponentScore;
    final localName = duelState.localPlayer?.name ?? 'Vous';
    final opponentName = duelState.opponent?.name ?? 'Adversaire';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDraw
                ? [Colors.grey.shade300, Colors.grey.shade100]
                : isWinner
                ? [Colors.green.shade300, Colors.green.shade50]
                : [Colors.red.shade300, Colors.red.shade50],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Icône
                Icon(
                  isDraw
                      ? Icons.handshake
                      : isWinner
                      ? Icons.emoji_events
                      : Icons.sentiment_dissatisfied,
                  size: 100,
                  color: isDraw
                      ? Colors.grey.shade700
                      : isWinner
                      ? Colors.amber
                      : Colors.red.shade700,
                ),
                const SizedBox(height: 24),

                // Titre
                Text(
                  isDraw
                      ? 'Égalité !'
                      : isWinner
                      ? 'Victoire ! 🎉'
                      : 'Défaite...',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isDraw
                        ? Colors.grey.shade800
                        : isWinner
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 32),

                // Scores
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Joueur local
                      _ScoreRow(
                        name: localName,
                        score: localScore,
                        isWinner: isWinner && !isDraw,
                        isLocal: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      // Adversaire
                      _ScoreRow(
                        name: opponentName,
                        score: opponentScore,
                        isWinner: !isWinner && !isDraw,
                        isLocal: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Détails
                Text(
                  'Pièces totales placées: ${localScore + opponentScore}/12',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // Boutons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Revanche - retourner au lobby
                      ref.read(duelIsometryProvider.notifier).leaveRoom();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DuelIsometryHomeScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Nouvelle partie',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bouton retour menu principal
                TextButton(
                  onPressed: () {
                    ref.read(duelIsometryProvider.notifier).leaveRoom();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'Retour au menu principal',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;
  final bool isLocal;

  const _ScoreRow({
    required this.name,
    required this.score,
    required this.isWinner,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icône joueur
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLocal ? Colors.blue.shade100 : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocal ? Icons.person : Icons.person_outline,
            color: isLocal ? Colors.blue : Colors.grey,
          ),
        ),
        const SizedBox(width: 16),

        // Nom
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green.shade700 : Colors.black87,
                ),
              ),
              if (isLocal)
                Text(
                  'Vous',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isWinner ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pièces',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (isWinner) ...[
                const SizedBox(width: 8),
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
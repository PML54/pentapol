// lib/duel_isometry/screens/duel_isometry_result_screen.dart
// Écran de résultat d'un round

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/duel_isometry_provider.dart';
import '../models/duel_isometry_state.dart';

class DuelIsometryResultScreen extends ConsumerWidget {
  const DuelIsometryResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelIsometryProvider);
    final result = state.roundResult;

    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isWinner = result.winnerId == state.localPlayer?.id;
    final isTie = result.winnerId == null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Round ${state.roundNumber} terminé'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Titre résultat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isWinner
                      ? Colors.green.shade100
                      : (isTie ? Colors.amber.shade100 : Colors.red.shade100),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWinner
                        ? Colors.green
                        : (isTie ? Colors.amber : Colors.red),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isWinner
                          ? Icons.emoji_events
                          : (isTie ? Icons.handshake : Icons.sentiment_dissatisfied),
                      size: 48,
                      color: isWinner
                          ? Colors.amber
                          : (isTie ? Colors.orange : Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isWinner
                          ? 'VICTOIRE !'
                          : (isTie ? 'ÉGALITÉ' : 'DÉFAITE'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isWinner
                            ? Colors.green.shade800
                            : (isTie ? Colors.amber.shade800 : Colors.red.shade800),
                      ),
                    ),
                    if (!isTie)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          isWinner
                              ? 'Moins d\'isométries !'
                              : 'L\'adversaire a utilisé moins d\'isométries',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Comparaison des stats
              Row(
                children: [
                  Expanded(
                    child: _buildPlayerStats(
                      name: state.localPlayer?.name ?? 'Vous',
                      isometries: result.localIsometries,
                      optimal: result.optimalIsometries,
                      timeMs: result.localTimeMs,
                      isWinner: isWinner,
                      color: Colors.cyan,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _buildPlayerStats(
                      name: state.opponent?.name ?? 'Adversaire',
                      isometries: result.opponentIsometries,
                      optimal: result.optimalIsometries,
                      timeMs: result.opponentTimeMs,
                      isWinner: !isWinner && !isTie,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Score global
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${state.localScore}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${state.opponentScore}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bouton continuer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Lancer le prochain round ou retourner au menu
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    state.roundNumber < state.totalRounds
                        ? 'Round suivant'
                        : 'Voir résultat final',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerStats({
    required String name,
    required int isometries,
    required int optimal,
    required int timeMs,
    required bool isWinner,
    required Color color,
  }) {
    final efficiency = optimal > 0 && isometries > 0
        ? (optimal / isometries * 100).clamp(0.0, 100.0)
        : 0.0;
    final timeSeconds = timeMs / 1000;
    final timeStr = '${timeSeconds.toStringAsFixed(1)}s';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isWinner ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow('Isométries', '$isometries', color),
          _buildStatRow('Optimal', '$optimal', Colors.grey.shade600),
          _buildStatRow(
            'Efficacité',
            '${efficiency.toStringAsFixed(1)}%',
            efficiency >= 80
                ? Colors.green
                : (efficiency >= 60 ? Colors.orange : Colors.red),
          ),
          _buildStatRow('Temps', timeStr, Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
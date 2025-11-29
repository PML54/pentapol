// lib/duel/screens/duel_game_screen.dart
// Écran principal du jeu duel (plateau partagé)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/duel_provider.dart';
import '../models/duel_state.dart';
import '../widgets/duel_scoreboard.dart';
import '../widgets/duel_countdown.dart';
import 'duel_result_screen.dart';

class DuelGameScreen extends ConsumerWidget {
  const DuelGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelState = ref.watch(duelProvider);

    // Écouter la fin de partie
    ref.listen<DuelState>(duelProvider, (previous, next) {
      if (next.gameState == DuelGameState.ended &&
          previous?.gameState != DuelGameState.ended) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DuelResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal
            Column(
              children: [
                // Barre de score
                DuelScoreboard(
                  player1Name: duelState.localPlayer?.name ?? 'Moi',
                  player1Score: duelState.localScore,
                  player2Name: duelState.opponent?.name ?? 'Adversaire',
                  player2Score: duelState.opponentScore,
                  timeRemaining: duelState.timeRemaining ?? 0,
                  isPlayer1Local: true,
                ),

                // Message d'erreur
                if (duelState.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Text(
                      duelState.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),

                // Zone de jeu
                Expanded(
                  child: _buildGameArea(context, ref, duelState),
                ),

                // Slider des pièces (TODO: implémenter avec le vrai slider)
                Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      'TODO: Slider des pièces\n'
                          'Pièces placées: ${duelState.placedPieces.length}/12',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ],
            ),

            // Overlay countdown (3, 2, 1, GO!)
            if (duelState.gameState == DuelGameState.countdown &&
                duelState.countdown != null)
              DuelCountdown(value: duelState.countdown!),
          ],
        ),
      ),
    );
  }

  Widget _buildGameArea(BuildContext context, WidgetRef ref, DuelState state) {
    // TODO: Intégrer le vrai plateau de jeu ici
    // Pour l'instant, affichage de debug

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Info solution
          Text(
            'Solution #${state.solutionId ?? "?"}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Placeholder plateau
          Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'PLATEAU\n6 × 10',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Liste des pièces placées
          if (state.placedPieces.isNotEmpty) ...[
            const Text(
              'Pièces placées:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: state.placedPieces.map((piece) {
                final isLocal = piece.ownerId == state.localPlayer?.id;
                return Chip(
                  label: Text('P${piece.pieceId}'),
                  backgroundColor: isLocal ? Colors.green.shade100 : Colors.red.shade100,
                  avatar: Icon(
                    isLocal ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: isLocal ? Colors.green : Colors.red,
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Bouton de test (temporaire)
          ElevatedButton(
            onPressed: () {
              // Simuler un placement de pièce
              final pieceId = state.placedPieces.length + 1;
              if (pieceId <= 12) {
                ref.read(duelProvider.notifier).placePiece(
                  pieceId: pieceId,
                  x: pieceId - 1,
                  y: 0,
                  orientation: 0,
                );
              }
            },
            child: const Text('TEST: Placer une pièce'),
          ),
        ],
      ),
    );
  }
}
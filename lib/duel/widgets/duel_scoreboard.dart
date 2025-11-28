// lib/duel/widgets/duel_scoreboard.dart
// Barre de score affichant les 2 joueurs et le timer

import 'package:flutter/material.dart';

class DuelScoreboard extends StatelessWidget {
  final String player1Name;
  final int player1Score;
  final String player2Name;
  final int player2Score;
  final int timeRemaining;
  final bool isPlayer1Local;

  const DuelScoreboard({
    super.key,
    required this.player1Name,
    required this.player1Score,
    required this.player2Name,
    required this.player2Score,
    required this.timeRemaining,
    required this.isPlayer1Local,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          // Joueur 1
          Expanded(
            child: _PlayerScore(
              name: player1Name,
              score: player1Score,
              isLocal: isPlayer1Local,
            ),
          ),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: timeRemaining < 30 ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(timeRemaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Joueur 2
          Expanded(
            child: _PlayerScore(
              name: player2Name,
              score: player2Score,
              isLocal: !isPlayer1Local,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final int score;
  final bool isLocal;
  final bool alignRight;

  const _PlayerScore({
    required this.name,
    required this.score,
    required this.isLocal,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal) const Icon(Icons.person, size: 16, color: Colors.green),
            if (isLocal) const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        Text(
          '$score pièces',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// lib/duel/screens/duel_game_screen.dart
// Écran principal du jeu duel (plateau partagé)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelGameScreen extends ConsumerWidget {
  const DuelGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duel en cours'),
        // TODO: Afficher timer, scores
      ),
      body: Column(
        children: [
          // TODO: Barre de score
          // - Nom joueur 1 : score
          // - Timer
          // - Nom joueur 2 : score

          // TODO: Plateau de jeu partagé
          // - Pièces du joueur local en couleur normale
          // - Pièces de l'adversaire avec hachures

          // TODO: Slider des pièces
          // - Pièces disponibles
          // - Pièces déjà placées grisées
        ],
      ),
    );
  }
}

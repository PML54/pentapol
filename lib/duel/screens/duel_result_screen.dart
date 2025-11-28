// lib/duel/screens/duel_result_screen.dart
// Écran de résultat de la partie

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelResultScreen extends ConsumerWidget {
  const DuelResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Afficher victoire/défaite/égalité
            const Icon(
              Icons.emoji_events,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Victoire !',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Afficher les scores
            const Text('Vous : 7 - Adversaire : 5'),
            const SizedBox(height: 48),
            // TODO: Boutons rejouer / retour
            ElevatedButton(
              onPressed: () {
                // TODO: Revanche
              },
              child: const Text('Revanche'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: Retour au menu
              },
              child: const Text('Retour au menu'),
            ),
          ],
        ),
      ),
    );
  }
}

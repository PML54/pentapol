// lib/duel/screens/duel_home_screen.dart
// Écran d'accueil du mode duel (créer/rejoindre)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelHomeScreen extends ConsumerWidget {
  const DuelHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Duel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Bouton Créer une partie
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers création
              },
              child: const Text('Créer une partie'),
            ),
            const SizedBox(height: 20),
            // TODO: Bouton Rejoindre une partie
            ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers rejoindre
              },
              child: const Text('Rejoindre une partie'),
            ),
          ],
        ),
      ),
    );
  }
}

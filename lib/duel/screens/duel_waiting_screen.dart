// lib/duel/screens/duel_waiting_screen.dart
// Écran d'attente d'un adversaire

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuelWaitingScreen extends ConsumerWidget {
  final String roomCode;

  const DuelWaitingScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Code de la partie',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            // TODO: Afficher le code en grand
            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Boutons Copier / Partager
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Partager
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Partager'),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('En attente d\'un adversaire...'),
          ],
        ),
      ),
    );
  }
}

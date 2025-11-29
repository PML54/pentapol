// lib/duel/screens/duel_waiting_screen.dart
// Écran d'attente d'un adversaire (affiche le code)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/duel_provider.dart';
import '../models/duel_state.dart';
import 'duel_game_screen.dart';

class DuelWaitingScreen extends ConsumerWidget {
  const DuelWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelState = ref.watch(duelProvider);
    final roomCode = duelState.roomCode ?? '------';

    // Écouter les changements pour naviguer automatiquement
    ref.listen<DuelState>(duelProvider, (previous, next) {
      // Un adversaire a rejoint et la partie commence
      if (next.gameState == DuelGameState.countdown ||
          next.gameState == DuelGameState.playing) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DuelGameScreen(),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('En attente...'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(duelProvider.notifier).leaveRoom();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation d'attente
              const SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              const Text(
                'Partagez ce code',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Code de la room (grand et visible)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 2,
                  ),
                ),
                child: Text(
                  roomCode,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons Copier / Partager
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouton Copier
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Code copié ! 📋'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Bouton Partager
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        '🎮 Viens jouer à Pentapol avec moi !\n\n'
                            'Code : $roomCode\n\n'
                            'Télécharge l\'app et rejoins-moi !',
                        subject: 'Partie Pentapol',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Message d'attente
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'En attente d\'un adversaire...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              // Afficher l'adversaire s'il est connecté
              if (duelState.opponent != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '${duelState.opponent!.name} a rejoint !',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'La partie va commencer...',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],

              const Spacer(),

              // Bouton Annuler
              TextButton(
                onPressed: () {
                  ref.read(duelProvider.notifier).leaveRoom();
                  Navigator.pop(context);
                },
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
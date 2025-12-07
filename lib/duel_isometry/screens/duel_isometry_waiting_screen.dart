// lib/duel_isometry/screens/duel_isometry_waiting_screen.dart
// Écran d'attente du 2e joueur - affiche plateau quand prêt
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/duel_isometry_provider.dart';
import '../widgets/duel_isometry_plateau.dart';
import '../models/duel_isometry_state.dart';
import 'duel_isometry_game_screen.dart';
class DuelIsometryWaitingScreen extends ConsumerWidget {
  const DuelIsometryWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(duelIsometryProvider);


    // Si le plateau est prêt, afficher le jeu au lieu d'attendre
    if (state.plateau != null &&
        (state.gameState == DuelGameState.countdown ||
            state.gameState == DuelGameState.playing)) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DuelIsometryGameScreen()),
        );
      });


    }

    return WillPopScope(
      onWillPop: () async {
        ref.read(duelIsometryProvider.notifier).leaveRoom();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duel Isométries'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.purple),
              const SizedBox(height: 32),
              Text(
                'Code: ${state.roomCode ?? "..."}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (state.opponent != null)
                Text(
                  '${state.opponent!.name} a rejoint !',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                )
              else
                const Text(
                  'En attente du 2e joueur...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              if (state.plateau != null)
                const Text(
                  'Plateau généré, démarrage...',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(duelIsometryProvider.notifier).leaveRoom();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


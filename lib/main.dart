// Modified: 2026-08-29 14:09 — suppression du mode classique (§2/§3.1, étape 7) : retrait de
//           l'amorce de solutionsReadyProvider et de son import (le provider et le singleton
//           global des 9356 disparaissent avec le module). L'entrée du mode classique avait
//           déjà été coupée à l'étape 6.
// lib/main.dart
// Historique: 2026-08-27 16:04 — suppression de la course au démarrage (P4) : chargement des
//             solutions via solutionsReadyProvider, amorcé ici.
//             2025-12-06 16:00 → 251226 (Avec numérotation)
// Version adaptée avec pré-chargement des solutions BigInt + Numérotation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

import 'package:pentapol/screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PentapolApp()));
}

class PentapolApp extends ConsumerStatefulWidget {
  const PentapolApp({super.key});

  @override
  ConsumerState<PentapolApp> createState() => _PentapolAppState();
}

class _PentapolAppState extends ConsumerState<PentapolApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Le singleton global des 9356 (solutionsReadyProvider) servait le mode classique,
    // supprimé : Pentoscope charge ses tables via pentoscopeSolutionsProvider.
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialiser un puzzle 5x3 au démarrage
      final notifier = ref.read(pentoscopeProvider.notifier);
      await notifier.startPuzzle(
        PentoscopeSize.size5x5, // 5x5 qui correspond à 5 pièces
        difficulty: PentoscopeDifficulty.random,
        showSolution: false,
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du puzzle: $e');
      // En cas d'erreur, on lance quand même l'app avec HomeScreen
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pentapol',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _isInitialized ? const PentoscopeGameScreen() : _buildLoadingScreen(),

      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de Pentoscope...'),
          ],
        ),
      ),
    );
  }
}
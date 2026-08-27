// Modified: 2026-08-27 — suppression de la course au démarrage (P4) : le chargement des
//           solutions passe du Future.microtask non attendu au solutionsReadyProvider,
//           amorcé ici et observé par PentominoGameScreen.
// lib/main.dart
// Historique: 2025-12-06 16:00 → 251226 (Avec numérotation)
// Version adaptée avec pré-chargement des solutions BigInt + Numérotation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/screens/pentoscope_game_screen.dart';

import 'package:pentapol/providers/solutions_provider.dart';
import 'package:pentapol/screens/home_screen.dart';
import 'package:pentapol/classical/pentomino_game_screen.dart';


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

    // Amorce le chargement des 9356 solutions SANS l'attendre : Pentoscope utilise
    // PentoscopeSolver et n'en a pas besoin, il ne doit pas être ralenti au démarrage.
    // PentominoGameScreen observe ce même provider et refuse de monter le jeu tant
    // qu'il n'est pas résolu — c'est ce qui supprime la course (défaut P4).
    ref.read(solutionsReadyProvider);

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
        '/game': (context) => const PentominoGameScreen(),
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
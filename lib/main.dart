// Modified: 2025-11-15 15:56:05
// lib/main.dart
// Version adaptée avec pré-chargement des solutions BigInt

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/plateau_editor_screen.dart';
import 'screens/pentomino_game_screen.dart';
import 'services/solution_matcher.dart';
import 'services/pentapol_solutions_loader.dart'; // <-- loader binaire -> BigInt

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initSupabase();
  } catch (e) {
    // En cas d'erreur Supabase (ex: web), continuer quand même
    debugPrint('⚠️ Erreur initialisation Supabase: $e');
  }

  // ✨ PRÉ-CHARGEMENT des solutions en arrière-plan
  debugPrint('🔄 Pré-chargement des solutions pentomino (BigInt)...');

  Future.microtask(() async {
    final startTime = DateTime.now();
    try {
      // 1) Charger et décoder les solutions normalisées depuis le .bin
      final solutionsBigInt = await loadNormalizedSolutionsAsBigInt();

      // 2) Initialiser le matcher global avec ces solutions
      solutionMatcher.initWithBigIntSolutions(solutionsBigInt);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final count = solutionMatcher.totalSolutions;
      debugPrint('✅ $count solutions BigInt chargées en ${duration}ms');
    } catch (e, st) {
      debugPrint('❌ Erreur lors du pré-chargement des solutions: $e');
      debugPrint('$st');
    }
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MODE DEBUG : Lancer directement le jeu
    const bool debugGameMode = true;

    return MaterialApp(
      title: 'Pentapol',
      theme: ThemeData(useMaterial3: true),
      routes: {
        '/': (context) {
          if (debugGameMode) {
            return const PentominoGameScreen();
          }
          final client = Supabase.instance.client;
          return client.auth.currentUser == null
              ? const AuthScreen()
              : const HomeScreen();
        },
        '/editor': (context) => const PlateauEditorScreen(),
        '/game': (context) => const PentominoGameScreen(),
      },
    );
  }
}

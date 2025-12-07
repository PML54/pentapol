// Modified: 2025-12-06 16:00
// lib/main.dart
// Version adaptée avec pré-chargement des solutions BigInt

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'screens/pentomino_game_screen.dart';
import 'duel_isometry/screens/duel_isometry_game_screen.dart';

import 'services/solution_matcher.dart';
import 'services/pentapol_solutions_loader.dart';


import 'isopento/screens/isopento_game_screen.dart';
import 'isopento/screens/isopento_menu_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MaterialApp(
      title: 'Pentapol',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),

      routes: {
        '/game': (context) => const PentominoGameScreen(),
        '/duel_isometry_game': (context) => const DuelIsometryGameScreen(),
            '/isopento_menu': (context) => const IsopentoMenuScreen(),

         '/isopento_game': (context) => const IsopentoGameScreen(),
      },

    );
  }
}
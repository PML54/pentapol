// Modified: 2026-09-02 16:46 — écran d'accueil (PLAN_ECRAN_ACCUEIL) : home démarre sur HomeScreen
//           (plutôt que directement PentoscopeGameScreen) ; l'écran de chargement est conservé.
// lib/main.dart
// Historique: 2026-08-31 17:00 — suppression de la difficulté : les deux appels startPuzzle ne
//           passent plus difficulty (paramètre retiré).
// Historique: 2026-08-30 12:05 — PLAN_PERSISTANCE §7 étape 4 : reprise de la partie en cours ;
//             WidgetsBindingObserver ; au lancement, restaure CurrentGame sinon génère le 5×5.
// Historique: 2026-08-30 — §8 étape 4 : abandon de l'écran d'accueil — retrait de l'unique
//             route nommée et de son import ; les Réglages passent par l'AppBar de Pentoscope.
//             2026-08-29 14:09 — étape 7 : retrait de l'amorce solutionsReadyProvider.
//             2026-08-27 16:04 — suppression de la course au démarrage (P4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pentapol/providers/settings_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_provider.dart';
import 'package:pentapol/pentoscope/pentoscope_generator.dart';
import 'package:pentapol/pentoscope/home/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PentapolApp()));
}

class PentapolApp extends ConsumerStatefulWidget {
  const PentapolApp({super.key});

  @override
  ConsumerState<PentapolApp> createState() => _PentapolAppState();
}

class _PentapolAppState extends ConsumerState<PentapolApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Le singleton global des 9356 (solutionsReadyProvider) servait le mode classique,
    // supprimé : Pentoscope charge ses tables via pentoscopeSolutionsProvider.
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Au passage en arrière-plan, figer la partie en cours pour capturer elapsedSeconds
    // avant que l'app soit suspendue (PLAN_PERSISTANCE §2.2). No-op en multijoueur.
    if (state == AppLifecycleState.paused) {
      ref.read(pentoscopeProvider.notifier).saveCurrentGameSnapshot();
    }
  }

  Future<void> _initializeApp() async {
    final notifier = ref.read(pentoscopeProvider.notifier);
    try {
      // Reprise : lire la partie en cours d'abord ; ne générer un puzzle neuf que s'il n'y
      // en a pas (PLAN_PERSISTANCE §2.4). Une partie corrompue est effacée et remplacée.
      final saved = await ref.read(settingsDatabaseProvider).loadCurrentGame();
      if (saved != null) {
        try {
          await notifier.restoreGame(saved);
        } catch (e) {
          debugPrint('❌ Reprise impossible, partie effacée: $e');
          await ref.read(settingsDatabaseProvider).clearCurrentGame();
          await notifier.startPuzzle(
            PentoscopeSize.size5x5,
            showSolution: false,
          );
        }
      } else {
        await notifier.startPuzzle(
          PentoscopeSize.size5x5, // 5x5 qui correspond à 5 pièces
          showSolution: false,
        );
      }

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du puzzle: $e');
      // En cas d'erreur, on lance quand même l'app (écran Pentoscope)
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
      home: _isInitialized ? const HomeScreen() : _buildLoadingScreen(),
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
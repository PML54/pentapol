// lib/tutorial/providers/tutorial_provider.dart
// Provider Riverpod pour la gestion des tutoriels

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tutorial_state.dart';
import '../models/tutorial_script.dart';
import '../models/tutorial_context.dart';
import '../interpreter/scratch_interpreter.dart';
import '../../providers/pentomino_game_provider.dart';

/// Provider pour l'état du tutoriel
final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(() {
  return TutorialNotifier();
});

/// Notifier pour gérer l'état des tutoriels
class TutorialNotifier extends Notifier<TutorialState> {
  @override
  TutorialState build() => TutorialState.initial();

  // ============================================================
  // CHARGEMENT DE SCRIPTS
  // ============================================================

  /// Charge un script de tutoriel
  void loadScript(TutorialScript script) {
    if (state.isRunning) {
      throw StateError('Un tutoriel est déjà en cours');
    }

    print('[TUTORIAL] Chargement du script: ${script.name}');

    state = state.copyWith(
      currentScript: script,
      isLoaded: true,
      currentStep: 0,
    );
  }

  /// Décharge le script actuel
  void unloadScript() {
    if (state.isRunning) {
      stop();
    }

    state = state.copyWith(
      clearCurrentScript: true,
      clearInterpreter: true,
      clearContext: true,
      isLoaded: false,
      currentStep: 0,
    );

    print('[TUTORIAL] Script déchargé');
  }

  // ============================================================
  // EXÉCUTION
  // ============================================================

  /// Démarre l'exécution du script chargé
  Future<void> start() async {
    if (!state.isLoaded || state.currentScript == null) {
      throw StateError('Aucun script chargé');
    }

    if (state.isRunning) {
      throw StateError('Le tutoriel est déjà en cours');
    }

    print('[TUTORIAL] Démarrage du tutoriel: ${state.currentScript!.name}');

    // Créer le contexte
    final gameNotifier = ref.read(pentominoGameProvider.notifier);
    final context = TutorialContext(
      gameNotifier: gameNotifier,
      ref: ref,  // ← ENLEVER le "as WidgetRef"
      variables: Map.from(state.currentScript!.variables),
    );

    // Créer l'interpréteur
    final interpreter = ScratchInterpreter(
      script: state.currentScript!,
      context: context,
      onStepChanged: _onStepChanged,
      onCompleted: _onCompleted,
      onError: _onError,
    );

    state = state.copyWith(
      interpreter: interpreter,
      context: context,
      isRunning: true,
      currentStep: 0,
    );

// Lancer l'exécution en asynchrone
    print('[TUTORIAL] 🟢 Appel de interpreter.run()...');
    interpreter.run();
    print('[TUTORIAL] 🟢 Appel terminé (asynchrone)');
  }

  /// Callback quand une étape change
  void _onStepChanged(int step) {
    state = state.copyWith(currentStep: step);

    // Mettre à jour le message si le contexte en a un
    if (state.context?.currentMessage != null) {
      state = state.copyWith(currentMessage: state.context!.currentMessage);
    }
  }

  /// Callback quand le script est terminé
  void _onCompleted() {
    print('[TUTORIAL] Tutoriel terminé: ${state.currentScript?.name}');

    // Nettoyer complètement l'état
    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      clearCurrentScript: true,
      clearInterpreter: true,
      clearContext: true,
      clearCurrentMessage: true,
      isLoaded: false,
      currentStep: 0,
    );
  }

  /// Callback en cas d'erreur
  void _onError(Object error, StackTrace stackTrace) {
    print('[TUTORIAL] Erreur dans le tutoriel: $error');
    print(stackTrace);

    state = state.copyWith(
      isRunning: false,
      isPaused: false,
      currentMessage: 'Erreur: $error',
    );
  }

  // ============================================================
  // CONTRÔLES
  // ============================================================

  /// Met en pause
  void pause() {
    if (!state.isRunning) return;

    state.interpreter?.pause();
    state = state.copyWith(isPaused: true);
    print('[TUTORIAL] Pause');
  }

  /// Reprend l'exécution
  void resume() {
    if (!state.isRunning) return;

    state.interpreter?.resume();
    state = state.copyWith(isPaused: false);
    print('[TUTORIAL] Reprise');
  }

  /// Arrête l'exécution
  void stop() {
    if (!state.isRunning) return;

    state.interpreter?.stop();
    state = state.copyWith(isRunning: false, isPaused: false, currentStep: 0);

    print('[TUTORIAL] Arrêt');
  }

  /// Redémarre depuis le début
  Future<void> restart() async {
    stop();
    await Future.delayed(const Duration(milliseconds: 100));
    await start();
  }

  // ============================================================
  // PAS À PAS
  // ============================================================

  /// Exécute l'étape suivante (mode pas à pas)
  Future<void> stepNext() async {
    if (state.interpreter == null) return;

    await state.interpreter!.stepNext();
    state = state.copyWith(currentStep: state.interpreter!.currentStep);
  }

  /// Revient à l'étape précédente
  void stepBack() {
    if (state.interpreter == null) return;

    state.interpreter!.stepBack();
    state = state.copyWith(currentStep: state.interpreter!.currentStep);
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  /// Met à jour le message affiché
  void updateMessage(String? message) {
    state = state.copyWith(
      currentMessage: message,
      clearCurrentMessage: message == null,
    );
  }
}

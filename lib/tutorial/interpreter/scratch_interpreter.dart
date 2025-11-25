// lib/tutorial/interpreter/scratch_interpreter.dart
// Interpréteur qui exécute les scripts de tutoriel

import '../models/scratch_command.dart';
import '../models/tutorial_script.dart';
import '../models/tutorial_context.dart';

/// Interpréteur de scripts Scratch-Pentapol
class ScratchInterpreter {
  /// Script à exécuter
  final TutorialScript script;

  /// Contexte d'exécution
  final TutorialContext context;

  /// Étape courante
  int currentStep = 0;

  /// En cours d'exécution
  bool isRunning = false;

  /// Callbacks
  final void Function(int step)? onStepChanged;
  final void Function()? onCompleted;
  final void Function(Object error, StackTrace stackTrace)? onError;

  ScratchInterpreter({
    required this.script,
    required this.context,
    this.onStepChanged,
    this.onCompleted,
    this.onError,
  });

  // ============================================================
  // EXÉCUTION COMPLÈTE
  // ============================================================

  /// Lance l'exécution du script du début à la fin
  Future<void> run() async {
    if (isRunning) {
      throw StateError('Le script est déjà en cours d\'exécution');
    }

    isRunning = true;
    currentStep = 0;

    print('[INTERPRETER] Démarrage du script: ${script.name}');

    try {
      while (currentStep < script.steps.length && !context.isCancelled) {
        // Attendre si en pause
        await context.waitIfPaused();

        if (context.isCancelled) break;

        // Exécuter la commande
        final command = script.steps[currentStep];
        print('[INTERPRETER] Étape $currentStep: ${command.name}');

        try {
          await command.execute(context);
        } catch (e, stackTrace) {
          print('[INTERPRETER] Erreur à l\'étape $currentStep: $e');
          onError?.call(e, stackTrace);
          // Continuer malgré l'erreur
        }

        // Passer à l'étape suivante
        currentStep++;
        onStepChanged?.call(currentStep);

        // Petit délai pour ne pas bloquer l'UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Terminé
      if (!context.isCancelled) {
        print('[INTERPRETER] Script terminé');
        onCompleted?.call();
      } else {
        print('[INTERPRETER] Script annulé');
      }
    } catch (e, stackTrace) {
      print('[INTERPRETER] Erreur fatale: $e');
      onError?.call(e, stackTrace);
    } finally {
      isRunning = false;
    }
  }

  // ============================================================
  // CONTRÔLES
  // ============================================================

  /// Met en pause
  void pause() {
    context.pause();
  }

  /// Reprend
  void resume() {
    context.resume();
  }

  /// Arrête l'exécution
  void stop() {
    context.cancel();
    isRunning = false;
  }

  // ============================================================
  // EXÉCUTION PAS À PAS
  // ============================================================

  /// Exécute la prochaine étape (mode pas à pas)
  Future<void> stepNext() async {
    if (currentStep >= script.steps.length) {
      print('[INTERPRETER] Fin du script');
      onCompleted?.call();
      return;
    }

    final command = script.steps[currentStep];
    print('[INTERPRETER] Étape $currentStep: ${command.name}');

    try {
      await command.execute(context);
      currentStep++;
      onStepChanged?.call(currentStep);

      if (currentStep >= script.steps.length) {
        onCompleted?.call();
      }
    } catch (e, stackTrace) {
      print('[INTERPRETER] Erreur: $e');
      onError?.call(e, stackTrace);
    }
  }

  /// Revient à l'étape précédente
  void stepBack() {
    if (currentStep > 0) {
      currentStep--;
      onStepChanged?.call(currentStep);
      print('[INTERPRETER] Retour à l\'étape $currentStep');
    }
  }

  /// Réinitialise au début
  void reset() {
    currentStep = 0;
    context.isCancelled = false;
    context.isPaused = false;
    onStepChanged?.call(0);
    print('[INTERPRETER] Réinitialisé');
  }
}

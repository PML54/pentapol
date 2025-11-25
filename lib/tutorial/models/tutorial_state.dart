// lib/tutorial/models/tutorial_state.dart
// État d'un tutoriel en cours d'exécution

import 'tutorial_script.dart';
import 'tutorial_context.dart';
import '../interpreter/scratch_interpreter.dart';

/// État d'un tutoriel
class TutorialState {
  /// Script actuellement chargé
  final TutorialScript? currentScript;

  /// Interpréteur en cours
  final ScratchInterpreter? interpreter;

  /// Contexte d'exécution
  final TutorialContext? context;

  /// Le tutoriel est-il en cours d'exécution ?
  final bool isRunning;

  /// Le tutoriel est-il en pause ?
  final bool isPaused;

  /// Index de l'étape courante
  final int currentStep;

  /// Message actuel affiché
  final String? currentMessage;

  /// Script chargé mais pas encore démarré
  final bool isLoaded;

  const TutorialState({
    this.currentScript,
    this.interpreter,
    this.context,
    this.isRunning = false,
    this.isPaused = false,
    this.currentStep = 0,
    this.currentMessage,
    this.isLoaded = false,
  });

  /// État initial
  factory TutorialState.initial() {
    return const TutorialState();
  }

  /// Copie avec modifications
  TutorialState copyWith({
    TutorialScript? currentScript,
    bool clearCurrentScript = false,
    ScratchInterpreter? interpreter,
    bool clearInterpreter = false,
    TutorialContext? context,
    bool clearContext = false,
    bool? isRunning,
    bool? isPaused,
    int? currentStep,
    String? currentMessage,
    bool clearCurrentMessage = false,
    bool? isLoaded,
  }) {
    return TutorialState(
      currentScript: clearCurrentScript
          ? null
          : (currentScript ?? this.currentScript),
      interpreter: clearInterpreter ? null : (interpreter ?? this.interpreter),
      context: clearContext ? null : (context ?? this.context),
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentStep: currentStep ?? this.currentStep,
      currentMessage: clearCurrentMessage
          ? null
          : (currentMessage ?? this.currentMessage),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  /// Calcule le progrès (0.0 à 1.0)
  double get progress {
    if (currentScript == null || currentScript!.steps.isEmpty) {
      return 0.0;
    }
    return currentStep / currentScript!.steps.length;
  }

  /// Nombre total d'étapes
  int get totalSteps => currentScript?.steps.length ?? 0;

  /// Le tutoriel est-il terminé ?
  bool get isCompleted => currentStep >= totalSteps && totalSteps > 0;
}

// Modified: 2026-08-27 20:50 — création : étape 3 du plan d'unification, famille Chrono.
//           Les trois méthodes de chronomètre étaient dupliquées dans les deux
//           providers. Voir docs/PLAN_UNIFICATION_PIECES.md.
// lib/common/game_timer_mixin.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chronomètre de partie, partagé par tous les modules de jeu.
///
/// Le module fournit uniquement [stateWithElapsedSeconds] : le mixin ne connaît pas
/// la forme de l'état, seulement le moyen d'y écrire le temps écoulé.
///
/// ## Trois intentions distinctes, trois méthodes
///
/// Avant l'unification, les deux providers avaient chacun leur `startTimer` avec une
/// **garde différente**, ce qui leur donnait des comportements incompatibles :
///
/// - le mode classique gardait sur `_startTime != null` : après un `stopTimer`, le
///   chrono ne repartait jamais, l'origine était préservée ;
/// - Pentoscope gardait sur `_gameTimer != null` : après un `stopTimer`, le chrono
///   repartait **en réinitialisant l'origine**, perdant le temps déjà écoulé.
///
/// Aucune des deux gardes ne convenait aux deux modules. La divergence venait de ce
/// que « mettre en pause » et « remettre à zéro » passaient par le même appel. Les
/// séparer supprime le conflit :
///
/// | Méthode | Effet | Reprise après |
/// |---|---|---|
/// | [stopTimer] | arrête le tic, **conserve** l'origine | reprend là où on s'était arrêté |
/// | [resetTimer] | arrête le tic et **efface** l'origine | repart de zéro |
///
/// [startTimer] est idempotent : appelé alors que le chrono tourne déjà, il ne fait
/// rien ; appelé après un [stopTimer], il reprend sans perdre le temps accumulé.
mixin GameTimerMixin<S> on Notifier<S> {
  Timer? _gameTimer;
  DateTime? _startTime;

  /// Retourne l'état courant avec [elapsedSeconds] mis à jour.
  ///
  /// Implémentation typique : `state.copyWith(elapsedSeconds: elapsedSeconds)`.
  S stateWithElapsedSeconds(int elapsedSeconds);

  /// Le chronomètre tourne-t-il.
  bool get isTimerRunning => _gameTimer != null;

  /// Démarre le chronomètre, ou le reprend s'il avait été arrêté par [stopTimer].
  ///
  /// Sans effet s'il tourne déjà. L'origine n'est posée qu'une fois : après un
  /// [stopTimer], le temps déjà écoulé est conservé. Pour repartir de zéro,
  /// appeler [resetTimer] au préalable.
  void startTimer() {
    if (_gameTimer != null) return;
    _startTime ??= DateTime.now();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      state = stateWithElapsedSeconds(getElapsedSeconds());
    });
  }

  /// Arrête le tic en conservant l'origine — une pause, ou une fin de partie.
  void stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Arrête le tic **et** efface l'origine — une nouvelle partie.
  ///
  /// Le prochain [startTimer] repartira de zéro.
  void resetTimer() {
    stopTimer();
    _startTime = null;
  }

  /// Temps écoulé depuis l'origine, en secondes. 0 si le chrono n'a jamais démarré.
  int getElapsedSeconds() {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }
}

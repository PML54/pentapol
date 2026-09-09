// Modified: 2026-09-08 22:37 — Mode entraînement niveau 1 (PLAN_MODE_ENTRAINEMENT §2) : provider Riverpod
//           d'état PUR — aucune écriture dans PuzzleStats/SolvedSolutions ni dans aucune base. La pièce
//           vit sur le plateau 5×5 ; les quatre boutons d'isométrie la tournent/retournent (comptés en
//           appuis), le doigt la déplace (translation, non comptée). Résolu = mêmes cases que le fantôme.
// lib/pentoscope/training/training_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/pentoscope/training/training_mode.dart';

/// État immuable d'un exercice d'entraînement en cours.
class TrainingState {
  final TrainingExercise exercise;

  /// Orientation courante de la pièce manipulée (index dans `piece.orientations`).
  final int currentPositionIndex;

  /// Ancre (col, ligne) courante de la pièce sur le plateau 5×5.
  final Point currentAnchor;

  /// Appuis d'isométrie effectués (rotations + miroirs). Les translations ne comptent pas (§5).
  final int presses;

  /// Vrai dès que les cases occupées recouvrent exactement le fantôme.
  final bool solved;

  /// Temps écoulé, **figé** à la résolution (0 tant que non résolu).
  final int elapsedSeconds;

  const TrainingState({
    required this.exercise,
    required this.currentPositionIndex,
    required this.currentAnchor,
    required this.presses,
    required this.solved,
    required this.elapsedSeconds,
  });

  TrainingState copyWith({
    int? currentPositionIndex,
    Point? currentAnchor,
    int? presses,
    bool? solved,
    int? elapsedSeconds,
  }) {
    return TrainingState(
      exercise: exercise,
      currentPositionIndex: currentPositionIndex ?? this.currentPositionIndex,
      currentAnchor: currentAnchor ?? this.currentAnchor,
      presses: presses ?? this.presses,
      solved: solved ?? this.solved,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

final trainingProvider =
    NotifierProvider<TrainingNotifier, TrainingState>(TrainingNotifier.new);

class TrainingNotifier extends Notifier<TrainingState> {
  late PentapolRng _rng;
  DateTime? _startedAt; // posé au premier geste, pour ne pas compter le temps de lecture.

  @override
  TrainingState build() {
    // Graine variable au lancement (le mode n'est pas classé — pas besoin d'un tirage figé ici,
    // à la différence du défi). Le tirage reste reproductible pour une graine donnée (testable).
    _rng = PentapolRng(DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    return _fresh();
  }

  TrainingState _fresh() {
    _startedAt = null;
    final exercise = drawLevel1(_rng);
    return TrainingState(
      exercise: exercise,
      currentPositionIndex: exercise.startPositionIndex,
      currentAnchor: _initialAnchor(exercise),
      presses: 0,
      solved: false,
      elapsedSeconds: 0,
    );
  }

  /// Ancre de départ : coin haut-gauche, décalé au coin opposé si cela résolvait d'emblée
  /// l'exercice (cas du X, forme = cible → il ne resterait qu'à ne pas déjà être posé dessus).
  Point _initialAnchor(TrainingExercise ex) {
    var anchor = clampAnchor(ex.piece, ex.startPositionIndex, const Point(0, 0));
    if (ex.isSolvedBy(ex.startPositionIndex, anchor)) {
      final box = orientationBox(ex.piece, ex.startPositionIndex);
      anchor = Point(kTrainBoardWidth - box.x, kTrainBoardHeight - box.y);
    }
    return anchor;
  }

  void _markStarted() => _startedAt ??= DateTime.now();

  /// Applique une isométrie (retourne le nouvel index d'orientation), confine l'ancre, compte
  /// l'appui, puis teste la résolution.
  void _applyIsometry(int newPos) {
    if (state.solved) return;
    _markStarted();
    final anchor = clampAnchor(state.exercise.piece, newPos, state.currentAnchor);
    _update(
      currentPositionIndex: newPos,
      currentAnchor: anchor,
      presses: state.presses + 1,
    );
  }

  void rotateCW() =>
      _applyIsometry(state.exercise.piece.rotationCW(state.currentPositionIndex));
  void rotateTW() =>
      _applyIsometry(state.exercise.piece.rotationTW(state.currentPositionIndex));
  void mirrorH() =>
      _applyIsometry(state.exercise.piece.symmetryH(state.currentPositionIndex));
  void mirrorV() =>
      _applyIsometry(state.exercise.piece.symmetryV(state.currentPositionIndex));

  /// Déplace la pièce (translation) — **pas** un appui. Confine l'ancre au plateau.
  void moveTo(Point anchor) {
    if (state.solved) return;
    _markStarted();
    final clamped =
        clampAnchor(state.exercise.piece, state.currentPositionIndex, anchor);
    if (clamped == state.currentAnchor) return;
    _update(currentAnchor: clamped);
  }

  void _update({
    int? currentPositionIndex,
    Point? currentAnchor,
    int? presses,
  }) {
    var next = state.copyWith(
      currentPositionIndex: currentPositionIndex,
      currentAnchor: currentAnchor,
      presses: presses,
    );
    if (!next.solved &&
        next.exercise.isSolvedBy(next.currentPositionIndex, next.currentAnchor)) {
      final elapsed = _startedAt == null
          ? 0
          : DateTime.now().difference(_startedAt!).inSeconds;
      next = next.copyWith(solved: true, elapsedSeconds: elapsed);
    }
    state = next;
  }

  /// Passe à l'exercice suivant.
  void next() {
    state = _fresh();
  }
}

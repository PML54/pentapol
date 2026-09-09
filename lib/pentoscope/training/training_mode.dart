// Modified: 2026-09-09 09:08 — plateau d'entraînement 5×7 (kTrainBoardHeight 5 → 7, choix de Paul) :
//           remplit l'écran en portrait ; la cible se tire dans tout le 5×7.
// Historique: 2026-09-08 22:37 — Mode entraînement niveau 1 (PLAN_MODE_ENTRAINEMENT §2) : logique pure,
//           sans Flutter — tirage reproductible (PentapolRng), validation par ÉGALITÉ DES ENSEMBLES
//           de cases occupées (jamais par index d'orientation), minimum d'appuis via
//           Pento.minIsometriesToReach (orpheline réutilisée). Terminaison garantie X compris.
// lib/pentoscope/training/training_mode.dart

import 'dart:math' as math;

import 'package:pentapol/common/pentapol_rng.dart';
import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/point.dart';

/// Plateau du mode entraînement : **5×7** (`size7x5`, choix de Paul 2026-09-09 — révise le size5x5
/// du PLAN §4). Les 63 orientations tiennent (boîte englobante ≤ 5), et le format haut **remplit
/// l'écran en portrait** (le 5×5, quasi carré, laissait une bande vide au-dessus).
const int kTrainBoardWidth = 5;
const int kTrainBoardHeight = 7;

/// Cellules (col, ligne) d'une orientation [pos] de [piece], normalisées sur sa boîte englobante :
/// le coin haut-gauche de la forme est en (0, 0). Repère : x = colonne, y = ligne, y vers le bas.
List<Point> _normalizedCells(Pento piece, int pos) {
  final raw = piece.orientations[pos]
      .map((n) => Point((n - 1) % 5, (n - 1) ~/ 5))
      .toList();
  final minX = raw.map((c) => c.x).reduce(math.min);
  final minY = raw.map((c) => c.y).reduce(math.min);
  return raw.map((c) => Point(c.x - minX, c.y - minY)).toList();
}

/// Boîte englobante (largeur, hauteur) de l'orientation [pos] de [piece].
Point orientationBox(Pento piece, int pos) {
  final norm = _normalizedCells(piece, pos);
  final w = norm.map((c) => c.x).reduce(math.max) + 1;
  final h = norm.map((c) => c.y).reduce(math.max) + 1;
  return Point(w, h);
}

/// Ensemble des cases du plateau occupées par [piece] à l'orientation [pos], ancrée en [anchor]
/// (coin haut-gauche de la boîte englobante). C'est cet ensemble qui sert à la **validation** :
/// deux placements sont équivalents ssi ils occupent exactement les mêmes cases (PLAN §2).
Set<Point> cellsFor(Pento piece, int pos, Point anchor) {
  return _normalizedCells(piece, pos)
      .map((c) => Point(c.x + anchor.x, c.y + anchor.y))
      .toSet();
}

/// Confine [anchor] pour que l'orientation [pos] de [piece] tienne entièrement dans le plateau.
Point clampAnchor(Pento piece, int pos, Point anchor) {
  final box = orientationBox(piece, pos);
  final x = anchor.x.clamp(0, kTrainBoardWidth - box.x);
  final y = anchor.y.clamp(0, kTrainBoardHeight - box.y);
  return Point(x, y);
}

/// Égalité de deux ensembles de cases (le `Set` de Dart n'a pas d'`==` structurel).
bool sameCells(Set<Point> a, Set<Point> b) =>
    a.length == b.length && a.containsAll(b);

/// Un exercice de niveau 1 : une pièce à amener de l'orientation [startPositionIndex] (au rack)
/// jusqu'à la **forme cible** ([targetPositionIndex] ancrée en [targetAnchor]) affichée en fantôme.
class TrainingExercise {
  final Pento piece;

  /// Orientation de départ (au rack). Pour le X (une seule orientation), égale à la cible.
  final int startPositionIndex;

  /// Orientation cible (celle du fantôme).
  final int targetPositionIndex;

  /// Ancre (col, ligne) de la forme cible sur le plateau 5×5.
  final Point targetAnchor;

  /// Minimum d'**appuis d'isométrie** (rotations + miroirs) pour passer du rack à la cible.
  /// Calculé par [Pento.minIsometriesToReach] — les translations ne sont pas des appuis (PLAN §5).
  final int minPresses;

  /// Vrai pour le X : « une orientation différente » n'existe pas → l'exercice se réduit à la
  /// **pose** (minPresses = 0). Décision de Paul : on garde le X (PLAN §2, règle non négociable).
  final bool poseOnly;

  const TrainingExercise({
    required this.piece,
    required this.startPositionIndex,
    required this.targetPositionIndex,
    required this.targetAnchor,
    required this.minPresses,
    required this.poseOnly,
  });

  /// Cases occupées par la forme cible (le fantôme).
  Set<Point> targetCells() => cellsFor(piece, targetPositionIndex, targetAnchor);

  /// Vrai si la pièce placée à l'orientation [pos] ancrée en [anchor] recouvre exactement la cible.
  bool isSolvedBy(int pos, Point anchor) =>
      sameCells(cellsFor(piece, pos, anchor), targetCells());
}

/// Tire un exercice de niveau 1 pour la pièce donnée, avec [rng] (reproductible → testable).
///
/// **Terminaison garantie, X compris** (PLAN §2) : le X (une orientation) ne boucle pas — départ =
/// cible, pose seule. Pour toute autre pièce, on tire une orientation de départ **de forme
/// différente** de la cible (boucle bornée par `numOrientations ≥ 2`), pour que le rack ne soit
/// jamais déjà résolu. La comparaison de forme se fait par ensembles de cases, pas par index.
TrainingExercise drawLevel1ForPiece(PentapolRng rng, Pento piece) {
  final n = piece.numOrientations;
  final target = rng.nextInt(n);
  final targetShape = cellsFor(piece, target, const Point(0, 0));

  int start;
  bool poseOnly;
  if (n == 1) {
    start = target; // X : pose seule (pas d'orientation différente possible).
    poseOnly = true;
  } else {
    start = rng.nextInt(n);
    // Rejette une orientation de départ de MÊME forme que la cible (pièces symétriques : deux
    // index peuvent décrire la même forme — on compare les cases, pas les index).
    while (sameCells(cellsFor(piece, start, const Point(0, 0)), targetShape)) {
      start = (start + 1) % n;
    }
    poseOnly = false;
  }

  // Ancre cible : n'importe quelle position où la forme cible tient dans le plateau 5×5.
  final box = orientationBox(piece, target);
  final ax = rng.nextInt(kTrainBoardWidth - box.x + 1);
  final ay = rng.nextInt(kTrainBoardHeight - box.y + 1);

  return TrainingExercise(
    piece: piece,
    startPositionIndex: start,
    targetPositionIndex: target,
    targetAnchor: Point(ax, ay),
    minPresses: piece.minIsometriesToReach(start, target),
    poseOnly: poseOnly,
  );
}

/// Tire un exercice de niveau 1 sur une pièce quelconque parmi les douze.
TrainingExercise drawLevel1(PentapolRng rng) =>
    drawLevel1ForPiece(rng, pentominos[rng.nextInt(pentominos.length)]);

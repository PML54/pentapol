// Modified: 2026-09-04 15:57 — maillot blanc : champ rescues (sauvetages rouge→jaune, §7).
// lib/pentoscope/completion_metrics.dart
// Historique: 2026-09-04 06:13 — médaille §4.6 : getter perfectVision (acuité 100 %, isoCount==minIso).
// Historique: 2026-09-04 05:20 — création : les trois mesures d'une partie terminée (maillots
//           jaune/à pois/vert, CDC §4). Calcul pur, testable hors provider. minIso somme
//           Pento.minIsometriesToReach(rack, placement) ; coups = pièces + 2·retraits (§4.7).

import 'package:pentapol/common/placed_piece.dart';

/// Les trois mesures d'une partie terminée (CDC §4), en valeurs **brutes**. Les ratios
/// (acuité, efficacité) se dérivent — on ne stocke que le brut, auditable (§7.6).
class CompletionMetrics {
  /// Σ des isométries **minimales** rack → placement posé, sur toutes les pièces. Maillot jaune.
  final int minIso;

  /// Isométries **réellement** effectuées par le joueur (compteur d'état).
  final int isometryCount;

  /// Coups = poses + retraits (maillot à pois). Vaut `pieceCount + 2·retraits` : à la
  /// complétion, `poses − retraits = pieceCount`, donc `poses = pieceCount + retraits`. Le
  /// déplacement direct (`translationCount`) est exclu (Q6, §4.7).
  final int moves;

  /// Minimum de coups atteignable = nombre de pièces (chaque pièce posée une fois, zéro retrait).
  final int minMoves;

  /// Temps écoulé, en secondes. Maillot vert.
  final int timeSeconds;

  /// Sauvetages rouge→jaune : nombre de fois où une action a rétabli la solubilité (usage de
  /// l'oracle). Maillot **blanc** (CDC §7 Acté 3-4). 0 = partie sans recours à la lampe.
  final int rescues;

  const CompletionMetrics({
    required this.minIso,
    required this.isometryCount,
    required this.moves,
    required this.minMoves,
    required this.timeSeconds,
    required this.rescues,
  });

  /// Acuité isométrique (§4.2) : `(minIso + 1) / (isometryCount + 1)`. Le `+1` traite le cas
  /// dégénéré `minIso = 0` (rack déjà bien orienté) et évite `0/0`.
  double get acuity => (minIso + 1) / (isometryCount + 1);

  /// Efficacité de placement (§4.7) : `pièces / coups`. Pas de cas dégénéré (`coups ≥ pièces`).
  double get efficiency => minMoves / moves;

  /// « Vision parfaite » (§4.6) : acuité à 100 %, c.-à-d. **aucun geste au-delà du nécessaire**
  /// (`isometryCount == minIso`). Jamais un seuil sur `minIso` brut : `minIso = 0` récompenserait
  /// le tirage, pas le joueur. La médaille exige en plus une partie sans aide (traité à l'appel).
  bool get perfectVision => isometryCount == minIso;
}

/// Calcule les mesures d'une partie **terminée** à partir de l'état brut.
///
/// [initialOrientations] est le rack distribué (`pieceId → index d'orientation`) ; pour chaque
/// pièce posée on ajoute `minIsometriesToReach(rack, orientation posée)`. Une pièce dont le rack
/// est inconnu (partie d'avant la capture du rack) n'ajoute rien — l'acuité est alors surévaluée,
/// cas résiduel accepté. [pieceCount] est le nombre de pièces du puzzle (= minimum de coups).
CompletionMetrics computeMetrics({
  required List<PlacedPiece> placedPieces,
  required Map<int, int> initialOrientations,
  required int isometryCount,
  required int deleteCount,
  required int pieceCount,
  required int timeSeconds,
  int rescues = 0,
}) {
  var minIso = 0;
  for (final pp in placedPieces) {
    final rack = initialOrientations[pp.piece.id];
    if (rack == null) continue;
    minIso += pp.piece.minIsometriesToReach(rack, pp.positionIndex);
  }
  return CompletionMetrics(
    minIso: minIso,
    isometryCount: isometryCount,
    moves: pieceCount + 2 * deleteCount,
    minMoves: pieceCount,
    timeSeconds: timeSeconds,
    rescues: rescues,
  );
}

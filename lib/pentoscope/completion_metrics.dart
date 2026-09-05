// Modified: 2026-09-05 17:24 — trois maillots (A) : acuité (PLAFONNÉE à 100 %), FAUTES (remplace les
//           coups ; = passages en cul-de-sac), temps. Suppression de moves/minMoves/efficiency ;
//           rescues renommé faults (le maillot « Help » est fusionné dans « fautes »).
// lib/pentoscope/completion_metrics.dart
// Historique: 2026-09-04 05:20 — création : mesures d'une partie terminée (calcul pur, testable).

import 'package:pentapol/common/placed_piece.dart';

/// Les mesures d'une partie terminée (CDC §4), en valeurs **brutes**. Trois maillots : acuité
/// (jaune), fautes (à pois), temps (vert). L'acuité se dérive ; on ne stocke que le brut.
class CompletionMetrics {
  /// Σ des isométries **minimales** rack → placement posé, sur toutes les pièces. Maillot jaune.
  final int minIso;

  /// Isométries **réellement** effectuées par le joueur (compteur d'état).
  final int isometryCount;

  /// **Fautes** (maillot à pois) : nombre de fois où une action fait passer le plateau de soluble
  /// à insoluble (lampe jaune→rouge) — un cul-de-sac. La partie finissant soluble, ce nombre égale
  /// aussi le nombre de sauvetages (rouge→jaune). Remplace l'ancien « coups ».
  final int faults;

  /// Temps écoulé, en secondes. Maillot vert.
  final int timeSeconds;

  const CompletionMetrics({
    required this.minIso,
    required this.isometryCount,
    required this.faults,
    required this.timeSeconds,
  });

  /// Acuité isométrique (§4.2), **plafonnée à 100 %** : `min(1, (minIso+1)/(isometryCount+1))`. Le
  /// plafond couvre le cas de l'indice, qui pose une pièce sans que le joueur fasse l'isométrie
  /// (`minIso` la compte, `isometryCount` non → ratio > 1). Le `+1` traite `minIso = 0`.
  double get acuity {
    final r = (minIso + 1) / (isometryCount + 1);
    return r > 1.0 ? 1.0 : r;
  }

  /// « Vision parfaite » (§4.6) : `isometryCount == minIso` (aucun geste de trop). La médaille
  /// exige en plus une partie **sans aide** (traité à l'appel).
  bool get perfectVision => isometryCount == minIso;
}

/// Calcule les mesures d'une partie **terminée** à partir de l'état brut.
///
/// [initialOrientations] est le rack distribué (`pieceId → index`) ; pour chaque pièce posée on
/// ajoute `minIsometriesToReach(rack, orientation posée)`. Une pièce dont le rack est inconnu
/// n'ajoute rien (cas résiduel accepté). [faults] = compteur de cul-de-sac de l'état.
CompletionMetrics computeMetrics({
  required List<PlacedPiece> placedPieces,
  required Map<int, int> initialOrientations,
  required int isometryCount,
  required int timeSeconds,
  int faults = 0,
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
    faults: faults,
    timeSeconds: timeSeconds,
  );
}

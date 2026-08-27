// Modified: 2026-08-27 20:39 — création : l'enum vivait dans pentoscope_provider.dart, ce qui
//           interdisait au mode classique de renvoyer le même type. Étape 2 du plan
//           docs/PLAN_UNIFICATION_PIECES.md.
// lib/common/transformation_result.dart

/// Issue d'une transformation isométrique appliquée à une pièce.
///
/// Retourné par les quatre méthodes `applyIsometry*` des providers de jeu.
///
/// ⚠️ **Le mode classique ne renvoie aujourd'hui que [success].** Ses helpers
/// (`_applyRotationToPlacedPiece`, `_applySymmetryToPlacedPiece`) n'ont aucun
/// chemin d'échec : ils sortent sans rien faire quand la transformation ne change
/// rien, sans le signaler. Seul Pentoscope distingue réellement les trois cas.
///
/// L'alignement du **type de retour** est volontairement séparé de la
/// réconciliation des **comportements**, qui relève de l'étape 3 du plan. Ne pas
/// se fier à un [success] venant du mode classique pour conclure qu'une
/// transformation a effectivement eu lieu.
enum TransformationResult {
  /// Transformation réussie, sans ajustement de position.
  success,

  /// Transformation réussie, mais la pièce a dû être recentrée pour tenir
  /// sur le plateau.
  recentered,

  /// Transformation impossible : aucune position valide n'existe.
  impossible,
}

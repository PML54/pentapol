// Modified: 2026-08-27 20:29 — création : contrat commun aux états des modules de jeu, étape 1
//           du plan d'unification (docs/PLAN_UNIFICATION_PIECES.md).
// lib/common/piece_manipulation_state.dart

import 'package:pentapol/common/pentominos.dart';
import 'package:pentapol/common/placed_piece.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/common/point.dart';
import 'package:pentapol/common/view_orientation.dart';

/// Noyau d'état commun à tous les modules de jeu : ce qu'il faut pour manipuler
/// des pièces depuis la barre et sur le plateau.
///
/// `PentominoGameState` (mode classique) et `PentoscopeState` (Pentoscope et
/// multijoueur) l'implémentent tous les deux. Leurs champs propres — puzzle,
/// compteurs, tutoriel, solutions — restent chez eux.
///
/// ## Pourquoi une interface et non un objet imbriqué
///
/// Ces 15 champs sont lus à environ **407 endroits** dans `lib/`. Un objet de valeur
/// imbriqué aurait imposé de réécrire chacun d'eux en `state.pieces.<champ>`.
/// Une interface est satisfaite automatiquement par les champs `final` existants :
/// aucun site d'appel ne change, et le compilateur garantit que les deux états
/// restent alignés.
///
/// ## À quoi ça sert
///
/// C'est le préalable à l'étape 3 du plan : les 28 méthodes de manipulation
/// aujourd'hui dupliquées entre les deux providers pourront être typées contre ce
/// contrat et remonter dans un mixin partagé.
///
/// **Ne pas ajouter ici un champ propre à un seul module.** Ce qui entre dans ce
/// contrat doit avoir un sens pour les trois.
abstract class PieceManipulationState {
  /// Grille de jeu.
  Plateau get plateau;

  /// Pièces encore disponibles dans la barre.
  List<Pento> get availablePieces;

  /// Pièces posées sur le plateau.
  List<PlacedPiece> get placedPieces;

  /// Pièce sélectionnée dans la barre, `null` si aucune.
  Pento? get selectedPiece;

  /// Index d'orientation de la pièce sélectionnée (0..numOrientations-1).
  int get selectedPositionIndex;

  /// Pièce posée sélectionnée sur le plateau, `null` si aucune.
  PlacedPiece? get selectedPlacedPiece;

  /// Orientation mémorisée par pièce, indexée par id de pièce.
  Map<int, int> get piecePositionIndices;

  /// Mastercase : cellule cliquée dans la pièce, point de référence du drag.
  Point? get selectedCellInPiece;

  /// Position X du preview de placement, `null` si aucun preview.
  int? get previewX;

  /// Position Y du preview de placement, `null` si aucun preview.
  int? get previewY;

  /// Le preview correspond-il à un placement valide.
  bool get isPreviewValid;

  /// Le preview est-il aimanté sur une position valide.
  bool get isSnapped;

  /// Un drag est-il en cours.
  bool get isDragging;

  /// Orientation de l'écran, qui conditionne l'interprétation des symétries.
  ViewOrientation get viewOrientation;

  /// Temps écoulé depuis le premier placement, en secondes.
  int get elapsedSeconds;
}

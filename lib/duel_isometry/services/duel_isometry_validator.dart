// 251206 1600
// Version: Claude V2
// lib/duel_isometry/services/duel_isometry_validator.dart
// Validateur pour Duel Isométries - Valide placements et compte isométries

import 'package:pentapol/models/pentominos.dart';
import 'package:pentapol/models/plateau.dart';
final allPentominoes = pentominos;

/// Résultat de validation
class ValidationResult {
  final bool isValid;
  final String? reason;

  ValidationResult.valid() : isValid = true, reason = null;
  ValidationResult.invalid(this.reason) : isValid = false;
}

/// Validateur pour Duel Isométries
class DuelIsometryValidator {
  /// Valide qu'une pièce placée en (x, y) avec orientation corresponds à la solution
  static ValidationResult validatePlacement({
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
    required Plateau solutionPlateau,
  }) {
    // 1. Vérifier pieceId valide
    if (pieceId < 1 || pieceId > 12) {
      return ValidationResult.invalid('ID pièce invalide: $pieceId');
    }

    final piece = pentominos[pieceId - 1];

    // 2. Vérifier orientation valide
    if (orientation < 0 || orientation >= piece.numPositions) {
      return ValidationResult.invalid('Orientation invalide: $orientation');
    }

    // 3. Récupérer les cellules de la pièce en cette orientation
    final shape = piece.positions[orientation];

    // 4. Vérifier que la pièce rentre dans le plateau
    final cellIndices = <int>[];
    for (final shapeCell in shape) {
      final sx = (shapeCell - 1) % 5;
      final sy = (shapeCell - 1) ~/ 5;
      final px = x + sx;
      final py = y + sy;

      // Vérifier bounds
      if (px < 0 || px >= solutionPlateau.width ||
          py < 0 || py >= solutionPlateau.height) {
        return ValidationResult.invalid('Pièce sort du plateau');
      }

      cellIndices.add(solutionPlateau.width * py + px);
    }

    // 5. Vérifier que toutes les cellules correspondent à la SOLUTION
    for (final idx in cellIndices) {
      final cellY = idx ~/ solutionPlateau.width;
      final cellX = idx % solutionPlateau.width;
      final solutionCell = solutionPlateau.getCell(cellX, cellY);

      if (solutionCell == 0) {
        return ValidationResult.invalid('Placement en dehors de la solution');
      }
    }

    return ValidationResult.valid();
  }

  /// Compte les isométries (rotations + symétries) d'une pièce
  static int countIsometries(int pieceId, int orientation) {
    if (pieceId == 2) return 0; // Croix I
    return orientation;
  }

  /// Valide et retourne le nombre d'isométries en un appel
  static ({bool valid, int isometries})? validateAndCountIsometries({
    required int pieceId,
    required int x,
    required int y,
    required int orientation,
    required Plateau solutionPlateau,
  }) {
    final result = validatePlacement(
      pieceId: pieceId,
      x: x,
      y: y,
      orientation: orientation,
      solutionPlateau: solutionPlateau,
    );

    if (!result.isValid) return null;

    final isometries = countIsometries(pieceId, orientation);
    return (valid: true, isometries: isometries);
  }
}
// Modified: 2026-09-30 07:27 — vérifier le pourcentage d'acuité tronqué à l'entier inférieur.
// test/piece_acuity_test.dart
// Historique: 2026-09-30 07:24 — inclure le test d'acuité dans la validation datée du bilan.
// Historique: 2026-09-29 07:49 — vérifier la note sur 1000 et la persistance de l'acuité par pièce.

import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/models/app_settings.dart';

void main() {
  test('pourcentage théorique/réel tronqué avec cas zéro', () {
    expect(
      const PieceAcuityTotals(
        placements: 7,
        theoretical: 9999,
        actual: 10000,
      ).percent,
      99,
    );
    expect(
      const PieceAcuityTotals(placements: 1, theoretical: 0, actual: 3).percent,
      0,
    );
    expect(
      const PieceAcuityTotals(placements: 1, theoretical: 0, actual: 0).percent,
      100,
    );
  });

  test('les cumuls par pièce survivent au JSON AppSettings', () {
    const settings = AppSettings(
      pieceAcuityTotals: {
        2: PieceAcuityTotals(placements: 4, theoretical: 6, actual: 8),
      },
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.pieceAcuityTotals[2]!.placements, 4);
    expect(restored.pieceAcuityTotals[2]!.theoretical, 6);
    expect(restored.pieceAcuityTotals[2]!.actual, 8);
    expect(restored.pieceAcuityTotals[2]!.percent, 75);
  });
}

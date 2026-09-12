// Modified: 2026-09-12 10:58 — barème chiffré, nature des impasses, corrections, complétion et sauvegarde.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/models/app_settings.dart';
import 'package:pentapol/pentoscope/geometry_score.dart';

void main() {
  test('barème proposé et paramètres personnalisés', () {
    const rules = GeometryRules();
    for (final row in [
      [.2, .4, 5.4],
      [.5, 2.5, 7.5],
      [.8, 6.4, 11.4],
    ]) {
      expect(rules.penalty(row[0], invalidArea: false), closeTo(row[1], 1e-10));
      expect(rules.penalty(row[0], invalidArea: true), closeTo(row[2], 1e-10));
    }
    expect(
      const GeometryRules(
        fillPenalty: 20,
        exponent: 3,
        areaPenalty: 7,
      ).penalty(.5, invalidArea: true),
      9.5,
    );
  });

  test('poche non multiple de 5 pénalisée, corrections sans double peine', () {
    final board = Plateau.allVisible(3, 5);
    // Une barre horizontale sépare deux zones de 3 et 9 cases.
    for (var x = 0; x < 3; x++) {
      board.setCell(x, 1, 1);
    }
    const start = GeometryScore();
    final fault = start.afterTransition(
      wasSolvable: true,
      nowSolvable: false,
      board: board,
    );
    expect(fault.value, closeTo(94.6, 1e-10));
    expect(
      fault.afterTransition(
        wasSolvable: false,
        nowSolvable: false,
        board: board,
      ),
      same(fault),
    );
    expect(
      fault.afterTransition(
        wasSolvable: false,
        nowSolvable: true,
        board: board,
      ),
      same(fault),
    );
    expect(
      fault
          .afterTransition(wasSolvable: true, nowSolvable: false, board: board)
          .value,
      closeTo(89.2, 1e-10),
    );
  });

  test('zone multiple de 5 : impasse subtile ; victoire sans pénalité', () {
    final board = Plateau.allVisible(3, 5);
    // Dix cases vides connexes ; le moteur signale une impasse de forme/pièces.
    for (var y = 0; y < 5; y++) {
      board.setCell(0, y, 1);
    }
    const start = GeometryScore();
    final fault = start.afterTransition(
      wasSolvable: true,
      nowSolvable: false,
      board: board,
    );
    expect(fault.penalties, closeTo(10 / 9, 1e-10));
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 3; x++) {
        board.setCell(x, y, 1);
      }
    }
    expect(
      fault.afterTransition(
        wasSolvable: true,
        nowSolvable: false,
        board: board,
      ),
      same(fault),
    );
  });

  test('réglages JSON, snapshots exacts et score plancher', () {
    const rules = GeometryRules(
      initialScore: 80,
      fillPenalty: 15,
      exponent: 3,
      areaPenalty: 8,
    );
    final settings = AppSettings(game: GameSettings(geometryRules: rules));
    final loaded = AppSettings.fromJson(
      jsonDecode(jsonEncode(settings.toJson())),
    );
    expect(loaded.game.geometryRules.toJson(), rules.toJson());
    const score = GeometryScore(rules: rules, penalties: 8.123456789);
    final restored = GeometryScore.fromJson(
      jsonDecode(jsonEncode(score.toJson())),
    )!;
    expect(restored.value, score.value);
    expect(restored.rules.toJson(), rules.toJson());
    expect(restored.experimental, isTrue);
    expect(const GeometryScore(penalties: 120).value, 0);
  });

  test('valeurs stockées invalides bornées, snapshot invalide rejeté', () {
    final rules = GeometryRules.fromJson({
      'initialScore': -10,
      'fillPenalty': 999,
      'exponent': double.nan,
      'areaPenalty': 'bad',
    });
    expect(rules.initialScore, 10);
    expect(rules.fillPenalty, 50);
    expect(rules.exponent, 2);
    expect(rules.areaPenalty, 5);
    expect(GeometryScore.fromJson({'version': 9}), isNull);
    expect(
      GeometryScore.fromJson({'version': 1, 'rules': {}, 'penalties': -1}),
      isNull,
    );
  });
}

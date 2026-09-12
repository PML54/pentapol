// Modified: 2026-09-12 10:58 — barème Géométrie expérimental réservé aux parties solo.
// Historique: 2026-09-12 07:25 — barème Géométrie paramétrable, transitions et snapshot persistable.
import 'dart:math' as math;

import 'package:pentapol/common/plateau.dart';
import 'package:pentapol/pentoscope/fault_analysis.dart';

/// Disponible aussi en release sur appareil pendant le calibrage.
/// Couper cette option au déploiement (voir docs/BAREME_GEOMETRIE.md).
const kGeometryTuningEnabled = bool.fromEnvironment(
  'PENTAPOL_SCORE_TUNING',
  defaultValue: true,
);

/// Paramètres immuables : aucune modification du réglage ne change une partie commencée.
class GeometryRules {
  final double initialScore;
  final double fillPenalty;
  final double exponent;
  final double areaPenalty;

  const GeometryRules({
    this.initialScore = 100,
    this.fillPenalty = 10,
    this.exponent = 2,
    this.areaPenalty = 5,
  }) : assert(initialScore >= 10 && initialScore <= 100),
       assert(fillPenalty >= 0 && fillPenalty <= 50),
       assert(exponent >= 1 && exponent <= 4),
       assert(areaPenalty >= 0 && areaPenalty <= 50);

  GeometryRules copyWith({
    double? initialScore,
    double? fillPenalty,
    double? exponent,
    double? areaPenalty,
  }) => GeometryRules(
    initialScore: initialScore ?? this.initialScore,
    fillPenalty: fillPenalty ?? this.fillPenalty,
    exponent: exponent ?? this.exponent,
    areaPenalty: areaPenalty ?? this.areaPenalty,
  );

  double penalty(double filled, {required bool invalidArea}) =>
      fillPenalty * math.pow(filled.clamp(0.0, 1.0), exponent) +
      (invalidArea ? areaPenalty : 0);

  Map<String, dynamic> toJson() => {
    'initialScore': initialScore,
    'fillPenalty': fillPenalty,
    'exponent': exponent,
    'areaPenalty': areaPenalty,
  };

  factory GeometryRules.fromJson(Map<String, dynamic> json) {
    double value(String key, double fallback, double min, double max) {
      final n = json[key];
      return n is num && n.isFinite ? n.toDouble().clamp(min, max) : fallback;
    }

    return GeometryRules(
      initialScore: value('initialScore', 100, 10, 100),
      fillPenalty: value('fillPenalty', 10, 0, 50),
      exponent: value('exponent', 2, 1, 4),
      areaPenalty: value('areaPenalty', 5, 0, 50),
    );
  }
}

/// Journal numérique d'une partie : barème figé et pénalités non arrondies.
/// Les défis et duels conservent leur contrat de score et n'ont pas de GeometryScore.
class GeometryScore {
  final GeometryRules rules;
  final double penalties;
  final bool experimental;

  const GeometryScore({
    this.rules = const GeometryRules(),
    this.penalties = 0,
    this.experimental = true,
  });

  double get value =>
      (rules.initialScore - penalties).clamp(0, rules.initialScore);

  GeometryScore afterTransition({
    required bool wasSolvable,
    required bool nowSolvable,
    required Plateau board,
  }) {
    if (!wasSolvable || nowSolvable) return this;
    var filled = 0;
    var total = 0;
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        final cell = board.getCell(x, y);
        if (cell == -1) continue;
        total++;
        if (cell > 0) filled++;
      }
    }
    // Le moteur indique aussi « aucune solution restante » à la victoire.
    if (total == 0 || filled == total) return this;
    final invalid = analyzeFault(board).kind == FaultKind.aireNonMultipleDe5;
    return GeometryScore(
      rules: rules,
      experimental: experimental,
      penalties:
          penalties + rules.penalty(filled / total, invalidArea: invalid),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'rules': rules.toJson(),
    'penalties': penalties,
    'experimental': experimental,
  };

  static GeometryScore? fromJson(dynamic json) {
    if (json is! Map<String, dynamic> ||
        json['version'] != 1 ||
        json['rules'] is! Map<String, dynamic>) {
      return null;
    }
    final p = json['penalties'];
    if (p is! num || !p.isFinite || p < 0) return null;
    return GeometryScore(
      rules: GeometryRules.fromJson(json['rules']),
      penalties: p.toDouble(),
      experimental: json['experimental'] != false,
    );
  }
}

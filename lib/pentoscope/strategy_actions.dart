// Modified: 2026-10-06 04:48 — calculer le minimum propre à une solution finale depuis le tiroir initial.
// Historique: 2026-10-06 04:16 — calculer le minimum de coups sur toutes les solutions du tirage.
// Historique: 2026-10-05 20:00 — compter les gestes de stratégie, y compris les tentatives refusées.
// lib/pentoscope/strategy_actions.dart

import 'package:pentapol/common/placed_piece.dart';

/// Orienter dans le tiroir puis poser chaque pièce atteint cette borne : aucune
/// translation ni suppression n'est nécessaire dans un parcours optimal.
int minimumSolutionMoves(List<PlacedPiece> solution, Map<int, int> rack) {
  final ids = solution.map((placed) => placed.piece.id).toSet();
  if (solution.length != rack.length ||
      ids.length != rack.length ||
      !ids.containsAll(rack.keys)) {
    throw StateError('Incomplete strategy solution');
  }
  return solution.fold(
    solution.length,
    (moves, placed) =>
        moves +
        placed.piece.minIsometriesToReach(
          rack[placed.piece.id]!,
          placed.positionIndex,
        ),
  );
}

enum StrategyAction { placement, rotation, symmetry, translation, removal }

class StrategyActions {
  final Map<StrategyAction, int> counts;
  final bool eligible;

  const StrategyActions({this.counts = const {}, this.eligible = true});

  int count(StrategyAction action) => counts[action] ?? 0;
  int get total => counts.values.fold(0, (sum, count) => sum + count);

  StrategyActions record(StrategyAction action) => StrategyActions(
    counts: Map.unmodifiable({...counts, action: count(action) + 1}),
    eligible: eligible,
  );

  Map<String, dynamic> toJson() => {
    'eligible': eligible,
    for (final action in StrategyAction.values) action.name: count(action),
  };

  Map<String, int> get breakdown => {
    for (final action in StrategyAction.values) action.name: count(action),
  };

  factory StrategyActions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StrategyActions(eligible: false);
    return StrategyActions(
      eligible: json['eligible'] as bool? ?? false,
      counts: Map.unmodifiable({
        for (final action in StrategyAction.values)
          action: (json[action.name] as num?)?.toInt() ?? 0,
      }),
    );
  }
}

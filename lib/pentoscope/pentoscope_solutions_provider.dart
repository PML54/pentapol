// Modified: 2026-08-29 09:26 — 6×10 dans Pentoscope (temps 2, étape 3) : famille de
//           chargement des tables de solutions, indexée par SolutionTable, paresseuse.
//           Instances propres à Pentoscope, séparées du singleton global du mode classique
//           (décision §4.3). Voir docs/PLAN_6X10_DANS_PENTOSCOPE.md §4.4.
// lib/pentoscope/pentoscope_solutions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/pentoscope/pentoscope_generator.dart' show SolutionTable;
import 'package:pentapol/services/pentapol_solutions_loader.dart';
import 'package:pentapol/services/solution_matcher.dart';

/// Charge, une fois par table et paresseusement, un [SolutionMatcher] propre à
/// Pentoscope pour une [SolutionTable] donnée.
///
/// Séparé du singleton global `solutionMatcher` (consommé par le mode classique
/// figé) : Pentoscope obtient ses propres instances, dimensionnées par la table.
/// Riverpod met le résultat en cache ; le `.bin` n'est lu qu'une fois par table.
final pentoscopeSolutionsProvider =
    FutureProvider.family<SolutionMatcher, SolutionTable>((ref, table) async {
  final matcher = SolutionMatcher(width: table.width, height: table.height);
  final canonical = await loadNormalizedSolutionsAsBigInt(table.asset);
  matcher.initWithBigIntSolutions(canonical);
  return matcher;
});

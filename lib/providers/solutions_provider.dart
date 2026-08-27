// Modified: 2026-08-27 — création : expose le chargement des solutions 6×10 comme état
//           observable Riverpod, pour supprimer la course au démarrage (défaut P4 de
//           docs/ANALYSE_STOCKAGE_POSITIONS.md). Remplace le Future.microtask
//           non attendu qui était dans main().
// lib/providers/solutions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pentapol/services/pentapol_solutions_loader.dart';
import 'package:pentapol/services/solution_matcher.dart';

/// Charge les 2339 solutions canoniques du plateau 6×10 et initialise
/// [solutionMatcher] avec les 9356 variantes.
///
/// Retourne le nombre de solutions disponibles (9356 en fonctionnement normal).
///
/// ## Pourquoi ce provider existe
///
/// Le mode classique appelle `countPossibleSolutions()` dès la construction de son
/// provider. Tant que [solutionMatcher] n'est pas initialisé, cet appel lève un
/// `StateError` que `plateau_solution_counter` attrape et convertit en `null` :
/// le compteur de solutions disparaît de l'interface **sans aucun message**.
///
/// Exposer le chargement comme un état observable permet à `PentominoGameScreen`
/// de refuser de monter le jeu tant que les données ne sont pas prêtes, au lieu
/// de le monter dans un état silencieusement dégradé.
///
/// ## Cycle de vie
///
/// Riverpod met le résultat en cache : le chargement n'a lieu qu'une seule fois,
/// quel que soit le nombre d'écrans qui l'observent. Le provider n'est pas
/// `autoDispose`, il survit donc aux allers-retours entre écrans.
///
/// Le chargement est **amorcé sans attente** depuis `main.dart`, pour qu'il soit
/// terminé avant que l'utilisateur ait navigué jusqu'au mode classique. Pentoscope,
/// qui utilise `PentoscopeSolver` et non [solutionMatcher], n'est pas ralenti.
///
/// En cas d'échec, `ref.invalidate(solutionsReadyProvider)` relance une tentative.
final solutionsReadyProvider = FutureProvider<int>((ref) async {
  // Déjà initialisé (hot reload, ou provider invalidé après un succès) : rien à faire.
  if (solutionMatcher.totalSolutions > 0) {
    return solutionMatcher.totalSolutions;
  }

  final canonicalSolutions = await loadNormalizedSolutionsAsBigInt();
  solutionMatcher.initWithBigIntSolutions(canonicalSolutions);

  return solutionMatcher.totalSolutions;
});

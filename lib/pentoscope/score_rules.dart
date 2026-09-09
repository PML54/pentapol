// Modified: 2026-09-09 05:29 — Centralisation des RÈGLES de score (CDC §4.2/§4.6) : l'acuité (ratio
//           plafonné à 100 %, pourcentage entier), la comparaison « meilleure acuité » sans flottant,
//           et la « vision parfaite ». Fonctions pures, SANS dépendance (importables par la couche
//           drift, l'API, les écrans et completion_metrics) → une seule définition, testable, réutilisée.
// lib/pentoscope/score_rules.dart

/// Acuité isométrique (CDC §4.2), **plafonnée à 1.0** (100 %) : `min(1, (minIso+1)/(iso+1))`.
///
/// Le `+1` traite `minIso = 0` ; le plafond couvre le cas de l'indice, qui pose une pièce sans que
/// le joueur fasse l'isométrie (`minIso` la compte, `iso` non → ratio > 1). Décision de Paul
/// (2026-09-09) : le plafond s'applique **partout** — records, bilan, classement — pas seulement au
/// maillot de fin de partie. Pour une partie **propre** (sans aide), `iso ≥ minIso` toujours → le
/// ratio est déjà ≤ 1 et le plafond n'a aucun effet visible (les records ne stockent que le propre).
double acuityRatio(int minIso, int isometryCount) {
  final r = (minIso + 1) / (isometryCount + 1);
  return r > 1.0 ? 1.0 : r;
}

/// Acuité en **pourcentage entier** (0..100), plafonnée. Arrondi identique à l'ancien affichage.
int acuityPercent(int minIso, int isometryCount) =>
    (acuityRatio(minIso, isometryCount) * 100).round();

/// Compare deux acuités par **produit croisé** (sans flottant, donc sans perte). Renvoie `true` si
/// le candidat `(newMinIso, newIso)` **bat** le meilleur courant, ou s'il n'y a pas encore de best.
///
/// Ordre total : ratio `(m+1)/(i+1)` le plus grand = meilleur. Le plafond ne s'applique **pas** ici
/// — c'est une comparaison d'ordre, pas une valeur affichée (et sur des parties propres, ratio ≤ 1).
bool isBetterAcuity(int? bestMinIso, int? bestIso, int newMinIso, int newIso) {
  if (bestMinIso == null || bestIso == null) return true;
  return (newMinIso + 1) * (bestIso + 1) > (bestMinIso + 1) * (newIso + 1);
}

/// « Vision parfaite » (CDC §4.6) : `isometryCount == minIso` (aucun geste de trop). La médaille
/// exige en plus une partie **sans aide** — cette condition-là se traite à l'appel.
bool isPerfectVision(int minIso, int isometryCount) => isometryCount == minIso;

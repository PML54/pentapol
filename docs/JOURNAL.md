# Journal — état, décisions, passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`. §ÉTAT est **réécrite** à chaque passage ;
> §DÉCISIONS et §PASSATIONS ne font que s'allonger.

---

## §ÉTAT — au 2026-08-28 19:33

**Chantier en cours** : unification de la manipulation des pièces sur les 3 modules
(`docs/PLAN_UNIFICATION_PIECES.md`). Étapes 0 à 2 faites, étape 3 en cours par famille :
Chrono ✅, Preview & drag ✅, Sélection ✅ (temps 1 et 2 + dettes). Restent Isométries,
Barre, Placement, puis les étapes 4 et 5.

**Poussé sur `origin/main`** : 6 commits, `f3a13a8..74e56b7`.

**⚠️ Jamais exécuté : le test manuel des 3 modules.** Six commits sont poussés, dont un
changement de modèle de données (stay + mask) et une suppression de ~700 lignes. C'est le
point de reprise prioritaire, avant tout nouveau travail.

**Non commité à cette heure** : `docs/PLAN_UNIFICATION_PIECES.md` (modifié),
`docs/PLAN_SUPPRESSION_DEMO.md`, `docs/MODUS_VIVENDI.md`, `docs/JOURNAL.md` (nouveaux),
`CLAUDE.md` (modifié). Plus du bruit de plateforme à trier : `ios/`, `macos/`,
`.metadata`, `analysis_options.yaml`, `pubspec.lock`.

**Dette technique connue, non traitée** : `flutter pub add collection` (lint
`depend_on_referenced_packages`) ; branche de preview cyan morte dans
`pentoscope_board.dart` (lit `state.isSnapped`, que personne n'écrit) ; troisième
implémentation du chrono dans `pentoscope_mp_provider.dart`, morte mais publique.

---

## §DÉCISIONS

Une ligne par décision non prévue au plan. Format : date — auteur — décision — où c'est
détaillé.

1. **2026-08-27 — Paul** — le magnétisme devient assistant partout : `_snapRadius` du
   mode classique porté de 2 à 10 plutôt que de porter l'implémentation de Pentoscope.
   → `PLAN_UNIFICATION_PIECES.md`, étape 3.
2. **2026-08-27 — cowork** — `reset` et `build` ne sont **pas** alignés entre les deux
   providers. → `PLAN_UNIFICATION_PIECES.md`, §étape 2.
3. **2026-08-28 — Paul** — la rotation non déposée est **abandonnée** à l'annulation et
   au changement de sélection ; ne pas synchroniser `placedPieces` dans les opérations
   d'isométrie. → `PLAN_UNIFICATION_PIECES.md`, « Sélection, temps 2 ».
4. **2026-08-28 — CLI** — `validateSelection()` : un clic sur une case **vide** valide la
   pièce sélectionnée à sa position et son orientation courantes, au lieu d'annuler.
   `cancelSelection` (abandon) reste inchangée pour ses autres appelants. Rétablit le
   comportement d'avant le temps 2 pour ce geste seul. → commit `74e56b7`.
   **Prise sans avoir été posée à Paul ; à confirmer au test manuel.**
5. **2026-08-28 — Paul** — suppression de la démo automatique et de toute la machinerie
   de tutoriel, périmètre A+B+C+D. → `PLAN_SUPPRESSION_DEMO.md`.
6. **2026-08-28 — Paul** — `docs/` appartient au CLI côté git ; protocole entre agents
   inscrit dans `CLAUDE.md`. → `MODUS_VIVENDI.md`.

---

## §PASSATIONS

**2026-08-28 19:33 — cowork → toi.** Écrit `MODUS_VIVENDI.md`, `JOURNAL.md`, et le bloc
« Protocole entre agents » dans `CLAUDE.md`. Rien à appliquer côté code.
**Reste** : faire commiter `docs/` + `CLAUDE.md` au CLI ; trier le bruit de plateforme ;
exécuter le test manuel des 3 modules ; trancher la décision n°4.

**2026-08-28 21:05 — CLI → cowork.** Six commits poussés (`f3a13a8..74e56b7`) : helper
`_rebuildPlateau`, bascule stay + mask, dettes `solutionsCount` et `isComplete`,
suppression de la démo (2 commits), `validateSelection`. `flutter analyze` : 0 warning.
**Non fait** : le test manuel, et le commit de `docs/`.

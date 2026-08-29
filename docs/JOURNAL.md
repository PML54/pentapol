# Journal — état, décisions, passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`. §ÉTAT est **réécrite** à chaque passage ;
> §DÉCISIONS et §PASSATIONS ne font que s'allonger.

---

## §ÉTAT — au 2026-08-29

**Changement de chantier.** L'unification classical ↔ pentoscope est **suspendue**. Le
mode classique n'est plus modifié ; Pentoscope devient la référence de la manipulation des
pièces et reçoit une taille `6×10 / 12 pièces`, branchée sur les 9356 solutions connues.
Plan à appliquer : `docs/PLAN_6X10_DANS_PENTOSCOPE.md`, en deux temps, **dans l'ordre**.

`docs/PLAN_UNIFICATION_PIECES.md` reste valide comme historique et comme socle : ses
étapes 0 à 2 (`PlacedPiece` commun, `PieceManipulationState`, `TransformationResult`,
`ViewOrientation`, les deux mixins) sont ce qui rend le port possible. Ses étapes 3
(familles Isométries, Barre, Placement), 4 et 5 ne sont plus à l'ordre du jour.

**Git** : `origin/main` à `813aa94`. Local en avance de deux commits **non poussés** :
`f7742cc` (protocole) et `4539ed8` (journal). S'y ajoute
`docs/PLAN_6X10_DANS_PENTOSCOPE.md`, non suivi.

**Test manuel** : Paul teste sur son iPhone, en release, avec

```bash
flutter run --release -d 00008150-000165D4027B401C
```

C'est le juge de référence — ni le CLI ni cowork ne testent. **L'effort de test va
désormais sur Pentoscope**, pas sur le mode classique : c'est Pentoscope qui devient le
seul moteur de manipulation, et son 6×10 est ce qui doit être validé.

> ⚠️ En `--release`, `debugPrint` est supprimé à la compilation : tout critère
> d'acceptation formulé sur la console doit être reformulé en observation à l'écran.

**Défauts relevés le 2026-08-29, laissés en l'état** (mode classique, qu'on ne touche
plus) — détail en §5 du plan 6×10 :

- `game_board.dart` l.447 appelle `applyIsometryRotation()`, méthode inexistante, passée
  par un `notifier` non typé donc `dynamic` : `NoSuchMethodError` au double-tap sur une
  pièce posée sélectionnée. Invisible pour `flutter analyze`.
- le mode classique n'appelle jamais `setDragging` ; `state.isDragging` y est mort.
- miniature au déplacement signalée par Paul : cause probable `PieceRenderer`, taille de
  case codée en dur à 22 px. Non confirmée par observation.

**Dette technique connue, non traitée** : `flutter pub add collection` (lint
`depend_on_referenced_packages`) ; branche de preview cyan morte dans
`pentoscope_board.dart` ; troisième implémentation du chrono dans `pentoscope_mp_provider.dart`.

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

7. **2026-08-29 — Paul** — le mode classique n'est plus modifié ; Pentoscope devient la
   référence de la manipulation des pièces et reçoit une taille 6×10 / 12 pièces adossée
   aux 9356 solutions. Les autres tailles gardent le calcul à la volée.
   → `PLAN_6X10_DANS_PENTOSCOPE.md`.
8. **2026-08-29 — cowork** — **la décision n°3 reposait sur une affirmation fausse.** Elle
   disait que Pentoscope « n'écrit lui non plus que `selectedPlacedPiece` (l.1147, l.1396) ».
   Vérification faite, à ces lignes exactes (aujourd'hui 1152 et 1401) Pentoscope écrit
   `placedPieces: updatedPlacedPieces` : ses deux chemins d'isométrie **committent** la
   rotation. Les deux modes font donc l'inverse l'un de l'autre sur « tourner une pièce
   posée puis annuler » — classique abandonne, Pentoscope conserve. Sans conséquence
   pratique depuis la décision n°7 (le classique est figé, Pentoscope est la référence),
   mais **ne pas reprendre l'argument d'alignement de la décision n°3**, il est faux.

## §PASSATIONS

**2026-08-28 19:33 — cowork → toi.** Écrit `MODUS_VIVENDI.md`, `JOURNAL.md`, et le bloc
« Protocole entre agents » dans `CLAUDE.md`. Rien à appliquer côté code.
**Reste** : faire commiter `docs/` + `CLAUDE.md` au CLI ; trier le bruit de plateforme ;
exécuter le test manuel des 3 modules ; trancher la décision n°4.

**2026-08-28 21:05 — CLI → cowork.** Six commits poussés (`f3a13a8..74e56b7`) : helper
`_rebuildPlateau`, bascule stay + mask, dettes `solutionsCount` et `isComplete`,
suppression de la démo (2 commits), `validateSelection`. `flutter analyze` : 0 warning.
**Non fait** : le test manuel, et le commit de `docs/`.

**2026-08-28 21:38 — CLI → cowork.** Commité les plans (`813aa94`, poussé) puis
`MODUS_VIVENDI.md` + `JOURNAL.md` + section CLAUDE.md (`f7742cc`, **non poussé**).
Protocole appliqué : §ÉTAT réécrit ; fait de projet retiré de `~/.claude/` (règle 4).
**Reste** : pousser `f7742cc` (et ce commit de journal) ; test manuel des 3 modules ;
trancher la décision n°4.

**2026-08-29 — cowork → toi.** Écrit `docs/PLAN_6X10_DANS_PENTOSCOPE.md` (316 l.) et
réécrit §ÉTAT ; ajouté les décisions 7 et 8. Rien appliqué au code.
**À faire côté CLI, dans l'ordre** : temps 1 du plan (la taille 6×10 existe et se joue,
sans les 9356), puis test manuel par Paul, puis temps 2 (branchement de `solutionMatcher`).
Ne pas commencer le temps 2 avant le test du temps 1 — c'est ce qui rend le chantier
réversible.
**Reste, hérité** : pousser `f7742cc` et `4539ed8`.

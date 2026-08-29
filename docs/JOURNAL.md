# Journal — état, décisions, passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`. §ÉTAT est **réécrite** à chaque passage ;
> §DÉCISIONS et §PASSATIONS ne font que s'allonger.

---

## §ÉTAT — au 2026-08-29 10:05

**Temps 2 du 6×10 dans Pentoscope : FAIT** (6 étapes en 4 commits de code
`52823f7` → `97f8da6`, poussé). Pentoscope
route ses réponses « solution » par une `SolutionSource` (table 6×10 ou solveur à la volée),
choisie au seul site `_makeSolutionSource`. Le 6×10 utilise la vraie table des 9356 :
`hasPossibleSolution` réel (l'indice peut virer au rouge), `applyHint` = solution compatible
**aléatoire** (décision de Paul §4.6), et un **compteur de solutions** dans l'AppBar, gaté
par `GameSettings.showSolutionCounter` (défaut true, rouge à 0). `SolutionMatcher`/loader
paramétrés additivement ; le singleton global du classique est intact.
`flutter analyze` : 0 warning ; critères §4.7 OK ; `lib/classical/` intact.

**Temps 1 : validé au test appareil (Paul).** Les étapes 3-4-6 du temps 2 aussi (latence 1er
démarrage imperceptible → pas de garde de montage, décision 14).

**Prochain pas : TEST MANUEL du temps 2 par Paul** (§4.7), surtout l'**étape 5 (compteur)**,
pas encore testée : 9356 sur plateau vide, décroît à chaque pose, rouge en impasse ; autres
tailles → compteur absent et comportement inchangé ; **mode classique → compteur toujours là
(le canari §4.3)**.

**Le mode classique reste figé** (décision n°7). Rien sous `lib/classical/` ni
`lib/screens/pentomino_game/` touché.

**Git** : `origin/main` à jour, local aligné — dernier commit de code `97f8da6`, plus le
commit de journal qui porte ce §ÉTAT.

**Test manuel** : Paul, iPhone en release —

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` supprimé : critère console → observation écran.

**Reste après validation** : §5 du plan (tables 5×12/4×15/3×20) — d'abord rendre
`PentominoSolver.maxSeconds` paramétrable (décision n°10), puis ouvrir ces tailles (objections
d'interface §5.4 : le sélecteur `Row` d'`Expanded` doit changer de forme avant 12 entrées).

**Défauts du mode classique laissés en l'état** (plan §6) : double-tap = `NoSuchMethodError`
(`applyIsometryRotation()` inexistante) ; `setDragging` jamais appelé ; miniature au
déplacement (`PieceRenderer` 22 px).

**Dette technique** : `flutter pub add collection` ; preview cyan morte dans
`pentoscope_board.dart` ; `maxSeconds=30` à paramétrer avant §5 ; 3e chrono dans
`pentoscope_mp_provider.dart`.

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

9. **2026-08-29 — Paul** — d'autres rectangles complets suivront le 6×10 : **5×12, 4×15,
   3×20**. L'origine des solutions est donc portée par la configuration sous forme de
   **référence** (`SolutionTable?` sur `PentoscopeSize`), pas d'un booléen `isComputed`, et
   n'est lue qu'à un seul endroit (`startPuzzle`) pour choisir un `SolutionSource`.
   → `PLAN_6X10_DANS_PENTOSCOPE.md` §4 et §5.
10. **2026-08-29 — cowork** — **le mystère du `solutions_6x10_brutes.bin` incomplet est
   résolu** : 8175 sur 9356 parce que `PentominoSolver.maxSeconds` vaut 30 et que
   `findAllSolutions` fait un simple `return` à l'expiration. Ce n'est pas un défaut de
   complétude du solveur. À rendre paramétrable **avant** de générer les trois nouvelles
   tables, sous peine de les tronquer de la même façon.
11. **2026-08-29 — CLI** — le court-circuit `hasPossibleSolution` du §3.2c est posé **à
   l'intérieur** de `_checkHasPossibleSolutionWith` (condition `size.table != null`), en un
   seul point, plutôt qu'aux 3 sites d'appel nommés par le plan. Le plan en avait **omis 2** :
   la méthode a 5 appelants (l.251, 376, 804, 1099, 1349), tous couverts ainsi. Forme
   `size.table != null` alignée décision n°9. → `fed0ef6`.
12. **2026-08-29 — CLI** — l'enum `SolutionTable` est créé au temps 1 avec **la seule valeur
   `r6x10`**, pas les quatre de §4.1 : les assets des trois autres rectangles (5×12, 4×15,
   3×20) n'existent pas encore et relèvent de §5. Les valeurs manquantes s'ajouteront avec
   leurs `.bin`. → `fed0ef6`.
13. **2026-08-29 — CLI** — `applyHint` **laissé inchangé** au temps 1 : sur le 6×10 il
   appelle `_solver.findSolutionFrom` (backtracking à la demande, pas `solutionMatcher`),
   donc temps-1-compatible mais lent au clic sur l'indice. À traiter au temps 2 (plan §4.6,
   « question ouverte pour Paul »). **Résolu au temps 2** → décision 15.
14. **2026-08-29 — CLI** — **pas de garde de montage d'écran** (§4.4). `startPuzzle` `await`
   le chargement de la table ; la source n'est jamais consultée avant. Le compteur n'apparaît
   donc jamais vide sans message (critère §4.7 satisfait). Latence 1er démarrage 6×10
   **imperceptible sur iPhone** (Paul). Si un jour elle gêne, ajouter la garde de pré-chargement.
15. **2026-08-29 — Paul** — l'indice du 6×10 tire une **solution compatible aléatoire** de la
   table (comme le mode classique), pas la première. `hintFrom` reçoit `remaining` (le plan
   montrait `hintFrom(plateau)`) pour que `LiveSolutionSource` ait la liste des pièces ; la
   table l'ignore. → `35ba8e4`, `PLAN_6X10_DANS_PENTOSCOPE.md` §4.6.
16. **2026-08-29 — Paul** — compteur de solutions **visible par défaut**, avec bascule oui/non
   dans les réglages (le champ `GameSettings.showSolutionCounter`, défaut true, existait déjà).
   Placé dans l'AppBar en jeu normal, rouge à 0. Masqué pour les tailles sans table. → `97f8da6`.

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

**2026-08-29 (suite) — cowork → toi.** Sur décision n°9, réécrit §4 du plan (référence
`SolutionTable?` et interface `SolutionSource`, un seul site de lecture) et ajouté §5, les
trois autres tables. Deux contraintes dures y sont posées : la paramétrisation de
`SolutionMatcher` doit être **additive** (le mode classique, figé, consulte le singleton
global et son `_toBigIntMask` refuse tout format autre que 6×10), et `maxSeconds` doit
devenir paramétrable avant toute génération. Le temps 1 est inchangé et reste le premier
travail à faire.

**2026-08-29 07:46 — CLI → cowork.** Temps 1 appliqué et commité (`fed0ef6`, non poussé) :
`size6x10` + `SolutionTable.r6x10` + court-circuit générateur, garde
`_checkHasPossibleSolutionWith`. `flutter analyze` 0 warning, critères §3.4 OK. Rien touché
sous `lib/classical/` ni `lib/screens/pentomino_game/`. Décisions 11-13 ajoutées ; §3.2d/e
étaient déjà satisfaits par le code (`startPuzzle` garde déjà le bloc `minIsometries`).
**À faire, dans l'ordre** : test manuel du 6×10 par Paul (le juge), **puis** temps 2 —
ne pas commencer le temps 2 avant. **Reste** : pousser `4f17ca8` + `fed0ef6` (et ce commit
de journal) ; élucider le doublon `4f17ca8`/`341021c`.

**2026-08-29 10:05 — CLI → cowork.** Temps 1 validé au test appareil (Paul), puis **temps 2
appliqué et poussé en **4 commits de code** (`52823f7`, `0d780e0`, `35ba8e4`, `97f8da6`) : `SolutionMatcher`/loader
paramétrés (additif), `SolutionSource` + 2 impls, famille de chargement, câblage `_solutions`
(un seul site lisant `size.table`), `applyHint` via `hintFrom`, compteur à l'écran.
`flutter analyze` 0 warning, critères §4.7 OK, `lib/classical/` intact. Décisions 14-16
ajoutées (14 = pas de garde de montage ; 15 = indice aléatoire, réponse de Paul ; 16 =
compteur visible par défaut). **À faire** : test manuel du temps 2 par Paul, **surtout le
compteur (étape 5, pas encore testée)**. Le doublon `4f17ca8`/`341021c` reste à élucider —
sans effet fonctionnel (mêmes docs).

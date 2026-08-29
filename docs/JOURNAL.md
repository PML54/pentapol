# Journal — état, décisions, passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`. §ÉTAT est **réécrite** à chaque passage ;
> §DÉCISIONS et §PASSATIONS ne font que s'allonger.

---

## §ÉTAT — au 2026-08-29, seconde session cowork (fin)

**Test du temps 2 : point 1 validé par Paul** — le compteur du 6×10 affiche 9356 et
décroît. Point 3 (la bascule) **ininstruisable** : l'écran de Réglages est inatteignable
(décision 23). Points 2, 4 et 5 non instruits, et **ils ne bloquent plus** : le canari du
§4.3 est remplacé par un test unitaire de `SolutionMatcher` (décision 24), préalable à la
suppression.

**Chantier lancé : la suppression du mode classique** — voir §PASSATIONS. Ce qui reste du
test appareil du temps 2 (§4.7 du plan 6×10), étape 5, le
**compteur de solutions**. Rien n'est exécutable avant — ni le §5 du plan 6×10, ni la
suppression du mode classique. Ce test est doublement important : le compteur du mode
classique est le **canari** de la §4.3, et le module qui le porte est promis à la
suppression.

**Chantier annoncé : supprimer totalement le mode classique** (décision 19).
`docs/PLAN_SUPPRESSION_CLASSICAL.md`, 243 l. C'est devenu mécanique parce que le temps 2 a
donné à Pentoscope sa chaîne complète — `grep -rn 'solutionMatcher|countPossibleSolutions|
solutionsReadyProvider' lib/pentoscope/` → vide.

- **Plancher : 3279 lignes** sans aucune décision.
- **505 lignes déménagent d'abord** (`piece_renderer`, `piece_border_calculator`,
  `draggable_piece_widget`, `game_colors`, `game_constants`) : Pentoscope et le multijoueur
  les lisent.
- **Trois points d'entrée** à couper, dont `pentoscope_game_screen.dart` l.237 — c'est
  Pentoscope lui-même qui ouvre le mode classique.
- **Les deux fonctionnalités sont ré-hébergées, pas abandonnées** (décisions 21 et 22).
  Le navigateur est **moins cher que prévu** (son lien au singleton est mort) ; l'historique
  est **plus cher que je ne l'avais dit** — il demande une migration drift, c'est un
  chantier à part.
- **Ordre en 7 étapes**, chacune réversible seule. La règle qui ne souffre pas d'exception :
  brancher le navigateur dans Pentoscope **avant** de couper l'accès au mode classique.

**Le 3×20 est abandonné** (décision 20) : tables à produire = **5×12 et 4×15**. Motif
rectifié au plan §5.6 — ce n'est pas l'affichage (cases à 50 % de celles du 6×10), c'est le
jeu (2 solutions, donc compteur à 0 et indice rouge en permanence).

**Préparé, inchangé** : §5.1 le correctif `PentominoSolver` (deux défauts — `maxSeconds` non
paramétrable ET troncature invisible ; le correctif porte sur la **signature**
`({solutions, truncated})`, gratuit car un seul appelant), §5.2 généralisation de l'outil,
§5.4 les trois vérifications d'acceptation, §5.7 l'ordre — jamais les valeurs d'enum avant
le sélecteur.

**À ne pas refaire** : `solutions_6x10_normalisees.bin` est complet (8175 brutes couvraient
2339/2339 classes). À reproduire une fois, comme non-régression du correctif §5.1.

**Le mode classique reste figé** en attendant sa suppression (décision n°7).

**Git** : `origin/main` à `1833aba`. Modifiés/nouveaux non commités : `docs/JOURNAL.md`,
`docs/PLAN_6X10_DANS_PENTOSCOPE.md`, `docs/PLAN_SUPPRESSION_CLASSICAL.md`. Ces docs ne
pilotent pas de code immédiat : à commiter **seuls, en début de prochaine session du CLI**,
avant toute modification de `lib/` (MODUS_VIVENDI §5). Le reste du `git status` est du bruit
de plateforme.

**Test manuel** : Paul, iPhone en release —

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` supprimé : critère console → observation écran.

**Défauts du mode classique** : ils s'éteindront avec le module
(`PLAN_SUPPRESSION_CLASSICAL.md` §7). Seule la miniature (`PieceRenderer`, case à 22 px en
dur) survit — ce fichier déménage, c'est le moment d'y ajouter un paramètre `cellSize`.

**Dette technique** : `flutter pub add collection` ; preview cyan morte dans
`pentoscope_board.dart` ; 3e chrono dans `pentoscope_mp_provider.dart` (multijoueur, non
concerné) ; **trois** implémentations du couple (pieces, mask) — la suppression en éteint
une, il en restera deux dont `common/bigint_plateau.dart`, orpheline et la mieux écrite.

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

17. **2026-08-29 — cowork** — **sélecteur de taille : deux groupes, pas une rangée de 12.**
    Les 8 puzzles gardent la rangée et les labels d'aujourd'hui ; les 4 rectangles complets
    forment une seconde rangée de 4, labels `'6×10'`…`'3×20'`. Le critère de séparation est
    `size.table == null`, qui existe déjà. Motif : ce n'est pas qu'une question de place —
    les deux familles diffèrent par les pièces (tirées / toutes), la configuration (une par
    tirage / une seule) et l'origine des solutions ; et `label` valant `numPieces`, les
    quatre rectangles s'afficheraient tous « 12 ». → plan §5.5.
18. **2026-08-29 — cowork** — **le 3×20 est généré et vérifié mais n'entre pas dans le
    sélecteur.** 2 solutions à symétrie près sur 60 cases : le compteur tomberait à 0 après
    très peu de pièces et l'indice serait rouge en permanence. Il sert de fixture de
    validation de la chaîne — seule table assez petite (8 solutions) pour être vérifiée à la
    main. Son ouverture au joueur reste une décision de jeu, à prendre après avoir vu le
    compteur sur le 4×15. **Recommandation de cowork, à confirmer ou infirmer par Paul.**
    → plan §5.6.

19. **2026-08-29 — Paul** — **intention de supprimer totalement le module classique.**
    Devenu possible : depuis le temps 2 (`35ba8e4`), Pentoscope a sa propre chaîne de
    solutions et ne lit plus rien du chemin classique (`grep -rn 'solutionMatcher|
    countPossibleSolutions|solutionsReadyProvider' lib/pentoscope/` → vide). Inventaire,
    objections et ordre d'exécution : `PLAN_SUPPRESSION_CLASSICAL.md`. **Non exécutable en
    l'état** — deux décisions de fonctionnalité manquent (navigateur de solutions,
    historique de parties en base) et le test appareil du temps 2 n'a pas été rapporté.
20. **2026-08-29 — Paul** — **le 3×20 est abandonné pour l'instant**, ni généré ni ouvert
    au joueur ; les tables à produire sont 5×12 et 4×15. Motif rectifié par cowork :
    l'objection d'affichage est faible (cases à 50 % de celles du 6×10), la raison dirimante
    est de jeu — 2 solutions à symétrie près, donc compteur à 0 et indice rouge en
    permanence. → plan 6×10 §5.6. *(Remplace la recommandation n°18.)*

21. **2026-08-29 — Paul** — **le navigateur de solutions est ré-hébergé dans Pentoscope**,
    pas abandonné. Découverte en écrivant le mode opératoire : son couplage au singleton est
    du **code mort** — les deux sites vivants passent par `.forSolutions`, le constructeur
    par défaut n'a aucun appelant. L'écran n'a donc besoin d'aucun `SolutionMatcher`. Le
    travail est côté appelant : une 4ᵉ méthode `compatibleSolutions(Plateau)` sur
    `SolutionSource`. → `PLAN_SUPPRESSION_CLASSICAL.md` §3.1.
22. **2026-08-29 — Paul** — **l'écriture de l'historique de parties est portée dans
    Pentoscope.** ⚠️ **Correction d'une estimation de cowork** : j'avais annoncé « une
    dizaine de lignes », c'est faux. `GameSessions.solutionNumber` est non nullable et sert
    de clé à `SolutionStats` ; Pentoscope ne connaît pas ce numéro (→ 5ᵉ méthode
    `solutionIndexOf`), et il n'est **pas unique entre tables** — la solution n°5 du 6×10 et
    celle du 5×12 se confondraient. Il faut donc une **migration drift** (colonne de plateau,
    `solutionNumber` nullable pour les tailles sans table). Chantier à part, à ne pas mêler
    au commit de suppression. → §3.2.

23. **2026-08-29 — cowork** — **défaut découvert pendant le test de Paul : l'écran de
    Réglages est inatteignable.** `main.dart` démarre sur `PentoscopeGameScreen` (l.77) ; les
    routes `'/home'` et `'/game'` sont déclarées (l.80-81) mais **aucun `pushNamed` n'existe
    dans le dépôt**. `HomeScreen` n'est donc joignable par aucun chemin, et avec lui
    `SettingsScreen` (seule porte vers la bascule « Compteur de solutions » de la décision 16,
    `settings_screen.dart` l.168-175) et `DatabaseDebugScreen`. Tous les réglages de jeu sont
    hors d'atteinte, pas seulement le compteur. **Correctif à part, plus urgent que la
    suppression du mode classique** ; et `HomeScreen` ne doit surtout pas être supprimé avec
    lui. → `PLAN_SUPPRESSION_CLASSICAL.md` §2.1.

24. **2026-08-29 — cowork** — **le canari du §4.3 est remplacé, pas contourné.** Le point 5
    du test (« le compteur du mode classique est toujours là ») devient sans objet dès lors
    que ce module est supprimé : ce qu'il prouvait, c'est que le câblage classique n'avait
    pas été abîmé, et ce câblage disparaît. Ce qui reste à garantir, c'est que
    `SolutionMatcher` répond juste — et un **test unitaire** le fait mieux qu'une observation
    à l'écran : plateau 6×10 vide → 9356, plateau à une pièce → compte stable entre deux
    exécutions. Ce test est l'étape 2 de `PLAN_SUPPRESSION_CLASSICAL.md` §5 et il est
    **préalable** à toute suppression. Le point 1 du test appareil ayant été validé par Paul,
    la suppression n'est plus bloquée par les points 2, 4 et 5.

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

**2026-08-29 — cowork → toi.** Écrit le §5 complet du plan (correctif `PentominoSolver`,
généralisation de l'outil, vérifications d'acceptation, deux décisions d'interface, ordre
d'exécution), mis §4.4 et §4.6 en accord avec ce qui a été livré, ajouté les décisions 17 et
18, réécrit §ÉTAT. **Aucun code touché.**
**Prochain pas : ton test appareil du temps 2**, §4.7 du plan, l'étape 5 avant tout. Le §5
n'est exécutable qu'après.

**2026-08-29 (seconde session) — cowork → toi.** Écrit `docs/PLAN_SUPPRESSION_CLASSICAL.md`
(200 l.) : inventaire mesuré, les 505 lignes à déménager avant, les 3 points d'entrée, les
2 décisions de fonctionnalité qui bloquent, l'ordre en 7 étapes dont chacune est réversible
seule. Rectifié §5.6 du plan 6×10 (3×20 abandonné, et pour la bonne raison). Décisions 19
et 20, §ÉTAT réécrit. **Aucun code touché.**
**Prochain pas, inchangé : le test appareil du temps 2**, §4.7, étape 5 avant tout.

**2026-08-29 (seconde session, fin) — cowork → toi.** Décisions 21 et 22 prises par Paul ;
§3 du plan de suppression réécrit en mode opératoire, ordre d'exécution passé à 7 étapes.
Deux rectifications de mes propres estimations y figurent — le navigateur est moins cher,
l'historique plus cher. §ÉTAT réécrit. **Aucun code touché.**
**Prochain pas, inchangé et bloquant : ton test appareil du temps 2**, §4.7, étape 5.

**2026-08-29 — cowork → toi (lancement de la suppression).** Décision 24 : le canari est
remplacé par un test unitaire, la suppression n'est plus bloquée par la fin du test
appareil. Phrase de lancement remise à Paul pour les étapes 2, 3, 5, 6 et 7 de
`PLAN_SUPPRESSION_CLASSICAL.md` §5 — **l'étape 4 (historique en base) en est exclue**,
c'est un chantier à part qui demande une migration drift. Le correctif de l'accès aux
Réglages (décision 23) en est exclu aussi.

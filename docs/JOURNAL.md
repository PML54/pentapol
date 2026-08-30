# Journal — état, décisions, passations

> Fichier de coordination entre Claude Code (CLI) et Claude cowork.
> Protocole : `docs/MODUS_VIVENDI.md`. §ÉTAT est **réécrite** à chaque passage ;
> §DÉCISIONS et §PASSATIONS ne font que s'allonger.

---

## §ÉTAT — au 2026-08-30, fin de session CLI (§8 appliquée)

**La suppression du mode classique est faite, poussée et vérifiée indépendamment**
(décision 27) : `lib/` passe de 23 036 à 19 839 lignes, −3197 ; aucun renvoi mort.

**§8 est appliquée** — 4 commits `35e9d0e..971e8cc`, un par étape, `flutter analyze` 0 warning,
critères §8.4 tous verts (grep) :
1. `PentoscopeDifficulty` unifié — `piece_difficulty.dart` **supprimé en entier** (il était
   100 % orphelin, cf. décision 36) ; le déclarant de `pentoscope_provider.dart` reste seul.
2. Bouton Réglages ⚙️ dans l'AppBar de Pentoscope (portrait **et** paysage, cf. décision 38) →
   `SettingsScreen`.
3. Dialogue « Nouvelle partie » (`StatefulBuilder`) : taille + difficulté + « montrer la
   solution », bouton **Lancer** appelant `startPuzzle` directement. `PentoscopeMenuScreen`
   supprimé, `changeBoardSize` aussi (plus d'appelant).
4. `HomeScreen` abandonné : `git rm home_screen.dart`, route nommée et import retirés de
   `main.dart`. L'app démarre directement sur `PentoscopeGameScreen`.

**Deux chantiers décidés restent à appliquer.** Dans `PLAN_SUPPRESSION_CLASSICAL.md` :

- **§9 — abandon de l'historique** (décision 32, qui **annule la 22**). Deux tables, sept
  méthodes, `DatabaseDebugScreen` : rien n'a d'appelant vivant. Depuis §8 étape 4,
  `DatabaseDebugScreen` (255 l.) est **franchement orphelin** — plus aucun écran n'y mène.
  Le seul point non mécanique est la **migration drift** — le projet n'en a jamais eu
  (`schemaVersion => 1`).
- **§5 du plan 6×10** — tables 5×12 et 4×15, inchangé et non commencé.

**Conséquence de la suppression encore ouverte** : l'application n'enregistre plus rien d'une
partie terminée (décision 28 — sera réglée par l'abandon, §9). Les Réglages, eux, sont
**redevenus joignables** (décision 23 — réglée par §8 étape 2).

**Observation d'architecture** (décision 29) : la couche `common/` — `PieceManipulationState`,
`GameTimerMixin`, `PieceInteractionMixin`, `PentominoGameMixin` — n'a plus qu'**un seul
client**, `pentoscope_provider.dart`. Rien à défaire dans l'immédiat, mais à ne pas hériter
sans l'examiner. Le commentaire de `piece_manipulation_state.dart` l.14 cite encore
`PentominoGameState`, qui n'existe plus.

**Test appareil dû par Paul** : depuis §8 étape 2, le point 3 du temps 2 (§4.7 du plan 6×10,
la bascule du compteur) est **désormais instruisable** — les Réglages sont joignables. Les
autres points du test post-suppression (Pentoscope toutes tailles, multijoueur, aucun bouton
mort, dialogue « Nouvelle partie » : difficulté + montrer la solution) restent dus.

**Git** : à jour et poussé jusqu'à `af4e046` ; **4 commits §8 non poussés** (`35e9d0e..971e8cc`)
plus ce commit de journal. Le reste du `git status` est du bruit de plateforme.

**Test manuel** : Paul, iPhone en release —

```bash
flutter run --release -d 00008150-000165D4027B401C
```

> ⚠️ En `--release`, `debugPrint` supprimé : critère console → observation écran.

**Dette technique** : `flutter pub add collection` ; preview cyan morte dans
`pentoscope_board.dart` ; 3e chrono dans `pentoscope_mp_provider.dart` ;
`common/bigint_plateau.dart` orpheline ; le paramètre `cellSize` de `PieceRenderer`
(miniature, plan 6×10 §6) ; l'index de `check_orphan_files` (tools/db) périmé.
> `PentoscopeDifficulty` en doublon (ex-décision 34) : **réglé** par §8 étape 1.

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

25. **2026-08-29 — CLI** — **le navigateur de solutions est dégraissé du singleton à l'étape 3
    mais déménagé seulement à l'étape 7**, pas à l'étape 3 comme l'écrit §3.1. Motif : le
    déménager pendant que le mode classique l'utilise encore forcerait à corriger l'import de
    deux fichiers voués à la suppression (écran classique, `action_slider`). En le laissant
    dans `lib/screens/` jusqu'à l'étape 7 (ce dossier survit), on ne touche aucun fichier
    condamné. Le but fonctionnel de §3.1 (découplage + accès Pentoscope) est atteint dès
    l'étape 3. → `6b96fa8`, `371c3d5`.
26. **2026-08-29 — CLI** — **`game_utils.dart` supprimé à l'étape 5, pas à l'étape 7.** Ce
    ré-export orphelin (aucun lecteur) importait `game_colors`/`game_constants` en **relatif** ;
    leur déménagement à l'étape 5 cassait ses imports. Le supprimer tout de suite évitait un
    import jetable à réparer. Sans impact (déjà mort). → `6ea1d35`.

27. **2026-08-29 — cowork** — **vérification indépendante de la suppression : conforme.**
    `classical/` 0, `screens/pentomino_game/` 0, `PentominoGameNotifier` 0,
    `pentominoGameProvider` 0 ; `solutionMatcher` hors `pentoscope/` = commentaires seulement ;
    les 5 fichiers sont bien sous `lib/common/` et `lib/common/widgets/`, le navigateur sous
    `lib/pentoscope/screens/`. **`lib/` passe de 23 036 à 19 839 lignes, −3197.** Les commits
    **sont poussés** (`git log origin/main..HEAD` = 0) : le §ÉTAT du CLI était périmé sur ce
    point.
28. **2026-08-29 — cowork** — **conséquence non anticipée : `GameSessions` est mort des deux
    côtés.** `onPuzzleCompleted` et le seul appel à `saveGameSession` vivaient dans le
    provider classique. **Plus aucun code n'écrit dans la table** ; `saveGameSession`,
    `getFastestCompletion`, `getHighestScore` et `_updateSolutionStats` n'ont plus d'appelant,
    et le seul lecteur restant (`getGameHistory`, dans `database_debug_screen`) est sur un
    écran injoignable (décision 23). **L'application n'enregistre plus rien d'une partie
    terminée.** Prévu par la décision 22, mais ça rend l'étape 4 urgente et non « un jour ».
29. **2026-08-29 — cowork** — **la couche `common/` n'a plus qu'un seul client.**
    `PieceManipulationState`, `GameTimerMixin`, `PieceInteractionMixin` et
    `PentominoGameMixin` ne servent plus que `pentoscope_provider.dart`. Elles avaient été
    extraites pour tenir **deux** implémentations alignées ; cette raison a disparu. **Ne rien
    défaire dans l'immédiat** — les mixins découpent un provider de 2000 lignes, ce qui vaut
    par soi-même — mais le noter plutôt que d'en hériter sans l'examiner. Au minimum, le
    commentaire de `piece_manipulation_state.dart` l.14 cite encore `PentominoGameState`,
    qui n'existe plus.
30. **2026-08-29 — cowork** — **le titre `## §PASSATIONS` avait disparu du journal** lors de
    la réécriture de §ÉTAT ; les passations se poursuivaient sous §DÉCISIONS. Restauré. Le
    contrôle de la §6 du MODUS_VIVENDI ne couvre pas la structure du journal lui-même — le
    faire à l'œil en fin de session.

31. **2026-08-29 — Paul** — **les Réglages passent dans l'AppBar de Pentoscope et
    `HomeScreen` est abandonné.** Mode opératoire : `PLAN_SUPPRESSION_CLASSICAL.md` §8.
    ⚠️ Conséquence non énoncée par la décision, relevée par cowork : `HomeScreen` portait
    **trois** cartes. Les Réglages sont traités ; `PentoscopeMenuScreen` (190 l.) et
    `DatabaseDebugScreen` (255 l.) deviennent **orphelins** et attendent chacun une décision.
    Celui du debug est le seul lecteur de l'historique de parties : son sort est lié à
    l'étape 4. → §8.2.

32. **2026-08-29 — Paul** — **l'historique de parties est ABANDONNÉ, pas porté. Cette
    décision annule la décision 22.** Motif : les lignes déjà en base sont des parties du mode
    classique, qui n'existe plus, et le portage exigeait une migration de schéma pour une
    fonctionnalité non consultée. Partent : les tables `GameSessions` et `SolutionStats`,
    sept méthodes de `settings_database.dart`, et `DatabaseDebugScreen` (255 l.). La table
    `Settings` reste — c'est toute la configuration. → `PLAN_SUPPRESSION_CLASSICAL.md` §9.
    ⚠️ Le projet n'a **jamais migré** (`schemaVersion => 1`, aucune `MigrationStrategy`) :
    cowork recommande d'en écrire une vraie plutôt que de laisser deux tables fantômes.
33. **2026-08-29 — Paul** — **`PentoscopeMenuScreen` est supprimé pour double emploi.**
    ⚠️ **Le double emploi n'est vrai qu'à moitié**, vérification faite par cowork : le bouton
    « + » de l'AppBar passe par `changeBoardSize`, qui code en dur
    `difficulty: random` et `showSolution: false`. Le menu est le **seul** endroit où l'on
    choisit la difficulté (`easy`/`hard`) et l'option « montrer la solution ». Le supprimer
    tel quel perd ces deux réglages et rend `generateEasy`/`generateHard` orphelines.
    **Question ouverte pour Paul** : le dialogue de taille absorbe-t-il ces deux réglages
    (avis de cowork), ou assume-t-on la perte ? → §8.2.
34. **2026-08-29 — cowork** — **`PentoscopeDifficulty` est déclaré deux fois** :
    `pentoscope/piece_difficulty.dart` l.25 et `pentoscope/pentoscope_provider.dart` l.65.
    Pour Dart ce sont deux types distincts — exactement le piège qu'avait `ViewOrientation`
    avant l'étape 1 de l'unification. À unifier quel que soit le sort du menu.

35. **2026-08-29 — Paul** — **le dialogue de taille absorbe le menu.** « Changer la taille du
    plateau » devient « Nouvelle partie » et porte taille + difficulté + « montrer la
    solution » ; `PentoscopeMenuScreen` est supprimé, `changeBoardSize` aussi (plus d'appelant).
    Effet de bord assumé : la liste des tailles n'agit plus au tap, il faut un bouton
    « Lancer » — c'est un gain de clarté, le comportement actuel jette la partie en cours sans
    le dire. Le sélecteur en deux groupes du plan 6×10 §5.5 ira dans ce dialogue.
    → `PLAN_SUPPRESSION_CLASSICAL.md` §8.2.

36. **2026-08-30 — CLI** — **`piece_difficulty.dart` supprimé en entier, pas ré-exporté.** §8
    étape 1 disait « garder le déclarant de `pentoscope_provider.dart` » ; le plan envisageait
    un ré-export du fichier pour l'autre déclaration. Vérification faite, le fichier était
    **100 % orphelin** : aucun importeur, et son seul autre contenu (`pieceDifficultyRank`)
    sans lecteur. Unifier = `git rm` le fichier. → `35e9d0e`.
37. **2026-08-30 — CLI** — **la carte « Pentominos Speed » de `HomeScreen` retirée à l'étape 3,
    pas à l'étape 4.** `HomeScreen` importait `PentoscopeMenuScreen` ; supprimer le menu à
    l'étape 3 (décision 35) cassait la compilation de `HomeScreen`. J'ai donc retiré la carte
    et l'import dès l'étape 3 pour garder `flutter analyze` à 0 warning entre chaque commit,
    l'étape 4 se contentant du `git rm home_screen.dart`. La consigne « ne fusionne pas les
    étapes 2 et 4 » est respectée : c'est l'étape 3 qui absorbe ce nettoyage, pas la 2. →
    `bd903a1`, `971e8cc`.
38. **2026-08-30 — CLI** — **bouton Réglages ajouté aussi en paysage.** §8 étape 2 ne visait
    que le bloc `actions:` de l'AppBar (portrait). L'écran a une barre d'outils distincte en
    paysage ; n'y mettre le bouton qu'en portrait l'aurait rendu injoignable dans l'autre
    orientation — exactement le défaut que §8 corrige. Ajouté aux deux. Note mineure au
    passage : l'infobulle du bouton « recommencer » précisée en « Recommencer (même taille) »
    pour la distinguer de « Nouvelle partie ». → `c6be674`.

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

**2026-08-29 14:09 — CLI → cowork (suppression du mode classique FAITE).** Étapes 2, 3, 5, 6,
7 appliquées, un commit chacune (`4485058`, `6b96fa8`, `6ea1d35`, `1f6fb08`, `371c3d5`) +
régénération de doc (`129ac70`). Le mode classique et sa plomberie 6×10 (singleton,
`plateau_solution_counter`, `solutions_provider`) n'existent plus ; le navigateur et les 5
fichiers partagés ont survécu, déménagés. Critères §6 verts, `flutter analyze` 0 warning,
canari 5/5. Décisions 25-26 ajoutées (navigateur déménagé à l'étape 7 ; `game_utils` supprimé
à l'étape 5). **Non fait** (hors périmètre) : étape 4 (historique), correctif Réglages
(déc. 23). **À signaler** : l'index de `check_orphan_files` (tools/db) est périmé, à
reconstruire ; et le test appareil (celui-ci + le temps 2 §4.7) reste dû par Paul.
**Non poussé** — 8 commits en avance sur `origin/main` (`1833aba`).

**2026-08-29 — cowork, vérification post-suppression.** Critères §6 repassés indépendamment :
conformes (décision 27). Deux conséquences vivantes relevées — l'historique de parties
n'existe plus (décision 28), les Réglages restent injoignables (décision 23, non traitée) —
et une observation d'architecture (décision 29). Titre §PASSATIONS restauré (décision 30).
**Aucun code touché.**
**Ordre proposé à Paul** : (1) rebrancher les Réglages — petit, corrige un défaut visible et
débloque le point 3 du test du temps 2 ; (2) étape 4, l'historique, qui rend la base vivante
à nouveau ; (3) le §5 du plan 6×10, tables 5×12 et 4×15.

**2026-08-29 — cowork → toi (Réglages).** Décision 31 prise par Paul ; §8 ajoutée au plan de
suppression — bouton dans l'AppBar, encombrement à surveiller (6 IconButton contre un titre
qui porte le compteur), et surtout les deux écrans qu'`HomeScreen` orpheline en partant.
Ordre en 3 temps, `HomeScreen` supprimé **en dernier** pour garder le filet.
**En attente de Paul** : le sort de `PentoscopeMenuScreen`, et ce que doit contenir
l'historique de parties (étape 4).

**2026-08-29 — cowork → toi (après décisions 31 à 33).** §9 écrite (abandon de l'historique,
avec la question de la migration drift — le projet n'en a jamais eu), §8.2 corrigée (le menu
Pentoscope n'est pas un pur doublon), §3.2 marquée renversée. Décisions 32 à 34.
**Aucun code touché.**
**En attente de Paul, une seule question** : le dialogue de taille absorbe-t-il la difficulté
et l'option « montrer la solution », ou les abandonne-t-on avec le menu ?

**2026-08-29 — cowork → toi (fin de session).** Décisions 31 à 35 enregistrées ; §8 et §9
écrites dans `PLAN_SUPPRESSION_CLASSICAL.md` avec leur mode opératoire et leur ordre ; §3.2
marquée renversée ; §ÉTAT réécrit. Deux corrections de fond apportées aux décisions de Paul,
qui reposaient sur des prémisses inexactes : le menu Pentoscope n'était pas un pur doublon
(difficulté et « montrer la solution » n'existent que là), et l'abandon de l'historique
demande quand même une migration. **Aucun code touché.**
**Prochain pas** : §8 puis §9 côté CLI, dans cet ordre.

**2026-08-30 — CLI → cowork (§8 FAITE).** §8 appliquée dans l'ordre de §8.3, un commit par
étape (`35e9d0e`, `c6be674`, `bd903a1`, `971e8cc`), `flutter analyze` 0 warning à chaque
palier, critères §8.4 tous verts. Les Réglages sont joignables via l'AppBar (portrait +
paysage) ; le dialogue « Nouvelle partie » absorbe le menu (taille + difficulté + montrer la
solution, bouton Lancer) ; `PentoscopeMenuScreen`, `changeBoardSize`, `piece_difficulty.dart`
et `home_screen.dart` supprimés ; `main.dart` sans route nommée. Trois décisions non prévues
au plan ajoutées (36 = suppression totale de `piece_difficulty` orphelin ; 37 = carte
`HomeScreen` retirée dès l'étape 3 pour ne pas casser la compilation ; 38 = bouton Réglages
aussi en paysage). **Non poussé** — 4 commits §8 + ce commit de journal.
**À faire, dû par Paul** : le test appareil, désormais complet — le point 3 du temps 2
(bascule du compteur) est enfin instruisable, plus le dialogue « Nouvelle partie ».
**Reste, hérité** : `DatabaseDebugScreen` franchement orphelin depuis l'étape 4 → §9 ;
tables 5×12/4×15 du plan 6×10 §5.

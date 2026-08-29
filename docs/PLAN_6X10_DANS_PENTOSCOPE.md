# Plan — porter le 6×10 dans Pentoscope

> Établi le 2026-08-29 par cowork, sur décision de Paul. **Remplace la suite du chantier
> d'unification** : `docs/PLAN_UNIFICATION_PIECES.md` étapes 3 (familles restantes), 4 et 5
> sont suspendues, pas annulées.
>
> Toutes les mesures et les numéros de ligne de ce document ont été relevés sur l'arbre de
> travail du 2026-08-29, après `4539ed8`. La méthode est donnée pour chacun.

---

## 1. La décision

**Le mode classique n'est plus modifié.** Il reste en l'état, fonctionnel, tel que livré
par les commits du 28/08. On ne lui applique ni la famille Isométries, ni la famille
Placement, ni rien d'autre.

**Pentoscope devient la référence de la manipulation des pièces**, et reçoit une taille
`6×10 / 12 pièces` — la seule dont les solutions soient connues à l'avance (les 9356 de
`assets/data/solutions_6x10_normalisees.bin`). Les autres tailles gardent le calcul à la
volée par `PentoscopeSolver`.

**Ordre imposé, et c'est le point qui rend le chantier réversible :** le 6×10 doit exister
et être **joué** dans Pentoscope avant qu'on envisage quoi que ce soit du côté du mode
classique. Dans ce sens, à tout instant, l'application a un 6×10 qui marche. Dans l'autre,
non.

### Ce qui reste acquis du plan d'unification

Les étapes 0 à 2 gardent toute leur valeur — ce sont elles qui rendent ce port possible :
`common/PlacedPiece` (un seul type de pièce posée), `common/PieceManipulationState` (le
contrat des 15 champs), `common/TransformationResult`, `common/ViewOrientation`,
`GameTimerMixin`, `PieceInteractionMixin`.

Ce qui est gelé : le travail Sélection (temps 1, temps 2, dettes) fait sur
`pentomino_game_provider.dart`. Il n'est pas perdu — le mode classique continue de
tourner avec — mais il ne sert plus l'objectif d'unification.

---

## 2. Pourquoi la substitution des 9356 est correcte, et à quelles conditions

C'est le seul point théorique du plan ; le reste est du câblage.

Les deux modules ne posent pas la même question :

| | question posée | mécanisme |
|---|---|---|
| Pentoscope | « les pièces restantes peuvent-elles remplir le plateau ? » (booléen) | `PentoscopeSolver.canSolveFrom` — backtracking exécuté **à chaque pose** |
| classique | « combien des 9356 solutions complètes restent compatibles ? » (entier) | balayage masqué de 9356 BigInt |

**Sur un 6×10 à 12 pièces, les deux réponses sont équivalentes** : chacune des 9356
solutions emploie les 12 pièces, donc `compte > 0` ⟺ « les pièces restantes peuvent
remplir le plateau ». La table donne en prime le compte, que le solveur ne donne pas.

**Cette équivalence ne vaut que pour cette taille.** Toutes les autres tailles de
Pentoscope sont un sous-ensemble tiré au hasard de `numPieces` pièces sur un rectangle qui
n'est pas un rectangle complet de pentominos : la table des 9356 ne dit rien de leurs
plateaux. Garder `canSolveFrom` pour elles n'est donc pas un compromis, c'est la seule
option correcte.

**Deux invariants sans lesquels la substitution devient fausse en silence :**

1. **Aucune case masquée.** `_toBigIntMask` (`services/plateau_solution_counter.dart`)
   casse sur les cases cachées (`-1`). Le défaut est latent aujourd'hui parce que le mode
   classique n'emploie que `Plateau.allVisible`. Si un 6×10 de Pentoscope masquait une
   case, le compteur répondrait faux sans aucun signal.
2. **Les 12 pièces, toutes les 12.** Un 6×10 auquel il manquerait une pièce sort du
   domaine de la table.

---

## 3. Temps 1 — la taille existe et se joue, sans les 9356

Objectif : pouvoir lancer un 6×10 dans Pentoscope et y jouer les 12 pièces. Aucun accès à
`solutionMatcher` à ce stade.

### 3.1 Le piège à écarter en premier — ne pas laisser le générateur travailler

`PentoscopeGenerator` ne doit **pas** traiter le 6×10 par son chemin normal. Trois raisons,
toutes vérifiées sur le code :

- `_selectRandomPieces(12)` sur 12 pièces donne un tirage **forcé**. La boucle
  `while (true)` et l'appel à `findFirstSolution` ne servent à rien.
- `findAllSolutions(timeout: 2 s)` : à l'expiration, `backtrackAll` fait un simple `return`
  (`pentoscope_solver.dart` l.103-105). `SolverResult.solutionCount` vaut alors la longueur
  de la liste **partielle**. Sur un 6×10 à 12 pièces on obtiendrait un nombre de solutions
  faux, présenté comme exact, sans le moindre avertissement. Ce n'est pas une lenteur,
  c'est un défaut silencieux.
- `generateEasy` boucle jusqu'à `solutionCount >= 4` : avec un tirage forcé et un compte
  partiel qui tomberait sous 4, c'est une boucle infinie.

### 3.2 Les sites, exactement

**a) `pentoscope_generator.dart` — la valeur d'enum.**

L'ordre des champs est `(dataIndex, width, height, numPieces, label)` :

```dart
size6x10(8, 6, 10, 12, '12');
```

> ⚠️ **Piège de nommage.** Les noms de cet enum ne veulent rien dire de façon cohérente :
> `size3x5` a bien width=3, height=5, mais `size10x5` a width=**5**, height=**10**. Les
> quatre premiers sont `widthxheight`, les quatre derniers l'inverse. `size6x10` est
> nommé ici selon la convention **widthxheight** (6 colonnes × 10 lignes), qui est celle
> que Paul emploie. Ne pas « corriger » les noms existants dans le même commit.

> `dataIndex` est mort : `grep -rn dataIndex lib/` ne trouve que sa déclaration et son
> paramètre. La valeur 8 n'a aucune importance.

**b) Le court-circuit, dans les quatre points d'entrée** — `generate` (l.22),
`generateEasy` (l.57), `generateHard` (l.95), `generateFromSeed` (l.140) :

```dart
PentoscopePuzzle _buildFullRectanglePuzzle(PentoscopeSize size) => PentoscopePuzzle(
      size: size,
      pieceIds: List.generate(12, (i) => i + 1),
      solutionCount: 9356,
      solutions: const [],   // délibérément vide — voir §4
    );
```

et, en tête de chacun des quatre :

```dart
if (size == PentoscopeSize.size6x10) return _buildFullRectanglePuzzle(size);
```

**c) `hasPossibleSolution` — ne pas appeler le solveur sur cette taille.**

`startPuzzle` pose déjà `hasPossibleSolution: true` (`pentoscope_provider.dart` l.612) ;
le problème n'apparaît qu'à la **première pose**, où `tryPlacePiece` (l.803) appelle
`_checkHasPossibleSolutionWith` → `_solver.canSolveFrom` sur un 6×10 avec 11 pièces
restantes et 55 cases libres. C'est le pire cas du backtracking et il n'est pas mesuré.

Au temps 1, court-circuiter : pour `size6x10`, `hasPossibleSolution` reste `true` sans
appel au solveur. Les trois sites qui appellent `_checkHasPossibleSolutionWith` sont
l.804 (`tryPlacePiece`), l.1097 (`_applyIsoUsingLookup`) et le site équivalent de
`_applySymmetryAbs`.

> Conséquence à connaître : le bouton d'indice de `pentoscope_game_screen.dart` (l.192-203)
> passe au **rouge** avec le tooltip « Aucune solution possible » dès que
> `hasPossibleSolution` est `false`. Un court-circuit oublié se voit donc à l'écran.

**d) `showSolution` avec une liste de solutions vide.**

`startPuzzle` l.584 écrit `firstSolution = showSolution ? puzzle.solutions[0] : null;`
sans garde — `RangeError` si `solutions` est vide. (Le site l.415 de `reset()`, lui, a
déjà son `&& newPuzzle.solutions.isNotEmpty`.) À garder :

```dart
firstSolution = (showSolution && puzzle.solutions.isNotEmpty) ? puzzle.solutions[0] : null;
```

**e) `minIsometries` — sans objet au temps 1.** La boucle l.582-595 parcourt
`puzzle.solutions` ; liste vide ⇒ `minIsometries = 0`. C'est acceptable au temps 1 et
c'est un point de conception au temps 2 (§4).

### 3.3 Ce qui bouge tout seul, et qu'il faut avoir vu

- **Les deux sélecteurs de taille itèrent `PentoscopeSize.values`** :
  `pentoscope_menu_screen.dart` l.128 et `pentoscope_game_screen.dart` l.952. Le 6×10
  **apparaîtra automatiquement** dans les deux. C'est voulu ; ce n'est pas un effet de bord
  à corriger.
- **Le multijoueur ne bouge pas.** `MPGameConfig.toPentoscopeSize()`
  (`pentoscope_mp_state.dart` l.174) cherche par `(width, height)` et le lobby fixe
  `size5x5` en dur (`pentoscope_mp_lobby_screen.dart` l.175). Rien à faire — mais rien
  n'interdit non plus le 6×10 en multijoueur plus tard.
- **`PentoscopeState.initial()` code en dur `Plateau.allVisible(5, 5)`** (l.1898). Sans
  effet ici, `startPuzzle` reconstruit le plateau. À noter, pas à corriger dans ce commit.
- **`PlacedPiece.getOccupiedCells()` a les bornes 6×10 en dur.** Pour cette taille, c'est
  juste ; pour les autres, non. Continuer à n'employer que `absoluteCells`.

### 3.4 Critères de fin, temps 1

```bash
G=lib/pentoscope/pentoscope_generator.dart
grep -c 'size6x10' $G                        # ≥ 5 : 1 déclaration + 4 court-circuits
grep -n '_buildFullRectanglePuzzle' $G       # 1 définition + 4 appels
grep -n 'puzzle.solutions\[0\]' lib/pentoscope/pentoscope_provider.dart  # aucun sans garde isNotEmpty
```

`flutter analyze` : **0 warning**, pas seulement 0 erreur.

Test manuel, sur appareil, c'est le seul juge :

- le 6×10 apparaît dans le menu Pentoscope et dans le sélecteur en cours de partie ;
- il démarre **sans latence** — s'il y a une attente d'une à deux secondes, le
  court-circuit du générateur n'est pas en place ;
- poser les 12 pièces : la victoire se déclenche une fois ;
- le bouton d'indice ne passe pas au rouge en cours de partie ;
- les autres tailles (3×5 … 5×10) se comportent comme avant, y compris en multijoueur.

---

## 4. Temps 2 — brancher les 9356

### 4.1 Presque tout existe déjà

`SolutionMatcher` (`services/solution_matcher.dart`) est **exclusivement** 6×10 :
`_width = 6`, `_height = 10`, `_cells = 60`. Il expose déjà les trois services voulus :

| besoin | méthode existante |
|---|---|
| le compteur de solutions | `countCompatibleFromBigInts(pieces, mask)` |
| l'indice | `getCompatibleSolutionIndices(pieces, mask)` |
| « montrer la solution » | `getSolutionByIndex` / `solutionToPlacedPieces` / `getPlacedPiecesByIndex` |

Le masque se construit par l'extension `services/plateau_solution_counter.dart`, celle-là
même qui porte `Plateau.countPossibleSolutions()`.

Le temps 2 est donc du **câblage**, pas de l'algorithmique nouvelle.

### 4.2 La décision de conception du temps 2 — ne PAS remplir `puzzle.solutions`

C'est le réflexe, et c'est un piège mesurable.

`startPuzzle` l.582-595 parcourt **toutes** les solutions du puzzle, et pour chacune les
12 placements, en appelant `minIsometriesToReach`. Avec `solutions: []` cette boucle ne
coûte rien. Avec 9356 solutions, elle devient 9356 × 12 appels **au démarrage de chaque
partie**, sur le chemin le plus visible de l'application.

S'y ajoutent la duplication en mémoire (les 9356 sont déjà chez `solutionMatcher`, sous
forme de BigInt) et la conversion `BigInt` → `Solution` pour chacune.

**Donc : `puzzle.solutions` reste vide pour le 6×10**, et les trois besoins passent par
`solutionMatcher`. Si `minIsometries` doit exister pour cette taille, c'est un calcul à
concevoir à part — pas un effet de bord d'une liste qu'on aurait remplie.

### 4.3 Le piège n°1 — la garde de chargement

`solutionsReadyProvider` (`providers/solutions_provider.dart`) est **amorcé** depuis
`main.dart` sans attente, et **gardé** par le seul `PentominoGameScreen`, qui refuse de
monter le jeu tant que les données ne sont pas prêtes.

Interroger `solutionMatcher` avant la fin du chargement lève un `StateError` que
`plateau_solution_counter` attrape et convertit en `null` : **le compteur disparaît de
l'interface sans aucun message.** C'est le défaut P4 déjà corrigé une fois côté classique.

L'écran de jeu Pentoscope doit donc, pour la taille 6×10, être gardé de la même façon —
sur le **montage**, pas seulement sur le `build`.

> Et la documentation de `solutions_provider.dart` dit aujourd'hui « Pentoscope, qui
> utilise `PentoscopeSolver` et non `solutionMatcher`, n'est pas ralenti ». Cette phrase
> devient fausse au temps 2 : la corriger dans le même commit.

### 4.4 Les branchements

- `hasPossibleSolution` pour `size6x10` := `plateau.countPossibleSolutions() > 0`, aux
  trois sites listés en §3.2c. Les autres tailles gardent `canSolveFrom`.
- Le compteur de solutions à l'écran : c'est la valeur, pas le booléen. Décider si
  Pentoscope l'affiche (le mode classique le fait) — **question pour Paul**, elle n'est
  pas tranchée ici.
- `applyHint` : Pentoscope a le sien, construit sur `puzzle.solutions`. Pour le 6×10 il
  doit passer par `getCompatibleSolutionIndices`. **C'est le seul endroit du temps 2 qui
  n'est pas du câblage** — les deux implémentations d'indice ne choisissent pas de la même
  façon.

### 4.5 Critères de fin, temps 2

```bash
grep -rn 'solutionMatcher' lib/pentoscope/     # les nouveaux points d'accès
grep -rn 'canSolveFrom' lib/pentoscope/        # doit rester gardé par size != size6x10
```

Test manuel :

- démarrer un 6×10 : le compteur annonce 9356 sur plateau vide ;
- poser une pièce : le compte diminue de façon plausible et **instantanément** ;
- amener volontairement le plateau dans une impasse : le bouton d'indice passe au rouge ;
- couper le réseau / relancer à froid : le 6×10 n'est jamais monté avec un compteur vide
  et sans message ;
- les autres tailles : compteur et indice inchangés.

---

## 5. Ce que ce plan ne traite pas

**Le navigateur de solutions** (`screens/solutions_browser_screen.dart`, vivant, appelé
par `action_slider` et l'écran classique), l'enregistrement de session en base
(`isometriesCount`, `calculateScore`), l'affichage `boardIsValid` / `overlappingCells` /
`offBoardCells`. Ces trois blocs appartiennent au mode classique et y restent. La question
de leur devenir ne se pose que si l'on décide un jour de supprimer le module — ce qui
n'est **pas** décidé.

**La miniature signalée par Paul** au déplacement d'une pièce en mode classique. Constat
statique : le retour visuel de drag est `PieceRenderer`, dont la taille de case est
**codée en dur à 22 px** (`piece_renderer.dart` l.56), alors que la case du plateau est
calculée par `availableWidth / visualCols`. Les deux plateaux **et** les deux barres
emploient le même widget, donc l'écart existe des deux côtés ; pourquoi il ne se voit
qu'en classique n'est pas élucidé. Correctif évident si c'est bien la cause : donner un
paramètre `cellSize` à `PieceRenderer` (défaut 22, pour les barres) et lui passer la
taille de case du plateau. **À confirmer par observation avant de coder.**

**Deux défauts relevés le 2026-08-29 et laissés en l'état**, puisqu'ils sont dans le mode
classique qu'on ne touche plus :

1. `screens/pentomino_game/widgets/shared/game_board.dart` l.447 appelle
   `notifier.applyIsometryRotation()`, méthode qui n'existe dans aucun provider. Elle passe
   `flutter analyze` parce que `_buildPieceOverlay(state, notifier, …)` a ses paramètres
   non typés : `notifier` est `dynamic`. C'est un `NoSuchMethodError` au **double-tap sur
   une pièce posée sélectionnée**. Reproductible sans effort ; à corriger si Paul rencontre
   le plantage.
2. Le mode classique n'appelle **jamais** `setDragging` — `state.isDragging` y vaut
   toujours `false`, et le `PieceInteractionMixin` extrait à l'étape 3 ne sert donc qu'à
   Pentoscope.

---

## Voir aussi

- `docs/PLAN_UNIFICATION_PIECES.md` — le chantier suspendu ; ses étapes 0 à 2 sont le socle
  de ce port
- `docs/ANALYSE_STOCKAGE_POSITIONS.md` — l'encodage `bit6`, le fondement des 9356
- `docs/JOURNAL.md` — §ÉTAT, §DÉCISIONS, §PASSATIONS

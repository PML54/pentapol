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

**a) `pentoscope_generator.dart` — la valeur d'enum, et le champ qui désigne sa table.**

Décision de Paul du 2026-08-29 : d'autres rectangles complets suivront (5×12, 4×15, 3×20).
L'information « d'où viennent les solutions » est donc portée par la configuration, sous la
forme d'une **référence**, pas d'un booléen — voir §4.1.

```dart
enum PentoscopeSize {
  size3x5 (0, 3,  5,  3, '3',    null),
  …                                       // les 7 autres : null, ajout mécanique
  size6x10(8, 6, 10, 12, '6×10', SolutionTable.r6x10);

  const PentoscopeSize(this.dataIndex, this.width, this.height,
                       this.numPieces, this.label, this.table);
  …
  /// Table de solutions pré-calculées, ou null si le puzzle est résolu à la volée.
  ///
  /// N'est valide que si la configuration emploie **toutes** les pièces de la table
  /// et qu'**aucune case n'est masquée** — voir §2.
  final SolutionTable? table;
}
```

> ⚠️ **Piège de nommage.** Les noms de cet enum ne sont pas cohérents : `size3x5` a bien
> width=3, height=5, mais `size10x5` a width=**5**, height=**10**. `size6x10` suit la
> convention **widthxheight** (6 colonnes × 10 lignes), celle qu'emploie Paul. Ne pas
> « corriger » les noms existants dans le même commit.

> ⚠️ **Le `label` ne peut plus être `numPieces`.** Les quatre rectangles complets ont tous
> 12 pièces : quatre entrées de menu marquées « 12 » sont inutilisables. Passer au format
> `'6×10'` pour ceux-là. Les huit tailles existantes gardent leur label ; c'est un champ
> d'affichage, rien ne le lit par valeur (`grep -n '\.label' lib/` : 5 sites, tous en
> affichage ou en trace).

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

## 4. Temps 2 — brancher les tables de solutions

### 4.1 La forme : une référence, pas un drapeau

Un booléen `isComputed` répondrait à « une table existe ? » mais pas à « laquelle ? ».
Avec quatre tables prévues, les deux questions doivent être posées une seule fois :

```dart
/// Table de solutions pré-calculées d'un rectangle de 60 cases.
enum SolutionTable {
  r6x10('assets/data/solutions_6x10_normalisees.bin',  6, 10, 2339),
  r5x12('assets/data/solutions_5x12_normalisees.bin',  5, 12, 1010),
  r4x15('assets/data/solutions_4x15_normalisees.bin',  4, 15,  368),
  r3x20('assets/data/solutions_3x20_normalisees.bin',  3, 20,    2);

  const SolutionTable(this.asset, this.width, this.height, this.canonicalCount);
  final String asset;
  final int width;
  final int height;
  /// Solutions à symétrie près, telles que stockées dans le .bin.
  final int canonicalCount;
  /// Après expansion identité / rot180 / miroirH / miroirV.
  /// Valide tant qu'aucune solution n'est invariante par l'une des trois — vérifié
  /// à la génération (§5.3), jamais à supposer.
  int get totalCount => canonicalCount * 4;
}
```

`size.table != null` remplace `isComputed`, sans champ redondant.

### 4.2 La discipline : un seul site de décision

Quatre fonctions ont besoin de savoir d'où viennent les solutions :
`_checkHasPossibleSolutionWith` (3 appelants — `tryPlacePiece` l.804,
`_applyIsoUsingLookup` l.1097, `_applySymmetryAbs`), `applyHint`, l'affichage du compteur,
`showSolution`. Un drapeau testé à quatre endroits, c'est « deux implémentations
sélectionnées par un booléen » — le motif que le chantier d'unification passait son temps
à démonter.

**Le champ n'est donc lu qu'une fois**, dans `startPuzzle`, pour choisir un collaborateur :

```dart
abstract interface class SolutionSource {
  /// Une solution reste-t-elle atteignable depuis ce plateau ?
  bool hasSolutionFrom(Plateau plateau, List<Pento> remaining);

  /// Combien de solutions complètes restent compatibles.
  /// null quand la source ne sait pas compter — c'est le cas du solveur à la volée.
  int? countFrom(Plateau plateau);

  /// Une solution compatible, pour l'indice. null s'il n'y en a plus.
  List<PlacedPiece>? hintFrom(Plateau plateau);
}
```

Deux implémentations : `TableSolutionSource(SolutionTable)` au-dessus d'un
`SolutionMatcher`, `LiveSolutionSource` au-dessus de `PentoscopeSolver`. Le provider les
tient dans un champ privé — comme il tient déjà `_generator` et `_solver` — posé par
`startPuzzle` :

```dart
_solutions = size.table == null
    ? LiveSolutionSource(_solver)
    : TableSolutionSource(size.table!);
```

`countFrom` nullable est ce qui évite un cinquième `if` : l'écran affiche le compteur quand
il y en a un, rien sinon.

### 4.3 Contrainte dure — ne pas casser le mode classique

Le mode classique est **figé** (décision n°7). Or il consulte le singleton global
`solutionMatcher` par l'extension `Plateau.countPossibleSolutions()`, et
`plateau_solution_counter._toBigIntMask()` **refuse explicitement** tout autre format :

```dart
if (width != 6 || height != 10) throw StateError(...);
```

La paramétrisation doit donc être **additive** : `SolutionMatcher` voit ses `_width`,
`_height`, `_cells` passer de `static const` à champs d'instance **avec les valeurs 6×10
par défaut**, le singleton global reste ce qu'il est, et Pentoscope obtient ses propres
instances. Aucun site du mode classique ne change.

Même chose pour le chargeur : `pentapol_solutions_loader.dart` est déjà générique —
`_boardCells = 60` et `_bytesPerSolution = 45` ne dépendent pas de la forme du rectangle,
seul le **nom du fichier** est en dur. Il suffit de le prendre en paramètre.

> ⚠️ `_toBigIntMask` enveloppe tout dans un `try/catch` qui convertit l'erreur en `null`
> après un `print`. Une table mal branchée ne lèvera donc rien : **le compteur disparaîtra
> de l'écran sans message**. Ne jamais interpréter un compteur absent comme « 0 solution ».

### 4.4 Le piège n°1 — la garde de chargement

`solutionsReadyProvider` (`providers/solutions_provider.dart`) est amorcé sans attente
depuis `main.dart` et **gardé** par le seul `PentominoGameScreen`, qui refuse de monter le
jeu tant que les données ne sont pas prêtes. Interroger un `SolutionMatcher` non initialisé
lève un `StateError` — avalé comme ci-dessus.

Avec quatre tables, ce provider devient une **famille** indexée par `SolutionTable`, chargée
paresseusement, et l'écran de jeu Pentoscope est gardé de la même façon — **sur le montage**,
pas seulement sur le `build`.

> **Tranché à l'exécution (décision n°14, 2026-08-29).** Pas de garde de montage : le CLI a
> fait `startPuzzle` `await` le chargement, et la latence au premier démarrage s'est révélée
> imperceptible au test appareil. La garde reste la solution de repli si un appareil plus
> lent la rendait visible.

> La documentation de `solutions_provider.dart` affirme aujourd'hui « Pentoscope, qui
> utilise `PentoscopeSolver` et non `solutionMatcher`, n'est pas ralenti ». Cette phrase
> devient fausse : la corriger dans le même commit.

### 4.5 Le piège n°2 — ne PAS remplir `puzzle.solutions`

`startPuzzle` l.582-595 parcourt **toutes** les solutions du puzzle, et pour chacune les 12
placements, pour calculer `minIsometries`. Liste vide : coût nul. 9356 solutions : 9356 × 12
appels **au démarrage de chaque partie**, sur le chemin le plus visible de l'application. S'y
ajoutent la duplication mémoire — la source les détient déjà en BigInt — et la conversion de
chacune.

`puzzle.solutions` **reste vide** pour toute taille adossée à une table. Si `minIsometries`
doit exister pour ces tailles, c'est un calcul à concevoir à part, pas l'effet de bord d'une
liste qu'on aurait remplie.

### 4.6 Le seul point qui n'est pas du câblage

`applyHint`. Pentoscope construit le sien sur `puzzle.solutions` ; le mode classique tire
d'une solution compatible aléatoire. Les deux ne choisissent pas de la même façon, et
`hintFrom` doit trancher.

> **Tranché par Paul (décision n°15, 2026-08-29) : solution compatible aléatoire**, comme le
> mode classique. Appliqué au temps 2.

### 4.7 Critères de fin, temps 2

```bash
grep -rn 'countPossibleSolutions\|_toBigIntMask' lib/classical/   # inchangé
grep -rn 'canSolveFrom' lib/pentoscope/       # uniquement dans LiveSolutionSource
grep -rn 'size.table\|\.table !=' lib/pentoscope/  # un seul site de lecture : startPuzzle
```

Test manuel :

- 6×10 : le compteur annonce 9356 sur plateau vide, diminue de façon plausible à chaque
  pose, **instantanément** ;
- amener volontairement le plateau dans une impasse : le bouton d'indice passe au rouge ;
- relancer à froid : le 6×10 n'est jamais monté avec un compteur vide et sans message ;
- les autres tailles : compteur absent, indice et comportement **inchangés** ;
- le **mode classique** : compteur de solutions toujours là. C'est le canari de la §4.3.

---

## 5. Les trois autres tables — 5×12, 4×15, 3×20

> Rédigé le 2026-08-29 par cowork, pendant l'attente du test appareil du temps 2. **Rien
> ici ne doit être exécuté avant que Paul ait validé le temps 2** (§4.7) — c'est ce qui
> garde le chantier réversible.

### 5.1 Le correctif préalable — rendre la troncature impossible à manquer

Il y a **deux** défauts, pas un.

1. `PentominoSolver.maxSeconds` vaut 30 et c'est un champ `final` sans paramètre de
   constructeur (`lib/services/pentomino_solver.dart` l.23) : l'outil hors-ligne ne peut
   pas le régler.
2. Même relevé, **un timeout ne se voit pas** : `findAllSolutions` fait un `return` après
   un `print` (l.470-475), et l'appelant reçoit une liste qu'il ne peut pas distinguer
   d'une liste complète.

Le second est le vrai défaut. Rendre `maxSeconds` paramétrable sans rendre la troncature
observable ne ferait que déplacer le problème d'un cran.

**La mesure qui autorise à changer la signature** : `findAllSolutions` n'a **qu'un seul
appelant** dans tout le dépôt — `tools/generate_6x10_solutions.dart` l.48. Vérifiable par
`grep -rn 'findAllSolutions' lib/ tools/ test/`.

#### Les sites, exactement

**a) Le champ et les deux constructeurs.**

```dart
final int? maxSeconds;   // null = sans limite
```

Paramètre nommé de défaut 30 sur le constructeur (l.38) **et** sur la factory
`fromIds` (l.45), pour que les trois appelants existants (`findSolution` l.11,
`hasSolution` l.17, l.68) ne changent pas d'une ligne.

**b) Les trois comparaisons** — l.111 (`backtrack`), l.472 (`findAllSolutions`), l.593
(boucle de reprise) — deviennent :

```dart
final limit = maxSeconds;
if (limit != null && DateTime.now().difference(startTime).inSeconds > limit) …
```

**c) La signature de `findAllSolutions`** — c'est le cœur du correctif :

```dart
Future<({List<List<PlacementInfo>> solutions, bool truncated})> findAllSolutions({...})
```

`truncated` vaut `true` si le timeout **ou** `maxSolutions` a coupé la recherche. Un
résultat tronqué ne peut alors plus être confondu avec un résultat exhaustif.

**d) L'outil refuse d'écrire** quoi que ce soit quand `truncated` est vrai. Une
énumération exhaustive interrompue n'est pas un résultat partiel, c'est un run raté.

#### Deux choses à savoir avant de toucher à ça

> **Le fichier livré est bon, ne pas le régénérer.** Les 8175 solutions brutes couvraient
> les **2339/2339** classes (vérifié le 2026-08-27) : `solutions_6x10_normalisees.bin` est
> complet. C'est un coup de chance qu'on ne peut pas attendre des trois autres tables — une
> troncature peut parfaitement faire manquer une classe.

> **L'avertissement « Cela va prendre plusieurs heures » (outil l.39) est faux.** 8175
> solutions en 30 s au plus, c'est ~270/s : les 9356 sortent en une quarantaine de
> secondes. Hypothèse simple, vérifiable au premier run ; corriger l'en-tête de l'outil
> dans le même commit.

#### Critères de fin

```bash
S=lib/services/pentomino_solver.dart
grep -c 'maxSeconds' $S                       # 1 champ + 2 params + 3 tests
grep -rn 'findAllSolutions' lib/ tools/ test/ # 1 déclaration + 1 appel
```

`flutter analyze` : **0 warning**. Et un run de non-régression sur le 6×10 :
**9356 brutes, 2339 normalisées, `truncated == false`**. Si le compte diffère, ne rien
écrire et revenir ici.

### 5.2 Généraliser l'outil de génération

`_boardWidth` / `_boardHeight` sont des `const` en tête de fichier (l.14-15) et les noms de
fichiers sont écrits en dur à six endroits. Passer les dimensions en arguments de ligne de
commande et dériver les noms (`solutions_${w}x${h}_brutes.bin`,
`solutions_${w}x${h}_normalisees.bin`).

`pieceOrder` (l.32) est une heuristique d'ordre de placement : valable pour toute forme,
la garder telle quelle.

### 5.3 Le format ne bouge pas

60 cases × 6 bits = 45 octets par solution, quelle que soit la forme du rectangle. Volumes
attendus :

| table | canoniques | ×4 | fichier |
|---|---|---|---|
| 6×10 | 2339 | 9356 | 105 255 o *(constaté)* |
| 5×12 | 1010 | 4040 | 45 450 o |
| 4×15 | 368 | 1472 | 16 560 o |
| 3×20 | 2 | 8 | 90 o |

Négligeable. Déclarer les trois nouveaux assets dans `pubspec.yaml`.

### 5.4 Le critère d'acceptation est gratuit et décisif

Les comptes canoniques des pavages de rectangles par les 12 pentominos sont connus :
**2339 / 1010 / 368 / 2**. Générer, normaliser, compter, comparer.

Trois vérifications, **dans l'outil** et pas dans un carnet — il refuse d'écrire si l'une
échoue :

1. compte canonique == valeur attendue pour ces dimensions ;
2. **aucune solution invariante** par rot180, miroirH ou miroirV — sinon l'expansion ×4 de
   `SolutionMatcher` produit des doublons et `totalCount` ment ;
3. expansion ×4 → 0 collision, compte == 4 × canoniques.

C'est exactement ce qui aurait attrapé le 8175.

### 5.5 Décision d'interface — le sélecteur de taille

**Le problème n'est pas seulement la place.** `pentoscope_menu_screen.dart` l.127-131 est un
`Row` d'`Expanded`, un par `PentoscopeSize.values` : 8 aujourd'hui, 12 demain, soit une
trentaine de pixels chacun sur un téléphone. Mais surtout, les deux familles n'ont rien à
faire dans la même rangée indifférenciée :

| | puzzles | rectangles complets |
|---|---|---|
| pièces | 3 à 10, **tirées au hasard** | les 12, toujours les mêmes |
| configuration | une par tirage | une seule, à jamais |
| solutions | calculées à la volée | table pré-calculée |
| `label` actuel | `numPieces` (`'3'`…`'10'`) | vaudrait `'12'` **quatre fois** |

**Décision retenue : deux groupes, chacun sa rangée, chacun son intitulé.** Les 8 puzzles
gardent la rangée et les labels d'aujourd'hui — aucune régression, c'est l'état que Paul a
validé. Les 4 rectangles forment une seconde rangée de 4 `Expanded`, plus large que
l'existante, avec des labels `'6×10'`, `'5×12'`, `'4×15'`, `'3×20'`.

Le changement se limite à `_buildSizeSelector` : une `Column` de deux `Row`, chacune filtrée
sur `size.table == null` ou non. Le champ qui distingue les deux familles existe déjà — c'est
celui de §4.1, et c'est un argument de plus en sa faveur.

**Écartés, et pourquoi** : le défilement horizontal cache des options alors qu'il n'y en a
que 12 et qu'on veut les voir toutes ; un menu déroulant ajoute un geste au choix principal
de l'écran.

**Le second sélecteur ne bouge pas.** `pentoscope_game_screen.dart` l.952 est une liste de
`RadioListTile` — elle absorbe 12 entrées sans rien changer. Son titre affiche déjà
`'${size.label} (${size.width}x${size.height})'`, qui reste correct.

### 5.6 Décision d'interface — le 3×20

> **Tranché par Paul, 2026-08-29 : le 3×20 est abandonné pour l'instant** — ni généré, ni
> ouvert au joueur. Les tables à produire sont donc **5×12 et 4×15**, deux et non trois.
>
> ⚠️ **Le motif importe.** Paul l'a écarté « pour problèmes d'affichage ». Ce n'est pas la
> bonne raison, et s'en tenir à celle-là ferait rouvrir la question le jour où l'affichage
> sera amélioré. L'objection d'affichage est **faible** (voir l'arithmétique ci-dessous :
> des cases à 50 % de celles du 6×10, pas illisibles). L'objection dirimante est de **jeu** :
> 2 solutions à symétrie près sur 60 cases, donc un compteur à 0 après très peu de pièces et
> un indice rouge en permanence. Aucune amélioration d'affichage ne changera ça.
>
> Coût de la table elle-même, pour mémoire si la question revient : **90 octets, 8
> solutions** — la seule vérifiable à la main, ce qui en aurait fait une bonne fixture de
> validation de la chaîne de génération. Écartée avec le reste ; à rouvrir seulement si un
> mode « expert » est décidé.


**Correction d'une mesure de la version précédente de ce document**, qui annonçait des cases
« illisibles » sur les plateaux hauts. L'arithmétique dit autre chose. `cellSize` vaut
`min(W/colonnes, H/lignes)` (`pentoscope_board.dart` l.65-67) ; en portrait ce sont les
lignes qui contraignent. Rapporté au 6×10 que Paul vient de valider, à surface d'affichage
égale :

| taille | lignes | case relative au 6×10 |
|---|---|---|
| 5×12 | 12 | **83 %** |
| 4×15 | 15 | **67 %** |
| 3×20 | 20 | **50 %** |

Moitié, pas « minuscule ». L'objection de lisibilité ne tient donc pas pour le 5×12 ni le
4×15 ; elle reste à regarder sur l'appareil pour le 3×20, et le mode paysage y échange les
axes (`visualCols = boardHeight`), ce qui change complètement le calcul — **à observer, pas
à déduire.**

**La vraie objection est ailleurs, et elle est de jeu.** Le 3×20 a **2 solutions à symétrie
près, 8 en tout, sur 60 cases**. Conséquence directe sur les deux fonctions qu'on vient de
brancher : le compteur tombe à 0 après très peu de pièces, et l'indice passe au rouge
presque tout le temps. Ce n'est pas un défaut d'implémentation, c'est la nature du plateau —
mais un niveau où l'assistance dit « impasse » en permanence n'est pas un niveau.

**Décision retenue : le 3×20 est généré et vérifié, mais n'entre pas dans le sélecteur.**
Il sert de **fixture de validation de la chaîne** — c'est la seule table assez petite (8
solutions) pour être vérifiée exhaustivement à la main. Son ouverture au joueur est une
décision de jeu séparée, à prendre après avoir vu le comportement du compteur sur le 4×15.

> Ce point est une recommandation de cowork, pas un arbitrage de Paul. S'il veut un mode
> « expert », le 3×20 est le candidat évident et rien dans le code ne s'y oppose — il suffit
> de lui donner sa `SolutionTable`.

### 5.7 Ordre d'exécution

1. **Correctif du solveur** (§5.1), commit seul, avec le run de non-régression 6×10.
2. **Généralisation de l'outil** (§5.2), commit seul.
3. **Génération et vérification** des trois tables (§5.4), ajout aux assets et à
   `pubspec.yaml`.
4. **Sélecteur de taille** (§5.5) — **avant** l'étape 5, jamais après : ajouter les valeurs
   d'enum d'abord ferait passer le `Row` à 12 entrées et afficherait quatre « 12 ».
5. Les valeurs `SolutionTable` et les tailles `PentoscopeSize` correspondantes — **deux**,
   5×12 et 4×15 ; le 3×20 est écarté (§5.6).
6. Test appareil.

L'inversion des étapes 4 et 5 est la seule erreur d'ordre qui produirait une régression
visible.

---

## 6. Ce que ce plan ne traite pas

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

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
`hintFrom` doit trancher. **Question ouverte, pour Paul.**

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

### 5.1 Le défaut à corriger AVANT de générer quoi que ce soit

`tools/solutions_6x10_brutes.bin` ne contenait que **8175 des 9356** solutions —
sous-ensemble strict, cause restée inexpliquée jusqu'ici. **Elle est trouvée :**
`PentominoSolver.maxSeconds` vaut **30**, c'est un champ `final` non paramétrable
(`lib/services/pentomino_solver.dart` l.23), et `findAllSolutions` fait un simple `return`
à l'expiration (l.470-475) après un `print`. L'outil hors-ligne
`tools/generate_6x10_solutions.dart` l'appelle sans pouvoir le régler.

Ce n'est donc **pas** un défaut de complétude du solveur : c'est un timeout silencieux. Le
même qui, non corrigé, tronquerait les trois nouvelles tables de la même façon.

Correctif préalable : passer `maxSeconds` en paramètre de constructeur (défaut 30, pour ne
rien changer aux appelants) et le mettre à l'infini dans l'outil hors-ligne.

### 5.2 Le format ne bouge pas

60 cases × 6 bits = 45 octets par solution, quelle que soit la forme du rectangle. Volumes
attendus :

| table | canoniques | ×4 | fichier |
|---|---|---|---|
| 6×10 | 2339 | 9356 | 105 255 o *(constaté)* |
| 5×12 | 1010 | 4040 | 45 450 o |
| 4×15 | 368 | 1472 | 16 560 o |
| 3×20 | 2 | 8 | 90 o |

Négligeable. Déclarer les trois nouveaux assets dans `pubspec.yaml`.

### 5.3 Le critère d'acceptation est gratuit et décisif

Les comptes canoniques des pavages de rectangles par les 12 pentominos sont connus :
**2339 / 1010 / 368 / 2**. Générer, normaliser, compter, comparer. Un écart d'une seule
unité signifie une table incomplète — c'est exactement ce qui aurait attrapé le 8175.

Trois vérifications, les mêmes que celles déjà passées sur le 6×10 :

1. compte canonique == valeur attendue ;
2. **aucune solution invariante** par rot180, miroirH ou miroirV — sinon l'expansion ×4
   produit des doublons et `totalCount` ment ;
3. expansion ×4 → 0 collision, compte == 4 × canoniques.

### 5.4 Objections d'interface, à trancher avant d'ouvrir ces tailles au joueur

- **Le sélecteur de taille est un `Row` de `Expanded`** (`pentoscope_menu_screen.dart`
  l.127-131). Il porte déjà 8 entrées ; à 12 sur une largeur de téléphone, chacune fait une
  trentaine de pixels. Ce composant doit changer de forme avant, pas après.
- **Le 3×20 n'est pas un niveau de jeu.** Deux solutions à symétrie près : c'est le
  rectangle le plus contraint qui existe. Utile comme cas de test de la chaîne, discutable
  comme taille proposée au joueur.
- **Les plateaux hauts ne cassent pas, mais deviennent minuscules.** `cellSize` est borné
  par `constraints.maxHeight / visualRows` (`pentoscope_board.dart` l.65-67) : pas de
  débordement, mais 20 lignes sur un téléphone donnent des cases illisibles. Le mode paysage
  échange les axes et sauve probablement le 3×20 et le 4×15 — **à regarder sur l'appareil.**

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

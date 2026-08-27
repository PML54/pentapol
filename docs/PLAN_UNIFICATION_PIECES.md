# Plan — unifier la manipulation des pièces (barre + plateau) sur les 3 modules

> Établi le 2026-08-27 20:22. Objectif fixé par Paul : **une seule implémentation** de la
> manipulation des pièces, depuis la barre comme sur le plateau, partagée par
> `classical`, `pentoscope` et `pentoscope_multiplayer`.
>
> Toutes les mesures de ce document ont été obtenues par extraction automatique sur les
> sources. La méthode est indiquée pour que tu puisses les refaire.

---

## 1. Où on en est vraiment

### Deux familles, pas trois

Le multijoueur n'est pas une troisième implémentation : c'est Pentoscope plus du réseau.
Il réutilise ses widgets et son provider tels quels. **La fracture est entre `classical`
et `pentoscope`** — c'est un problème à deux termes, pas à trois.

| | classical | pentoscope | multijoueur |
|---|---|---|---|
| Plateau | `shared/game_board.dart` (529 l.) | `pentoscope_board.dart` (859 l.) | idem pentoscope |
| Barre | `game_mode/piece_slider.dart` (189 l.) | `pentoscope_piece_slider.dart` (197 l.) | idem pentoscope |
| Provider | `PentominoGameNotifier` (1841 l., 54 méthodes) | `PentoscopeNotifier` (1846 l., 34 méthodes) | consomme celui de pentoscope |

### Ce qui est déjà partagé, et qui marche

- `common/pentomino_game_mixin.dart` — 6 helpers de géométrie : `canPlacePiece` (abstrait),
  `remapSelectedCell`, `getRawMastercaseCoords`, `calculateDefaultCell`,
  `calculateAnchorPosition`, `findNearestValidPosition`
- `common/pentomino_symmetry_api.dart` — les isométries
- `common/placed_piece.dart` — **depuis le 2026-08-27**, un seul type de pièce posée
- `piece_renderer.dart`, `draggable_piece_widget.dart`, `piece_border_calculator.dart` —
  importés par les **deux** familles

Autrement dit : la géométrie et le rendu bas niveau sont mutualisés. C'est la couche
d'**orchestration** — l'enchaînement sélection → drag → snap → pose — qui est doublée.

### 28 méthodes portent le même nom dans les deux providers

Mesure : extraction des méthodes déclarées dans le corps de chaque classe `Notifier`.

| Constat | Nombre |
|---|---|
| Noms communs aux deux providers | **28** |
| Dont signatures identiques et corps de taille comparable | 15 |
| Dont **signatures différentes** | **6** |
| Dont corps très différents (rapport ≥ 2) | 7 |

Les 6 signatures divergentes :

| Méthode | classical | pentoscope |
|---|---|---|
| `applyIsometryRotationCW` | `void` | `TransformationResult` |
| `applyIsometryRotationTW` | `void` | `TransformationResult` |
| `applyIsometrySymmetryH` | `void` | `TransformationResult` |
| `applyIsometrySymmetryV` | `void` | `TransformationResult` |
| `reset` | `void` | `Future<void>` |
| `build` | `PentominoGameState` | `PentoscopeState` |

Les 7 corps très divergents : `cancelSelection`, `cycleToNextOrientation`,
`getRawMastercaseCoordsPublic`, `highlightPieceInSlider`, `placeSelectedPieceForTutorial`,
`scrollSliderToPiece`, `selectPiece`.

À noter : la divergence de taille ne signifie pas toujours une divergence de
comportement. `applyIsometryRotationCW` fait 14 lignes côté classical contre 3 côté
pentoscope simplement parce que classical distingue pièce du slider et pièce posée là où
pentoscope délègue à un helper. C'est de la **normalisation**, pas de la réconciliation.

### Le noyau d'état est déjà commun à 15 champs

`PentominoGameState` (18 champs) et `PentoscopeState` (27 champs) partagent **15 champs
de type strictement identique** :

```
plateau · availablePieces · placedPieces
selectedPiece · selectedPositionIndex · selectedPlacedPiece
piecePositionIndices · selectedCellInPiece
previewX · previewY · isPreviewValid · isSnapped · isDragging
viewOrientation · elapsedSeconds
```

`placedPieces` est de type `List<PlacedPiece>` des deux côtés **depuis la fusion du
2026-08-27** — avant, les types différaient et ce noyau n'existait pas.

Champs propres à classical : `boardIsValid`, `offBoardCells`, `solutionsCount`,
`solvedSolutionIndex`, `isInTutorial`, `isometriesCount`, `solutionsViewCount`.
Champs propres à pentoscope : `puzzle`, `currentSolution`, `validPlacements`,
`selectedMasterAbs`, `hasPossibleSolution`, `isComplete`, `showSolution`, et cinq
compteurs de statistiques.

**C'est la découverte qui structure tout le plan** : le désordre est en surface. Dessous,
les deux modules manipulent déjà la même chose.

---

## 2. Le vrai obstacle

Deux verrous, dans cet ordre de gravité.

**Les widgets lisent un provider global nommément.**

```
game_board.dart        →  import classical/pentomino_game_provider
pentoscope_board.dart  →  import pentoscope/pentoscope_provider
```

Un widget qui nomme son provider ne peut servir qu'un module. La duplication n'est pas un
défaut de discipline, c'est une conséquence mécanique. Tant que ce couplage tient, aucune
fusion de widget n'est possible.

**Les 28 méthodes opèrent sur deux types d'état distincts.** Elles ne peuvent pas monter
dans un mixin partagé tant qu'elles manipulent `PentominoGameState` d'un côté et
`PentoscopeState` de l'autre.

---

## 3. Ce qu'il ne faut PAS faire en premier

**Fusionner les deux plateaux.** C'est le réflexe, et c'est un piège.
`pentoscope_board.dart` contient de la **logique de jeu** que `game_board.dart` laisse à
son provider : `placeSelectedPiece`, `selectPieceOnBoard`, `highlightCell`,
`_showVictoryDialog`. Sur les méthodes des deux fichiers, 5 noms communs seulement,
25 propres à Pentoscope. Les fusionner maintenant produirait un fichier commun contenant
le désordre des deux, sans rien résoudre.

---

## 4. Le chemin

Cinq étapes. Chacune a un critère de fin vérifiable et laisse l'application en état de
marche — aucune ne demande un « big bang ».

### Étape 0 — un seul type de pièce posée ✅ FAIT le 2026-08-27

`PentoscopePlacedPiece` fusionné dans `common/PlacedPiece` (commit `1b97e82`).
C'est ce qui a rendu le noyau d'état commun possible.

### Étape 1 — extraire le noyau d'état commun ✅ FAIT le 2026-08-27

**Réalisée autrement que prévu.** Le plan proposait un objet de valeur imbriqué ; mesure
faite avant d'écrire, les 15 champs sont lus à **≈ 407 endroits** dans `lib/`, qu'il
aurait fallu réécrire en `state.pieces.<champ>`. Retenu à la place : une **interface
abstraite** `common/piece_manipulation_state.dart`, que les deux états implémentent. Les
champs `final` existants la satisfont automatiquement — **aucun site d'appel modifié**, et
le compilateur garantit désormais que les deux états restent alignés.

Obstacle découvert au passage : `ViewOrientation` était déclaré **deux fois**, en deux
types distincts pour Dart. Unifié dans `common/view_orientation.dart`, ré-exporté par les
deux anciens hôtes.

- **Critère de fin** : les deux états compilent, les 15 champs ne sont plus déclarés
  qu'une fois, l'application se comporte à l'identique.
- **Risque** : faible mais diffus — chaque `state.selectedPiece` devient
  `state.pieces.selectedPiece`. Beaucoup de sites d'appel, tous mécaniques. Le
  compilateur les signale tous ; rien ne peut passer silencieusement.
- **Taille** : la plus grosse en nombre de lignes touchées, la plus faible en réflexion.

### Étape 2 — aligner les signatures divergentes ✅ FAIT le 2026-08-27

`TransformationResult` (enum `success` / `recentered` / `impossible`) déplacé de
`pentoscope_provider.dart` vers `common/transformation_result.dart`, ré-exporté par
l'ancien hôte. Les 4 `applyIsometry*` du mode classique le renvoient désormais au lieu
de `void`.

Sur 31 sites d'appel des isométries, **4 seulement consomment le résultat**, tous côté
Pentoscope. Les 27 autres ignorent la valeur : le changement leur est transparent.

**Le mode classique ne renvoie que `success`.** Ses helpers
(`_applyRotationToPlacedPiece`, `_applySymmetryToPlacedPiece`) n'ont, vérification faite,
**aucun chemin d'échec** : ils sortent sans rien faire quand la transformation ne change
rien, sans le signaler. L'alignement porte donc sur le **type**, pas sur la sémantique —
celle-ci relève de l'étape 3, quand les corps fusionneront. C'est documenté sur l'enum
lui-même, pour que personne ne se fie à un `success` venant du mode classique.

#### Décision : `reset` et `build` ne sont PAS alignés

Le plan initial prévoyait d'aligner `reset` sur `Future<void>` des deux côtés. **Écarté
après examen**, pour deux raisons :

- Le `reset()` du mode classique est **réellement synchrone** — arrêt du chrono,
  réinitialisation de l'état, comptage des solutions. Celui de Pentoscope est
  `Future<void>` parce qu'il **régénère un puzzle**, ce qui est asynchrone par nature.
  Forcer `Future<void>` sur classical produirait un `async` de façade, sans bénéfice.
- `reset` et `build` relèvent du **cycle de vie**, pas de la manipulation des pièces.
  Ils sortent du périmètre de ce plan.

Divergence légitime, donc conservée. Il reste 0 signature divergente **dans le périmètre
des pièces**.

- **Critère de fin atteint** : les méthodes de manipulation des pièces ont des signatures
  identiques dans les deux providers.

### Étape 3 — remonter les méthodes dans le mixin, par famille

Une fois 1 et 2 faites, les 28 méthodes opèrent sur le même noyau avec les mêmes
signatures. Elles peuvent monter dans `PentominoGameMixin`. **Par famille, un commit
chacune**, jamais toutes d'un coup :

| Famille | Méthodes |
|---|---|
| Sélection | `selectPiece`, `selectPlacedPiece`, `cancelSelection` |
| Preview & drag ⚠ | `setDragging` ✅, `clearPreview` ✅ — **`updatePreview` reclassé** (voir ci-dessous) |
| Placement | `tryPlacePiece`, `updatePreview`, `getPlacedPieceAt`, `removePlacedPiece` |
| Isométries | les 4 `applyIsometry*`, `cycleToNextOrientation` |
| Barre | `highlightPieceInSlider`, `clearSliderHighlight`, `scrollSliderToPiece` |
| Chrono ✅ | `startTimer`, `stopTimer`, `getElapsedSeconds` — **fait le 2026-08-27** |

Commencer par **Chrono** et **Preview & drag** : corps déjà quasi identiques, gain
immédiat, risque nul.

> **Défaut corrigé, 2026-08-27 — une isométrie pouvait faire sortir la pièce du
> plateau.** Signalé par Paul en mode classique : une rotation ou une symétrie change
> l'empreinte de la pièce **sans déplacer son ancre**, si bien qu'une pièce collée à un
> bord se retrouvait partiellement hors plateau et s'affichait tronquée.
>
> Cause exacte : les **quatre** méthodes d'isométrie du mode classique ne faisaient
> aucune vérification de bornes — ce qui est précisément la raison pour laquelle elles
> renvoyaient toujours `success` (voir étape 2). Pentoscope, lui, recentre déjà : son
> `neededRecentering` est posé à dix endroits.
>
> Correction : un garde-fou unique `_keepOnBoard(PlacedPiece)` appliqué aux **6 sites**
> où une pièce posée reçoit une nouvelle orientation. Décalage **minimal**, juste ce
> qu'il faut pour que toutes les cellules rentrent. Il ne vérifie **que les bornes**,
> pas les chevauchements : c'est le défaut signalé, et `boardIsValid` continue de
> signaler le reste.
>
> **Dette restante** : le décalage n'est pas remonté dans le retour. Ces méthodes
> devraient renvoyer `TransformationResult.recentered` quand `_keepOnBoard` a déplacé la
> pièce. Non fait ici pour ne pas mêler une correction de défaut à un changement de
> sémantique dans le même commit — à traiter avec la famille Isométries.
>
> **Décision de jeu, 2026-08-27 — le magnétisme devient assistant partout.** Les deux
> modes n'avaient pas le même comportement d'accrochage : le mode classique cherchait
> une position valide dans un rayon de **2 cases** et affichait rouge au-delà ; Pentoscope
> snappait sur la position valide la plus proche **sans aucune limite de distance**. Paul
> a tranché pour le comportement de Pentoscope, plus assistant.
>
> **Appliqué autrement que « reprendre l'implémentation de Pentoscope ».** Ce port aurait
> imposé d'ajouter `validPlacements` à l'état classique et d'en répliquer les **13 sites
> d'invalidation**, et fait perdre l'indicateur `isSnapped` (preview cyan) que seul le mode
> classique alimente. Le mode classique ayant déjà l'algorithme « position valide la plus
> proche dans un rayon », il a suffi de porter `_snapRadius` de 2 à **10** — le plateau
> 6×10 est alors entièrement couvert depuis n'importe quelle ancre. Une constante, aucun
> état ajouté, l'indicateur cyan préservé.
>
> Coût : 440 positions testées par mouvement du doigt au lieu de 24, soit ~2200
> vérifications de case. Négligeable à l'échelle d'un geste ; c'est le premier poste à
> regarder si le drag devenait saccadé sur un appareil lent.
>
> **Défaut découvert, non corrigé** : Pentoscope **lit** `state.isSnapped` dans
> `pentoscope_board.dart` pour afficher une preview cyan, mais ne l'**écrit** jamais — le
> champ n'apparaît chez lui qu'en déclaration, valeur par défaut et plomberie de
> `copyWith`. La branche cyan de Pentoscope est donc morte depuis toujours. À traiter avec
> la famille Placement, où les deux `updatePreview` seront réconciliés.
>
> **Preview & drag, fait le 2026-08-27** → `common/piece_interaction_mixin.dart`,
> `PieceInteractionMixin<S extends PieceManipulationState> on Notifier<S>`. Le bornage
> sur le contrat de l'étape 1 est ce qui permet à `clearPreview` de lire
> `state.previewX` sans connaître le type concret — première fois que l'interface sert
> à autre chose qu'à documenter.
>
> **`updatePreview` a été reclassé dans la famille Placement.** Le plan le disait « quasi
> identique » sur la foi de sa taille — 37 lignes contre 38. Le nombre de lignes était un
> mauvais indicateur : ce sont deux **algorithmes différents**. Le mode classique calcule
> la validité à la volée ; Pentoscope s'appuie sur `validPlacements`, une liste
> pré-calculée dans son état que le mode classique n'a pas, et n'écrit jamais `isSnapped`.
> Les unifier revient à choisir un comportement de snapping pour les deux modes : une
> décision de jeu, pas un refactor.
>
> Gain brut de cette famille : 15 lignes. Le vrai intérêt est d'avoir établi le domicile
> des familles lourdes sur deux méthodes dont l'échec aurait été immédiat et sans
> conséquence.
>
> **Chrono, fait le 2026-08-27** → `common/game_timer_mixin.dart`, mixin générique
> `GameTimerMixin<S> on Notifier<S>`. Le module ne fournit que
> `stateWithElapsedSeconds` : le mixin ignore la forme de l'état.
>
> Contrairement à l'attente, `startTimer` **n'était pas** identique. Les gardes
> différaient — `_startTime != null` côté classique, `_gameTimer != null` côté
> Pentoscope — donnant des comportements incompatibles : le premier ne repartait
> jamais après un arrêt, le second repartait en **perdant le temps écoulé**. La cause
> était que « mettre en pause » et « remettre à zéro » passaient par le même appel.
> Résolu en séparant les intentions : `stopTimer()` conserve l'origine, `resetTimer()`
> l'efface. `startTimer()` devient idempotent et reprend sans perte.
>
> Les champs privés du chrono vivant désormais dans une autre bibliothèque, les accès
> directs ont été remplacés par l'API du mixin : `isTimerRunning` côté Pentoscope,
> `resetTimer()` / `stopTimer()` côté classique.
>
> **Découverte** : il existait une **troisième** implémentation du chrono, dans
> `pentoscope_mp_provider.dart` — l'audit initial disait « deux familles », ce qui vaut
> pour les widgets mais pas ici. Elle n'est **pas** absorbée, pour une raison précise :
> ce provider a **deux** timers qui se partagent les mêmes champs, `_startGameTimer()`
> (1 s, vérifie l'état de partie) et `startTimer()` (100 ms). Le second n'est **jamais
> appelé** ; `getElapsedSeconds` ne l'est que depuis lui. Les deux sont donc morts, mais
> ils échappent à `flutter analyze` parce qu'ils sont publics. À traiter à part. Garder **Placement** pour la fin — `tryPlacePiece` fait 178 lignes
côté classical contre 91 côté pentoscope, c'est là qu'est la vraie réconciliation.

- **Critère de fin, par famille** : la méthode n'existe plus que dans le mixin, les deux
  modules se comportent à l'identique.
- **Risque** : moyen et croissant selon la famille. Test manuel des deux modes après
  chaque famille.

### Étape 4 — sortir la logique de `pentoscope_board.dart`

Déplacer `placeSelectedPiece`, `selectPieceOnBoard`, `highlightCell`,
`_showVictoryDialog` et consorts vers `PentoscopeNotifier`, pour que les deux plateaux
aient la même répartition des responsabilités : le widget affiche, le provider décide.

- **Critère de fin** : `pentoscope_board.dart` ne contient plus que du rendu et des
  callbacks. Son volume devrait se rapprocher des 529 lignes de `game_board.dart`.
- **Bénéfice propre, indépendant de la fusion** : Pentoscope devient testable sans monter
  d'arbre Flutter.
- **Peut se faire en parallèle de l'étape 3.**

### Étape 5 — plateau et barre uniques, paramétrés

Un seul `GameBoard` et un seul `PieceSlider`, recevant dimensions, pièces posées,
sélection et callbacks **en arguments** — jamais un provider lu en dur. Chaque module les
alimente depuis son propre provider.

- **Critère de fin** : `pentoscope_board.dart` et `pentoscope_piece_slider.dart`
  supprimés, les trois modules montent les mêmes widgets.
- **Préalable strict** : étapes 1 à 4. Toute tentative avant est prématurée.

---

## 5. Pièges connus

**`PlacedPiece.getOccupiedCells()`** a les bornes du plateau 6×10 écrites en dur. Depuis
que la classe est partagée, Pentoscope y a accès et obtiendrait un résultat faux, sans
erreur, sur un plateau de largeur ≠ 6. Un avertissement est en place dans la doc de la
méthode. Utiliser `absoluteCells`, qui ne présume rien des dimensions.

**Le nommage des isométries.** Dans `pentominos.dart`, les méthodes publiques appellent
des helpers privés au nom **opposé** (`rotationCW` → `_rotate90TWCoords`, `symmetryH` →
`_flipVCoords`). L'inversion compense le repère écran, mais elle a déjà produit deux
tables de documentation contradictoires. Se fier aux noms publics, jamais aux privés.

**Le multijoueur suit sans le savoir.** Il ne nomme jamais les types de Pentoscope, il
consomme `PentoscopeState`. Les étapes 1 à 3 lui sont transparentes — mais il doit être
testé après chaque famille de l'étape 3, puisqu'il partage le provider modifié.

**Le tutoriel est asymétrique.** `placeSelectedPieceForTutorial` fait 69 lignes côté
classical contre 14 côté pentoscope. Ce n'est probablement pas la même fonctionnalité :
à traiter à part, pas dans une famille de l'étape 3.

---

## 6. Reproduire les mesures

```bash
# noms de méthodes communs aux deux providers
# (extraire les méthodes du corps de chaque classe Notifier, puis comm -12)

# champs communs aux deux états
grep -n "final .*;" lib/classical/pentomino_game_state.dart
grep -n "final .*;" lib/pentoscope/pentoscope_provider.dart
```

> ⚠️ Attention en refaisant la mesure des champs : un formateur a coupé quatre
> déclarations de `PentominoGameState` sur deux lignes (`final Pento?` puis
> `selectedPiece;`). Une regex sur une seule ligne les rate et sous-estime le noyau
> commun de 4 champs — l'erreur a été commise en établissant ce document.

---

## Voir aussi

- `docs/FONCTIONNEMENT.md` — documentation fonctionnelle vérifiée
- `docs/PENTOSCOPE.md` — le module dont la logique est à extraire (étape 4)
- `docs/MEMO_ARCHITECTURE_PIECES_REUSABLE.md` — mémo antérieur sur le même sujet,
  **non relu**, encore en vocabulaire « Isopento »

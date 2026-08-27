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

### Étape 1 — extraire le noyau d'état commun

Créer dans `common/` un objet de valeur portant les 15 champs partagés — appelons-le
`PieceManipulationState`. `PentominoGameState` et `PentoscopeState` le contiennent au
lieu de déclarer ces champs, et conservent leurs champs propres.

- **Critère de fin** : les deux états compilent, les 15 champs ne sont plus déclarés
  qu'une fois, l'application se comporte à l'identique.
- **Risque** : faible mais diffus — chaque `state.selectedPiece` devient
  `state.pieces.selectedPiece`. Beaucoup de sites d'appel, tous mécaniques. Le
  compilateur les signale tous ; rien ne peut passer silencieusement.
- **Taille** : la plus grosse en nombre de lignes touchées, la plus faible en réflexion.

### Étape 2 — aligner les 6 signatures divergentes

Choisir un type de retour unique pour les 4 isométries. `TransformationResult`
(pentoscope) est plus riche que `void` (classical) : l'aligner vers le haut, quitte à ce
que classical ignore le résultat au début. Idem pour `reset` : `Future<void>` des deux
côtés.

- **Critère de fin** : les 28 méthodes communes ont des signatures identiques, `build`
  excepté — il retourne l'état du module, c'est normal et définitif.
- **Risque** : faible. Peu de sites d'appel, changements localisés.
- **Préalable** : aucun. Peut se faire avant l'étape 1 si tu préfères commencer petit.

### Étape 3 — remonter les méthodes dans le mixin, par famille

Une fois 1 et 2 faites, les 28 méthodes opèrent sur le même noyau avec les mêmes
signatures. Elles peuvent monter dans `PentominoGameMixin`. **Par famille, un commit
chacune**, jamais toutes d'un coup :

| Famille | Méthodes |
|---|---|
| Sélection | `selectPiece`, `selectPlacedPiece`, `cancelSelection` |
| Preview & drag | `setDragging`, `updatePreview`, `clearPreview` |
| Placement | `tryPlacePiece`, `getPlacedPieceAt`, `removePlacedPiece` |
| Isométries | les 4 `applyIsometry*`, `cycleToNextOrientation` |
| Barre | `highlightPieceInSlider`, `clearSliderHighlight`, `scrollSliderToPiece` |
| Chrono | `startTimer`, `stopTimer`, `getElapsedSeconds` |

Commencer par **Chrono** et **Preview & drag** : corps déjà quasi identiques, gain
immédiat, risque nul. Garder **Placement** pour la fin — `tryPlacePiece` fait 178 lignes
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
